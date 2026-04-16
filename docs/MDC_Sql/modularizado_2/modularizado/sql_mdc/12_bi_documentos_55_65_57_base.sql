/*
===============================================================================
MDC 12 - DOCUMENTOS ELETRÔNICOS BI/XML (55, 65 e 57)
-------------------------------------------------------------------------------
Objetivo
- Normalizar NF-e, NFC-e e CT-e num mesmo contrato documental.
- Base canônica da trilha de auditoria EFD x documentos e de várias consultas
  de nota/XML usadas nas demais análises.

Granularidade
- 1 linha por documento eletrônico autorizado (usando item 1 como linha-mãe).
===============================================================================
*/
WITH parametros AS (
    SELECT
        REGEXP_REPLACE(TRIM(:CNPJ_CPF), '[^0-9]', '') AS cnpj,
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
SELECT
    '55' AS modelo,
    d.infprot_cstat AS status,
    CASE
        WHEN d.co_destinatario = p.cnpj AND d.co_emitente <> p.cnpj AND d.co_tp_nf = 0 THEN 'Entrada 55'
        WHEN d.co_emitente     = p.cnpj AND d.co_tp_nf = 1 THEN 'Saida 55'
        WHEN d.co_emitente     = p.cnpj AND d.co_tp_nf = 0 THEN 'Entrada própria 55'
        ELSE 'Outro 55'
    END AS papel_contribuinte,
    d.chave_acesso,
    d.ide_serie AS serie,
    d.nnf,
    d.tot_vnf AS tot_doc,
    d.tot_vicms AS doc_icms,
    d.dhemi,
    d.co_uf_emit AS uf_in,
    d.co_uf_dest AS uf_fim,
    d.co_emitente,
    d.co_destinatario
FROM bi.fato_nfe_detalhe d
JOIN parametros p ON 1 = 1
WHERE d.dhemi BETWEEN p.data_inicial AND p.data_final
  AND d.infprot_cstat IN ('100','150')
  AND d.seq_nitem = '1'
  AND (d.co_emitente = p.cnpj OR d.co_destinatario = p.cnpj)
UNION ALL
SELECT
    '65' AS modelo,
    n.infprot_cstat AS status,
    'Saida 65' AS papel_contribuinte,
    n.chave_acesso,
    n.ide_serie AS serie,
    n.nnf,
    n.tot_vnf AS tot_doc,
    n.tot_vicms AS doc_icms,
    n.dhemi,
    NULL AS uf_in,
    NULL AS uf_fim,
    n.co_emitente,
    n.co_destinatario
FROM bi.fato_nfce_detalhe n
JOIN parametros p ON 1 = 1
WHERE n.dhemi BETWEEN p.data_inicial AND p.data_final
  AND n.co_emitente = p.cnpj
  AND n.infprot_cstat IN ('100','150')
  AND n.seq_nitem = '1'
UNION ALL
SELECT
    '57' AS modelo,
    c.infprot_cstat AS status,
    CASE
        WHEN c.cnpj_cpf_tomador = p.cnpj AND c.emit_co_cnpj <> p.cnpj THEN 'Tomador 57'
        WHEN c.emit_co_cnpj = p.cnpj THEN 'Saida 57'
        ELSE 'Outro 57'
    END AS papel_contribuinte,
    c.chave_acesso,
    c.co_serie AS serie,
    c.co_nct AS nnf,
    c.prest_vtprest AS tot_doc,
    c.icms_vicms AS doc_icms,
    c.dhemi,
    c.co_ufini AS uf_in,
    c.co_uffim AS uf_fim,
    c.emit_co_cnpj AS co_emitente,
    c.cnpj_cpf_tomador AS co_destinatario
FROM cte_ajuste c
JOIN parametros p ON 1 = 1
WHERE c.dhemi BETWEEN p.data_inicial AND p.data_final
  AND c.infprot_cstat IN ('100','150')
  AND (c.emit_co_cnpj = p.cnpj OR c.cnpj_cpf_tomador = p.cnpj);
