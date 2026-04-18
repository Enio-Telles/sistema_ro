/*
    CONSULTA: NFe_NFCe.sql
    ========================================================================
    Objetivo: Localizar TODAS as notas fiscais (NFe e NFC-e) relacionadas
              a um CPF ou CNPJ, distinguindo ENTRADAS de SAIDAS.
    ========================================================================
*/

WITH parametros AS (
    SELECT
        :CPF_CNPJ AS documento_filtro,
        TO_DATE(:DATA_INICIAL, 'DD/MM/YYYY') AS data_inicial,
        TO_DATE(:DATA_FINAL, 'DD/MM/YYYY') AS data_final
    FROM DUAL
),

-- ========================================================================
-- BLOCO 1: NFe (Modelo 55)
-- ========================================================================
nfe AS (
    SELECT
        'NFE' AS TIPO_DOCUMENTO,
        55 AS MODELO,

        CASE
            WHEN d.co_emitente = p.documento_filtro AND d.co_tp_nf = 1 THEN 'SAIDA'
            WHEN d.co_destinatario = p.documento_filtro AND d.co_tp_nf = 1 THEN 'ENTRADA'
            WHEN d.co_emitente = p.documento_filtro AND d.co_tp_nf = 0 THEN 'ENTRADA'
            WHEN d.co_destinatario = p.documento_filtro AND d.co_tp_nf = 0 AND d.co_emitente != p.documento_filtro THEN 'SAIDA'
            ELSE 'INDEFINIDO'
        END AS OPERACAO,

        CASE
            WHEN d.co_emitente = p.documento_filtro THEN 'EMITENTE'
            WHEN d.co_destinatario = p.documento_filtro THEN 'DESTINATARIO'
            ELSE 'NAO_IDENTIFICADO'
        END AS PAPEL,

        CASE d.co_tp_nf
            WHEN 0 THEN 'ENTRADA'
            WHEN 1 THEN 'SAIDA'
            ELSE 'OUTRO'
        END AS TIPO_NF_EMITENTE,

        d.chave_acesso AS CHAVE_ACESSO,
        d.nnf AS NUMERO_NF,
        d.ide_serie AS SERIE,
        d.dhemi AS DATA_EMISSAO,
        d.dhsaient AS DATA_SAIDA_ENTRADA,
        d.co_emitente AS CNPJ_CPF_EMITENTE,
        d.xnome_emit AS NOME_EMITENTE,
        d.co_uf_emit AS UF_EMITENTE,
        d.xmun_emit AS MUNICIPIO_EMITENTE,
        d.co_destinatario AS CNPJ_CPF_DESTINATARIO,
        d.xnome_dest AS NOME_DESTINATARIO,
        d.co_uf_dest AS UF_DESTINATARIO,
        d.xmun_dest AS MUNICIPIO_DESTINATARIO,
        d.seq_nitem AS ITEM,
        d.prod_cprod AS CODIGO_PRODUTO,
        d.prod_xprod AS DESCRICAO_PRODUTO,
        d.prod_ncm AS NCM,
        d.co_cfop AS CFOP,
        d.prod_ucom AS UNIDADE,
        d.prod_qcom AS QUANTIDADE,
        d.prod_vuncom AS VALOR_UNITARIO,
        d.prod_vprod AS VALOR_PRODUTO,
        d.icms_vbc AS BC_ICMS,
        d.icms_vicms AS VALOR_ICMS,
        d.icms_picms AS ALIQ_ICMS,
        d.icms_cst AS CST_ICMS,
        d.icms_vbcst AS BC_ICMS_ST,
        d.icms_vicmsst AS VALOR_ICMS_ST,
        d.tot_vnf AS VALOR_TOTAL_NF,
        d.tot_vicms AS ICMS_TOTAL_NF,
        d.tot_vfrete AS FRETE_TOTAL,
        d.tot_vseg AS SEGURO_TOTAL,
        d.tot_vdesc AS DESCONTO_TOTAL,
        CASE d.co_finnfe
            WHEN 1 THEN 'NORMAL'
            WHEN 2 THEN 'COMPLEMENTAR'
            WHEN 3 THEN 'AJUSTE'
            WHEN 4 THEN 'DEVOLUCAO'
            ELSE TO_CHAR(d.co_finnfe)
        END AS FINALIDADE,
        TO_CHAR(d.infprot_cstat) AS STATUS,
        TO_CHAR(d.co_indfinal) AS IND_CONSUMIDOR_FINAL

    FROM
        bi.fato_nfe_detalhe d,
        parametros p
    WHERE
        GREATEST(COALESCE(d.dhsaient, d.dhemi), d.dhemi) BETWEEN p.data_inicial AND p.data_final
        AND (d.co_destinatario = p.documento_filtro OR d.co_emitente = p.documento_filtro)
        AND d.infprot_cstat IN ('100', '150')
),

