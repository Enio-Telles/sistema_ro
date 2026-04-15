/*
===============================================================================
MDC 05 - DOCUMENTOS EFD (C100)
-------------------------------------------------------------------------------
Objetivo
- Formar o cabeçalho canônico dos documentos escriturados na EFD.
- Base para ressarcimento, auditoria EFD x XML, relatórios EFD Master e
  resumos de entradas/saídas.

Granularidade
- 1 linha por documento fiscal escriturado.
===============================================================================
*/
WITH arquivos_validos AS (
    SELECT reg_0000_id, cnpj, dt_ini, data_entrega
    FROM (
        SELECT
            r.id AS reg_0000_id,
            r.cnpj,
            r.dt_ini,
            r.data_entrega,
            ROW_NUMBER() OVER (
                PARTITION BY r.cnpj, r.dt_ini, NVL(r.dt_fin, r.dt_ini)
                ORDER BY r.data_entrega DESC, r.id DESC
            ) rn
        FROM sped.reg_0000 r
        WHERE r.cnpj = REGEXP_REPLACE(TRIM(:CNPJ_CPF), '[^0-9]', '')
          AND r.dt_ini BETWEEN TO_DATE(:DATA_INICIAL, 'DD/MM/YYYY')
                           AND TO_DATE(:DATA_FINAL, 'DD/MM/YYYY')
    )
    WHERE rn = 1
)
SELECT
    a.cnpj,
    a.dt_ini          AS efd_ref,
    a.data_entrega,
    c.reg_0000_id,
    c.id              AS reg_c100_id,
    c.reg,
    c.ind_oper,
    c.ind_emit,
    c.cod_part,
    c.cod_mod,
    c.cod_sit,
    c.ser,
    c.num_doc,
    c.chv_nfe,
    c.dt_doc,
    c.dt_e_s,
    c.vl_doc,
    c.vl_desc,
    c.vl_merc,
    c.vl_bc_icms,
    c.vl_icms,
    c.vl_bc_icms_st,
    c.vl_icms_st,
    c.vl_ipi,
    c.vl_pis,
    c.vl_cofins
FROM sped.reg_c100 c
JOIN arquivos_validos a
  ON a.reg_0000_id = c.reg_0000_id;
