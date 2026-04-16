/*
===============================================================================
MÓDULO 85 - LOOKUP SIMÉTRICO DO BI/XML
-------------------------------------------------------------------------------
Objetivo
- Montar um lookup amplo de documentos para o cruzamento reverso.

Granularidade
- 1 linha por chave de acesso encontrada nas bases documentais.
===============================================================================
*/

WITH cte_ajuste AS (
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
    SELECT d.chave_acesso, d.infprot_cstat AS status, d.ide_serie AS serie, d.nnf,
           d.tot_vnf AS tot_doc, d.tot_vicms AS doc_icms, d.dhemi,
           d.co_uf_emit AS uf_in, d.co_uf_dest AS uf_fim,
           d.co_emitente, d.co_destinatario
    FROM bi.fato_nfe_detalhe d
    WHERE d.seq_nitem = '1' AND d.infprot_cstat IN ('100','150')

    UNION ALL

    SELECT n.chave_acesso, n.infprot_cstat, n.ide_serie, n.nnf,
           n.tot_vnf, n.tot_vicms, n.dhemi,
           NULL, NULL, n.co_emitente, n.co_destinatario
    FROM bi.fato_nfce_detalhe n
    WHERE n.seq_nitem = '1' AND n.infprot_cstat IN ('100','150')

    UNION ALL

    SELECT c.chave_acesso, c.infprot_cstat, c.co_serie, c.co_nct,
           c.prest_vtprest, c.icms_vicms, c.dhemi,
           c.co_ufini, c.co_uffim, c.emit_co_cnpj, c.cnpj_cpf_tomador
    FROM cte_ajuste c
    WHERE c.infprot_cstat IN ('100','150')
);