-- ========================================================================
-- BLOCO 2: NFC-e (Modelo 65)
-- ========================================================================
nfce AS (
    SELECT
        'NFCE' AS TIPO_DOCUMENTO,
        65 AS MODELO,

        CASE
            WHEN d.co_emitente = p.documento_filtro THEN 'SAIDA'
            WHEN d.co_destinatario = p.documento_filtro THEN 'ENTRADA'
            ELSE 'INDEFINIDO'
        END AS OPERACAO,

        CASE
            WHEN d.co_emitente = p.documento_filtro THEN 'EMITENTE'
            WHEN d.co_destinatario = p.documento_filtro THEN 'DESTINATARIO'
            ELSE 'NAO_IDENTIFICADO'
        END AS PAPEL,

        'SAIDA' AS TIPO_NF_EMITENTE,

        d.chave_acesso AS CHAVE_ACESSO,
        d.nnf AS NUMERO_NF,
        d.ide_serie AS SERIE,
        d.dhemi AS DATA_EMISSAO,
        CAST(NULL AS DATE) AS DATA_SAIDA_ENTRADA,
        d.co_emitente AS CNPJ_CPF_EMITENTE,
        d.xnome_emit AS NOME_EMITENTE,
        d.co_uf_emit AS UF_EMITENTE,
        d.xmun_emit AS MUNICIPIO_EMITENTE,
        d.co_destinatario AS CNPJ_CPF_DESTINATARIO,
        d.xnome_dest AS NOME_DESTINATARIO,
        d.co_uf_dest AS UF_DESTINATARIO,
        d.xmun_dest AS MUNICIPIO_DESTINATARIO,
        d.seq_nitem AS ITEM,
        d.prod_cprod AS CODIGO_PRODUTO,
        d.prod_xprod AS DESCRICAO_PRODUTO,
        d.prod_ncm AS NCM,
        d.co_cfop AS CFOP,
        d.prod_ucom AS UNIDADE,
        d.prod_qcom AS QUANTIDADE,
        d.prod_vuncom AS VALOR_UNITARIO,
        d.prod_vprod AS VALOR_PRODUTO,
        d.icms_vbc AS BC_ICMS,
        d.icms_vicms AS VALOR_ICMS,
        d.icms_picms AS ALIQ_ICMS,
        d.icms_cst AS CST_ICMS,
        d.icms_vbcst AS BC_ICMS_ST,
        d.icms_vicmsst AS VALOR_ICMS_ST,
        d.tot_vnf AS VALOR_TOTAL_NF,
        d.tot_vicms AS ICMS_TOTAL_NF,
        CAST(NULL AS NUMBER) AS FRETE_TOTAL,
        CAST(NULL AS NUMBER) AS SEGURO_TOTAL,
        CAST(NULL AS NUMBER) AS DESCONTO_TOTAL,
        'NORMAL' AS FINALIDADE,
        TO_CHAR(d.infprot_cstat) AS STATUS,
        '1' AS IND_CONSUMIDOR_FINAL

    FROM
        bi.fato_nfce_detalhe d,
        parametros p
    WHERE
        d.dhemi BETWEEN p.data_inicial AND p.data_final
        AND (d.co_destinatario = p.documento_filtro OR d.co_emitente = p.documento_filtro)
        AND d.infprot_cstat IN ('100', '150')
)

SELECT * FROM nfe
UNION ALL
SELECT * FROM nfce
ORDER BY DATA_EMISSAO DESC, CHAVE_ACESSO, ITEM
