WITH tab_infadic AS (
    SELECT /*+ PARALLEL(4) */
        a.nsu,
        substr(ident.chave_acesso, 4, 44) AS chave_acesso,
        ident.infAdFisco,
        ident.infCpl
    FROM
        xdb_nfe.arquivo@XDB_NFE_PRODUCAO a,
        XMLTable(
            XMLNamespaces (DEFAULT 'http://www.portalfiscal.inf.br/nfe'),
            '//infNFe' passing a.xml
            COLUMNS
                chave_acesso VARCHAR2(50)   PATH '@Id',
                infAdFisco   VARCHAR2(2000) PATH 'infAdic/infAdFisco[1]',
                infCpl       VARCHAR2(4000) PATH 'infAdic/infCpl[1]'
        ) ident,
        XDB_NFE.DFE@XDB_NFE_PRODUCAO dados
    WHERE a.nsu = dados.nsu
      -- Substituído pelo parâmetro :cnpj
      AND (dados.dest_id = :cnpj OR dados.emit_id = :cnpj)
)

SELECT DISTINCT
    -- 1. CLASSIFICAÇÃO DA OPERAÇÃO
    CASE
        -- CNPJ consultado é o EMITENTE
        WHEN d.co_emitente = :cnpj AND d.co_tp_nf = 1 THEN '1 - SAIDA'
        WHEN d.co_emitente = :cnpj AND d.co_tp_nf = 0 THEN '0 - ENTRADA'

        -- CNPJ consultado é o DESTINATÁRIO
        WHEN d.co_destinatario = :cnpj AND d.co_tp_nf = 1 THEN '0 - ENTRADA'
        WHEN d.co_destinatario = :cnpj AND d.co_tp_nf = 0 THEN '1 - SAIDA'

        ELSE 'INDEFINIDO'
    END AS tipo_operacao,

    -- 2. DADOS DE CONTATO E ENDEREÇO DINÂMICOS
    CASE
        WHEN d.co_emitente = :cnpj THEN NULL -- Não temos fone_emit na base
        ELSE UPPER(d.fone_dest)
    END AS telefone,

    CASE
        WHEN d.co_emitente = :cnpj THEN NULL -- Não temos email_emit na base
        ELSE UPPER(d.email_dest)
    END AS email,

    CASE
        WHEN d.co_emitente = :cnpj THEN UPPER(d.xmun_emit)
        ELSE UPPER(d.xmun_dest)
    END AS municipio,

    CASE
        WHEN d.co_emitente = :cnpj THEN UPPER(d.co_uf_emit)
        ELSE UPPER(d.co_uf_dest)
    END AS uf,

    -- 3. INFORMAÇÕES DO XML
    infadic.infadfisco,
    infadic.infcpl

FROM bi.fato_nfe_detalhe d
LEFT JOIN tab_infadic infadic ON d.chave_acesso = infadic.chave_acesso
-- Substituído pelo parâmetro :cnpj
WHERE (d.co_destinatario = :cnpj OR d.co_emitente = :cnpj)
  AND d.dhemi BETWEEN TO_DATE('01/06/2025', 'DD/MM/YYYY') AND TO_DATE('31/12/2025', 'DD/MM/YYYY');
