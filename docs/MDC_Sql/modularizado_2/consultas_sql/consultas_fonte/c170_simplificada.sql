/*
 * EXTRAÇÃO SIMPLIFICADA: Registro C170 (Itens das NFs)
 * Filtra apenas por CNPJ e data_limite_processamento.
 * Traz campos essenciais para cruzamento de ressarcimento.
 */
WITH
    PARAMETROS AS (
        SELECT
:CNPJ AS cnpj_filtro,
            NVL (
                TO_DATE(
:data_limite_processamento,
                    'DD/MM/YYYY'
                ),
                TRUNC(SYSDATE)
            ) AS dt_corte
        FROM dual
    ),
    ARQUIVOS_RANKING AS (
        SELECT r.id AS reg_0000_id, r.cnpj, r.dt_ini, r.data_entrega, ROW_NUMBER() OVER (
                PARTITION BY
                    r.cnpj, r.dt_ini
                ORDER BY r.data_entrega DESC, r.id DESC
            ) AS rn
        FROM sped.reg_0000 r
            JOIN PARAMETROS p ON r.cnpj = p.cnpj_filtro
        WHERE
            r.data_entrega <= p.dt_corte
    )

SELECT
    TO_CHAR(arq.dt_ini, 'YYYY/MM') AS periodo_efd,
    c100.chv_nfe,
    c100.ind_oper,
    c100.num_doc,
    CASE
        WHEN c100.dt_doc IS NOT NULL
        AND REGEXP_LIKE (c100.dt_doc, '^\d{8}$') THEN TO_DATE(c100.dt_doc, 'DDMMYYYY')
        ELSE NULL
    END AS dt_doc,
    c170.num_item,
    c170.cod_item,
    C170.descr_compl,
    c170.cfop,
    c170.cst_icms,
    NVL (c170.qtd, 0) AS qtd,
    c170.unid,
    c170.vl_item,
    NVL (c170.vl_icms, 0) AS vl_icms,
    NVL (c170.vl_bc_icms, 0) AS vl_bc_icms,
    c170.aliq_icms,
    NVL (c170.vl_bc_icms_st, 0) AS vl_bc_icms_st,
    NVL (c170.vl_icms_st, 0) AS vl_icms_st,
    c170.aliq_st
FROM
    sped.reg_c170 c170
    INNER JOIN ARQUIVOS_RANKING arq ON arq.reg_0000_id = c170.reg_0000_id
    AND arq.rn = 1
    INNER JOIN sped.reg_c100 c100 ON c100.id = c170.reg_c100_id
ORDER BY arq.dt_ini, c100.num_doc, c170.num_item
