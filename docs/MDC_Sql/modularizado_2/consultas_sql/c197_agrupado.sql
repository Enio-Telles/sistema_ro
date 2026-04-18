WITH PARAMETROS AS (
    -- 1. Padronização dos inputs e definição da Data de Corte
    SELECT
        :CNPJ AS cnpj_filtro,
        TO_DATE(:data_inicial, 'DD/MM/YYYY') AS dt_ini_filtro,
        TO_DATE(:data_final,   'DD/MM/YYYY') AS dt_fim_filtro,
        NVL(TO_DATE(:data_limite_processamento, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_corte
    FROM dual
),

TODOS_ARQUIVOS_VALIDOS AS (
    -- 2. Seleção do arquivo mais recente respeitando a Data de Corte
    SELECT
        r.ID              AS reg_0000_id,
        r.DT_INI          AS dt_ini,
        r.DT_FIN          AS dt_fin,
        r.CNPJ            AS cnpj,
        r.DATA_ENTREGA    AS data_entrega,
        r.COD_FIN         AS cod_fin_efd,
        p.dt_corte, p.dt_ini_filtro, p.dt_fim_filtro,
        ROW_NUMBER() OVER (
            PARTITION BY r.CNPJ, r.DT_INI
            ORDER BY r.DATA_ENTREGA DESC
        ) AS rn
    FROM sped.reg_0000 r
    JOIN PARAMETROS p ON r.CNPJ = p.cnpj_filtro
    WHERE r.DATA_ENTREGA <= p.dt_corte
),

ARQUIVOS_DO_PERIODO AS (
    -- 3a. Arquivos EFD cujo período de apuração está dentro do filtro
    SELECT * FROM TODOS_ARQUIVOS_VALIDOS
    WHERE rn = 1
      AND dt_ini BETWEEN dt_ini_filtro AND dt_fim_filtro
),

OUTROS_ARQUIVOS AS (
    -- 3b. Arquivos EFD de outros períodos (para notas extemporâneas)
    SELECT * FROM TODOS_ARQUIVOS_VALIDOS
    WHERE rn = 1
      AND (dt_ini < dt_ini_filtro OR dt_ini > dt_fim_filtro)
),

BASE_C197 AS (
    -- 4. União das notas do período com as extemporâneas
    SELECT
        arq.dt_ini                                                   AS periodo_efd_dt,
        c100.chv_nfe,
        c197.cod_aj,
        c197.descr_compl_aj,
        c197.vl_bc_icms,
        c197.vl_icms,
        c197.vl_outros
    FROM sped.reg_c197 c197
    INNER JOIN sped.reg_c100 c100 ON c197.reg_c100_id = c100.id
    INNER JOIN ARQUIVOS_DO_PERIODO arq ON c100.reg_0000_id = arq.reg_0000_id

    UNION ALL

    SELECT
        arq.dt_ini                                                   AS periodo_efd_dt,
        c100.chv_nfe,
        c197.cod_aj,
        c197.descr_compl_aj,
        c197.vl_bc_icms,
        c197.vl_icms,
        c197.vl_outros
    FROM sped.reg_c197 c197
    INNER JOIN sped.reg_c100 c100 ON c197.reg_c100_id = c100.id
    INNER JOIN OUTROS_ARQUIVOS arq ON c100.reg_0000_id = arq.reg_0000_id
    WHERE GREATEST(
            CASE WHEN c100.dt_doc IS NOT NULL AND REGEXP_LIKE(c100.dt_doc, '^\d{8}$') THEN TO_DATE(c100.dt_doc, 'DDMMYYYY') ELSE NULL END,
            NVL(
              CASE WHEN c100.dt_e_s IS NOT NULL AND REGEXP_LIKE(c100.dt_e_s, '^\d{8}$') THEN TO_DATE(c100.dt_e_s, 'DDMMYYYY') ELSE NULL END,
              CASE WHEN c100.dt_doc IS NOT NULL AND REGEXP_LIKE(c100.dt_doc, '^\d{8}$') THEN TO_DATE(c100.dt_doc, 'DDMMYYYY') ELSE NULL END
            )
          ) BETWEEN arq.dt_ini_filtro AND arq.dt_fim_filtro
)

-- 5. AGREGAMENTO FINAL
SELECT
    TO_CHAR(periodo_efd_dt, 'YYYY/MM') AS periodo_efd,
    cod_aj,
    descr_compl_aj,
    COUNT(DISTINCT chv_nfe)            AS qtd_notas_afetadas,
    SUM(vl_bc_icms)                    AS total_bc_icms_c197,
    SUM(vl_icms)                       AS total_icms_c197,
    SUM(vl_outros)                     AS total_outros_c197
FROM BASE_C197
GROUP BY
    TO_CHAR(periodo_efd_dt, 'YYYY/MM'),
    cod_aj,
    descr_compl_aj
ORDER BY
    periodo_efd, total_icms_c197 DESC;
