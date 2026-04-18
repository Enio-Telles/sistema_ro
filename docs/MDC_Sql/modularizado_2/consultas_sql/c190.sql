WITH PARAMETROS AS (
    SELECT
        :CNPJ AS cnpj_filtro,
        GREATEST(
            NVL(TO_DATE(:DATA_INICIAL, 'DD/MM/YYYY'), DATE '2020-01-01'),
            DATE '2020-01-01'
        ) AS dt_ini_filtro,
        NVL(TO_DATE(:DATA_FINAL, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_fim_filtro,
        NVL(TO_DATE(:DATA_LIMITE_PROCESSAMENTO, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_corte
    FROM dual
),

ARQUIVOS_PROCESSADOS AS (
    SELECT
        r.id            AS reg_0000_id,
        r.cnpj,
        r.cod_fin       AS cod_fin_efd,
        r.dt_ini,
        r.dt_fin,
        r.data_entrega,
        ROW_NUMBER() OVER (
            PARTITION BY r.cnpj, r.dt_ini, NVL(r.dt_fin, r.dt_ini)
            ORDER BY r.data_entrega DESC, r.id DESC
        ) AS rn
    FROM sped.reg_0000 r
    JOIN PARAMETROS p
      ON r.cnpj = p.cnpj_filtro
    WHERE r.data_entrega <= p.dt_corte
),

ARQUIVOS_VALIDOS AS (
    SELECT
        reg_0000_id,
        cnpj,
        cod_fin_efd,
        dt_ini,
        dt_fin,
        data_entrega
    FROM ARQUIVOS_PROCESSADOS
    WHERE rn = 1
),

ARQUIVOS_DO_PERIODO AS (
    SELECT a.*
    FROM ARQUIVOS_VALIDOS a
    CROSS JOIN PARAMETROS p
    WHERE a.dt_fin >= p.dt_ini_filtro
      AND a.dt_ini <= p.dt_fim_filtro
),

OUTROS_ARQUIVOS AS (
    SELECT a.*
    FROM ARQUIVOS_VALIDOS a
    CROSS JOIN PARAMETROS p
    WHERE NOT (
        a.dt_fin >= p.dt_ini_filtro
        AND a.dt_ini <= p.dt_fim_filtro
    )
),

C100_PERIODO AS (
    SELECT
        'PERIODO'       AS origem_busca,
        a.dt_ini        AS periodo_efd_dt,
        a.data_entrega  AS data_entrega_efd_dt,
        a.cod_fin_efd,
        c100.id         AS reg_c100_id,
        c100.reg        AS c100,
        c100.cod_sit,
        c100.ind_oper,
        c100.chv_nfe,
        c100.num_doc,
        CASE
            WHEN c100.dt_doc IS NOT NULL
             AND REGEXP_LIKE(TRIM(c100.dt_doc), '^\d{8}$')
            THEN TO_DATE(TRIM(c100.dt_doc), 'DDMMYYYY')
        END AS dt_doc,
        CASE
            WHEN c100.dt_e_s IS NOT NULL
             AND REGEXP_LIKE(TRIM(c100.dt_e_s), '^\d{8}$')
            THEN TO_DATE(TRIM(c100.dt_e_s), 'DDMMYYYY')
        END AS dt_e_s
    FROM sped.reg_c100 c100
    JOIN ARQUIVOS_DO_PERIODO a
      ON a.reg_0000_id = c100.reg_0000_id
),

C100_EXTEMP_RAW AS (
    SELECT
        'EXTEMPORANEA'  AS origem_busca,
        a.dt_ini        AS periodo_efd_dt,
        a.data_entrega  AS data_entrega_efd_dt,
        a.cod_fin_efd,
        c100.id         AS reg_c100_id,
        c100.reg        AS c100,
        c100.cod_sit,
        c100.ind_oper,
        c100.chv_nfe,
        c100.num_doc,
        CASE
            WHEN c100.dt_doc IS NOT NULL
             AND REGEXP_LIKE(TRIM(c100.dt_doc), '^\d{8}$')
            THEN TO_DATE(TRIM(c100.dt_doc), 'DDMMYYYY')
        END AS dt_doc,
        CASE
            WHEN c100.dt_e_s IS NOT NULL
             AND REGEXP_LIKE(TRIM(c100.dt_e_s), '^\d{8}$')
            THEN TO_DATE(TRIM(c100.dt_e_s), 'DDMMYYYY')
        END AS dt_e_s
    FROM sped.reg_c100 c100
    JOIN OUTROS_ARQUIVOS a
      ON a.reg_0000_id = c100.reg_0000_id
),

C100_EXTEMP AS (
    SELECT
        x.*,
        CASE
            WHEN x.dt_doc IS NOT NULL AND x.dt_e_s IS NOT NULL THEN GREATEST(x.dt_doc, x.dt_e_s)
            ELSE COALESCE(x.dt_doc, x.dt_e_s)
        END AS dt_ref
    FROM C100_EXTEMP_RAW x
    CROSS JOIN PARAMETROS p
    WHERE
        CASE
            WHEN x.dt_doc IS NOT NULL AND x.dt_e_s IS NOT NULL THEN GREATEST(x.dt_doc, x.dt_e_s)
            ELSE COALESCE(x.dt_doc, x.dt_e_s)
        END BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro
),

BASE_FINAL AS (
    SELECT
        origem_busca,
        periodo_efd_dt,
        data_entrega_efd_dt,
        cod_fin_efd,
        reg_c100_id,
        c100,
        cod_sit,
        ind_oper,
        chv_nfe,
        num_doc,
        dt_doc,
        dt_e_s
    FROM C100_PERIODO

    UNION ALL

    SELECT
        origem_busca,
        periodo_efd_dt,
        data_entrega_efd_dt,
        cod_fin_efd,
        reg_c100_id,
        c100,
        cod_sit,
        ind_oper,
        chv_nfe,
        num_doc,
        dt_doc,
        dt_e_s
    FROM C100_EXTEMP
)

SELECT
    b.origem_busca,
    TO_CHAR(b.periodo_efd_dt,      'MM/YYYY')    AS periodo_efd,
    TO_CHAR(b.data_entrega_efd_dt, 'DD/MM/YYYY') AS data_entrega_efd,
    b.cod_fin_efd,
    b.c100,
    b.cod_sit,
    b.ind_oper,
    b.chv_nfe,
    b.num_doc,
    b.dt_doc,
    b.dt_e_s,
    c190.reg AS c190,
    c190.cst_icms,
    c190.cfop,
    c190.aliq_icms,
    c190.vl_opr,
    c190.vl_bc_icms,
    c190.vl_bc_icms_st,
    c190.vl_icms,
    c190.vl_icms_st,
    c190.vl_red_bc,
    c190.vl_ipi,
    c190.cod_obs
FROM BASE_FINAL b
LEFT JOIN sped.reg_c190 c190
       ON c190.reg_c100_id = b.reg_c100_id
ORDER BY
    b.periodo_efd_dt,
    b.dt_doc NULLS LAST,
    b.dt_e_s NULLS LAST,
    b.num_doc,
    c190.cfop;
