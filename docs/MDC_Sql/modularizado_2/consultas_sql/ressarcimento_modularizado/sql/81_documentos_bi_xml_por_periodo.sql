/*
===============================================================================
MÓDULO 81 - DOCUMENTOS DO BI/XML POR PERÍODO
-------------------------------------------------------------------------------
Objetivo
- Consolidar o conjunto principal de documentos eletrônicos a auditar.

Granularidade
- 1 linha por chave de acesso do documento.

Fontes
- bi.fato_nfe_detalhe
- bi.fato_nfce_detalhe
- cte_ajuste

Regra de negócio
- A classificação depende do modelo e do papel do contribuinte no documento.
===============================================================================
*/

WITH parametros AS (
    SELECT
        REGEXP_REPLACE(TRIM(:CNPJ), '[^0-9]', '') AS cnpj,
        NVL(TO_DATE(:DATA_INICIAL, 'DD/MM/YYYY'), DATE '1900-01-01') AS data_inicial,
        NVL(TO_DATE(:DATA_FINAL,   'DD/MM/YYYY'), TRUNC(SYSDATE))    AS data_final
    FROM dual
),
cte_ajuste AS (
    SELECT
        c.chave_acesso,
        c.infprot_cstat,
        c.co_serie,
        c.co_nct,
        c.prest_vtprest,
        c.icms_vicms,
        c.dhemi,
        c.emit_co_cnpj,
        c.co_ufini,
        c.co_uffim,
        CASE
            WHEN c.co_tomador3 = '0' THEN c.rem_cnpj_cpf
            WHEN c.co_tomador3 = '1' THEN c.exp_co_cnpj_cpf
            WHEN c.co_tomador3 = '2' THEN c.receb_cnpj_cpf
            WHEN c.co_tomador3 = '3' THEN c.dest_cnpj_cpf
            ELSE c.co_tomador4_cnpj_cpf
        END AS cnpj_cpf_tomador
    FROM bi.fato_cte_detalhe c
)
SELECT * FROM (
    SELECT d.infprot_cstat AS status, 'Entrada' AS operacao, d.chave_acesso,
           d.ide_serie AS serie, d.nnf, d.tot_vnf AS tot_doc, d.tot_vicms AS doc_icms,
           d.dhemi, d.co_uf_emit AS uf_in, d.co_uf_dest AS uf_fim,
           d.co_emitente, d.co_destinatario
    FROM bi.fato_nfe_detalhe d JOIN parametros p ON 1=1
    WHERE d.dhemi BETWEEN p.data_inicial AND p.data_final
      AND d.co_destinatario = p.cnpj AND d.co_emitente <> p.cnpj
      AND d.co_tp_nf = 1 AND d.infprot_cstat IN ('100','150') AND d.seq_nitem = '1'

    UNION ALL
    SELECT d.infprot_cstat, 'Entrada Propria', d.chave_acesso,
           d.ide_serie, d.nnf, d.tot_vnf, d.tot_vicms,
           d.dhemi, d.co_uf_emit, d.co_uf_dest,
           d.co_emitente, d.co_destinatario
    FROM bi.fato_nfe_detalhe d JOIN parametros p ON 1=1
    WHERE d.dhemi BETWEEN p.data_inicial AND p.data_final
      AND d.co_emitente = p.cnpj AND d.co_tp_nf = 0
      AND d.infprot_cstat IN ('100','150') AND d.seq_nitem = '1'

    UNION ALL
    SELECT d.infprot_cstat, 'Indicado como remetente', d.chave_acesso,
           d.ide_serie, d.nnf, d.tot_vnf, d.tot_vicms,
           d.dhemi, d.co_uf_emit, d.co_uf_dest,
           d.co_emitente, d.co_destinatario
    FROM bi.fato_nfe_detalhe d JOIN parametros p ON 1=1
    WHERE d.dhemi BETWEEN p.data_inicial AND p.data_final
      AND d.co_destinatario = p.cnpj AND d.co_emitente <> p.cnpj
      AND d.co_tp_nf = 0 AND d.infprot_cstat IN ('100','150') AND d.seq_nitem = '1'

    UNION ALL
    SELECT d.infprot_cstat, 'Saida 55', d.chave_acesso,
           d.ide_serie, d.nnf, d.tot_vnf, d.tot_vicms,
           d.dhemi, d.co_uf_emit, d.co_uf_dest,
           d.co_emitente, d.co_destinatario
    FROM bi.fato_nfe_detalhe d JOIN parametros p ON 1=1
    WHERE d.dhemi BETWEEN p.data_inicial AND p.data_final
      AND d.co_emitente = p.cnpj AND d.co_tp_nf = 1
      AND d.infprot_cstat IN ('100','150') AND d.seq_nitem = '1'

    UNION ALL
    SELECT n.infprot_cstat, 'Saida 65', n.chave_acesso,
           n.ide_serie, n.nnf, n.tot_vnf, n.tot_vicms,
           n.dhemi, NULL, NULL,
           n.co_emitente, n.co_destinatario
    FROM bi.fato_nfce_detalhe n JOIN parametros p ON 1=1
    WHERE n.dhemi BETWEEN p.data_inicial AND p.data_final
      AND n.co_emitente = p.cnpj AND n.infprot_cstat IN ('100','150') AND n.seq_nitem = '1'

    UNION ALL
    SELECT c.infprot_cstat,
           CASE
               WHEN c.cnpj_cpf_tomador = p.cnpj AND c.emit_co_cnpj <> p.cnpj THEN 'Tomador 57'
               WHEN c.emit_co_cnpj = p.cnpj THEN 'Saida 57'
               ELSE 'outros'
           END,
           c.chave_acesso, c.co_serie, c.co_nct, c.prest_vtprest, c.icms_vicms,
           c.dhemi, c.co_ufini, c.co_uffim, c.emit_co_cnpj, c.cnpj_cpf_tomador
    FROM cte_ajuste c JOIN parametros p ON 1=1
    WHERE c.dhemi BETWEEN p.data_inicial AND p.data_final
      AND (c.cnpj_cpf_tomador = p.cnpj OR c.emit_co_cnpj = p.cnpj)
      AND c.infprot_cstat IN ('100','150')
)
WHERE operacao <> 'outros';
