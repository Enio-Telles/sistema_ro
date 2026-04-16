/*
===============================================================================
MÓDULO 86 - EFD SEM CORRESPONDENTE NO BI/XML
-------------------------------------------------------------------------------
Objetivo
- Identificar documentos escriturados na EFD sem correspondente no conjunto principal.

Granularidade
- 1 linha por documento escriturado na EFD e não localizado em docs_bi_xml.
===============================================================================
*/

WITH docs_n_cruzados AS (
    SELECT
        TO_CHAR(e.efd_ref, 'YYYY/MM') AS efd_ref,
        TO_CHAR(e.data_entrega, 'DD/MM/YYYY HH24:MI:SS') AS efd_data_entrega,
        e.chave_efd,
        e.efd_icms,
        e.ind_oper,
        e.cod_mod,
        e.reg,
        e.ser,
        e.num_doc,
        e.cod_sit,
        e.efd_ref AS efd_ref_data
    FROM efd_documentos_validos e
    JOIN parametros_docs p ON 1=1
    WHERE e.efd_ref BETWEEN p.data_inicial AND p.data_final
      AND e.chave_efd IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM docs_bi_xml d WHERE d.chave_acesso = e.chave_efd
      )
)
SELECT nc.*, bl.status, bl.serie, bl.nnf, bl.tot_doc, bl.doc_icms, bl.dhemi,
       bl.uf_in, bl.uf_fim, bl.co_emitente, bl.co_destinatario
FROM docs_n_cruzados nc
LEFT JOIN bi_lookup_simetrico bl
  ON bl.chave_acesso = nc.chave_efd;
