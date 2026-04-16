/*
===============================================================================
MÓDULO 83 - CRUZAMENTO DOCUMENTO x EFD
-------------------------------------------------------------------------------
Objetivo
- Cruzar o documento do BI/XML com a escrituração da EFD pela chave de acesso.

Granularidade
- 1 linha por documento do conjunto principal docs.

Saídas analíticas
- valor de ICMS no documento e na EFD;
- diferença;
- coincidência ou não do período de escrituração.
===============================================================================
*/

SELECT
    d.status,
    d.operacao,
    d.chave_acesso,
    d.serie,
    d.nnf,
    d.tot_doc,
    d.doc_icms,
    e.efd_icms,
    (d.doc_icms - e.efd_icms) AS diferenca,
    TO_CHAR(e.efd_ref, 'YYYY/MM') AS efd_ref,
    d.dhemi,
    CASE
        WHEN e.efd_ref IS NULL THEN '(Confirmar Omissao na EFD)'
        WHEN TRUNC(e.efd_ref, 'MM') = TRUNC(d.dhemi, 'MM') THEN 'igual'
        ELSE 'diferente'
    END AS data_efd_x_doc,
    TO_CHAR(e.data_entrega, 'DD/MM/YYYY HH24:MI:SS') AS efd_data_entrega,
    d.uf_in,
    d.uf_fim,
    d.co_emitente,
    d.co_destinatario
FROM docs_bi_xml d
LEFT JOIN efd_documentos_validos e
  ON e.chave_efd = d.chave_acesso;
