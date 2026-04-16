/*
===============================================================================
MÓDULO 87 - RESULTADO FINAL DA AUDITORIA DOCUMENTAL
-------------------------------------------------------------------------------
Objetivo
- Entregar uma visão única com o cruzamento principal e o cruzamento reverso.

Granularidade
- 1 linha por documento auditado.

Uso sugerido
- Relatório analítico por chave de acesso.
===============================================================================
*/

SELECT
    b.status,
    b.operacao,
    b.chave_acesso,
    b.serie,
    b.nnf,
    b.tot_doc,
    b.doc_icms,
    b.efd_icms,
    b.diferenca,
    CASE
        WHEN b.diferenca < 0 THEN 'NEGAT'
        WHEN b.diferenca > 0 THEN 'POSIT'
        ELSE 'NULA'
    END AS tipo_dif,
    b.efd_ref,
    b.dhemi,
    b.data_efd_x_doc || NVL2(me.evento_descevento, ' - ' || me.evento_descevento || ' (' || me.evento_dhevento || ')', NULL) AS data_efd_x_doc,
    b.efd_data_entrega,
    b.uf_in,
    b.uf_fim,
    b.co_emitente,
    b.co_destinatario
FROM cruzamento_docs_efd b
LEFT JOIN omissoes_eventos_manifestacao me
  ON me.chave_acesso = b.chave_acesso

UNION ALL

SELECT
    bl.status,
    CASE WHEN nc.ind_oper = 0 THEN '_Entrada_EFD_N_Cruzada' ELSE '_Saída_EFD_N_Cruzada' END AS operacao,
    nc.chave_efd AS chave_acesso,
    bl.serie,
    bl.nnf,
    bl.tot_doc,
    bl.doc_icms,
    nc.efd_icms,
    (bl.doc_icms - nc.efd_icms) AS diferenca,
    CASE
        WHEN (bl.doc_icms - nc.efd_icms) < 0 THEN 'NEGAT'
        WHEN (bl.doc_icms - nc.efd_icms) > 0 THEN 'POSIT'
        ELSE 'NULA'
    END AS tipo_dif,
    nc.efd_ref,
    bl.dhemi,
    CASE
        WHEN bl.chave_acesso IS NULL THEN '(Documento da EFD sem correspondente no BI/XML)'
        WHEN TRUNC(nc.efd_ref_data, 'MM') = TRUNC(bl.dhemi, 'MM') THEN 'igual'
        ELSE 'diferente'
    END AS data_efd_x_doc,
    nc.efd_data_entrega,
    bl.uf_in,
    bl.uf_fim,
    bl.co_emitente,
    bl.co_destinatario
FROM efd_nao_cruzada_bi_xml nc
LEFT JOIN bi_lookup_simetrico bl
  ON bl.chave_acesso = nc.chave_efd;
