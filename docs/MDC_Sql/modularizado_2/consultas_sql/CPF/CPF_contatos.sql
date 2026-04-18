/*
    CONSULTA: CPF_contatos.sql
    ========================================================================
    Objetivo: Extrair contatos (telefones e emails) associados a um CPF
    Fontes: NFe (emitente e destinatario)
    ========================================================================
*/

WITH parametros AS (
    SELECT
        :CPF AS documento_filtro
    FROM DUAL
),

-- Contatos do CPF como DESTINATARIO (televendas/compras)
contatos_dest AS (
    SELECT DISTINCT
        'DESTINATARIO' AS TIPO_CONTATO,
        d.co_destinatario AS CPF_CNPJ,
        d.xnome_dest AS NOME,
        d.fone_dest AS TELEFONE,
        d.email_dest AS EMAIL,
        d.xmun_dest AS MUNICIPIO,
        d.co_uf_dest AS UF,
        EXTRACT(YEAR FROM d.dhemi) AS ANO_REFERENCIA,
        COUNT(*) OVER (PARTITION BY d.fone_dest, d.email_dest) AS QTD_OCORRENCIAS
    FROM
        bi.fato_nfe_detalhe d,
        parametros p
    WHERE
        d.co_destinatario = p.documento_filtro
        AND d.infprot_cstat IN ('100', '150')
        AND (d.fone_dest IS NOT NULL OR d.email_dest IS NOT NULL)
        AND d.seq_nitem = 1  -- Apenas primeiro item para evitar duplicacao
),

-- Contatos do CPF como EMITENTE (fornecedor)
contatos_emit AS (
    SELECT DISTINCT
        'EMITENTE' AS TIPO_CONTATO,
        d.co_emitente AS CPF_CNPJ,
        d.xnome_emit AS NOME,
        d.fone_emit AS TELEFONE,
        NULL AS EMAIL,  -- NFe nao tem email do emitente
        d.xmun_emit AS MUNICIPIO,
        d.co_uf_emit AS UF,
        EXTRACT(YEAR FROM d.dhemi) AS ANO_REFERENCIA,
        COUNT(*) OVER (PARTITION BY d.fone_emit) AS QTD_OCORRENCIAS
    FROM
        bi.fato_nfe_detalhe d,
        parametros p
    WHERE
        d.co_emitente = p.documento_filtro
        AND d.infprot_cstat IN ('100', '150')
        AND d.fone_emit IS NOT NULL
        AND d.seq_nitem = 1
)

-- Uniao de todos os contatos
SELECT * FROM contatos_dest
UNION ALL
SELECT * FROM contatos_emit
ORDER BY ANO_REFERENCIA DESC, QTD_OCORRENCIAS DESC
