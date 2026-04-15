/*
===============================================================================
MDC 06 - ITENS EFD (C170)
-------------------------------------------------------------------------------
Objetivo
- Formar a visão canônica item a item dos documentos C100.
- Base necessária para ressarcimento, inventário/última entrada, CFOP, CST,
  auditoria de quantidades e comparação com XML.

Granularidade
- 1 linha por item do documento fiscal.
===============================================================================
*/
WITH docs AS (
    SELECT reg_c100_id, reg_0000_id, chv_nfe, ind_oper, cod_sit, dt_doc
    FROM (
        SELECT
            c.id AS reg_c100_id,
            c.reg_0000_id,
            c.chv_nfe,
            c.ind_oper,
            c.cod_sit,
            c.dt_doc
        FROM sped.reg_c100 c
        JOIN (
            SELECT reg_0000_id
            FROM (
                SELECT r.id AS reg_0000_id,
                       ROW_NUMBER() OVER (
                           PARTITION BY r.cnpj, r.dt_ini, NVL(r.dt_fin, r.dt_ini)
                           ORDER BY r.data_entrega DESC, r.id DESC
                       ) rn
                FROM sped.reg_0000 r
                WHERE r.cnpj = REGEXP_REPLACE(TRIM(:CNPJ_CPF), '[^0-9]', '')
                  AND r.dt_ini BETWEEN TO_DATE(:DATA_INICIAL, 'DD/MM/YYYY')
                                   AND TO_DATE(:DATA_FINAL, 'DD/MM/YYYY')
            ) WHERE rn = 1
        ) a ON a.reg_0000_id = c.reg_0000_id
    )
)
SELECT
    d.chv_nfe,
    d.ind_oper,
    d.cod_sit,
    d.dt_doc,
    i.reg_0000_id,
    i.reg_c100_id,
    i.id AS reg_c170_id,
    i.num_item,
    i.cod_item,
    i.descr_compl,
    i.cfop,
    i.unid,
    i.qtd,
    i.vl_item,
    i.vl_desc,
    i.vl_bc_icms,
    i.aliq_icms,
    i.vl_icms,
    i.vl_bc_icms_st,
    i.vl_icms_st
FROM sped.reg_c170 i
JOIN docs d
  ON d.reg_c100_id = i.reg_c100_id;
