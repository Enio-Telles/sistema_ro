WITH PARAMETROS AS (
    SELECT
        :CNPJ AS cnpj_filtro,
        NVL(TO_DATE(:data_inicial, 'DD/MM/YYYY'), DATE '1900-01-01') AS dt_ini_filtro,
        NVL(TO_DATE(:data_final,   'DD/MM/YYYY'), TRUNC(SYSDATE))    AS dt_fim_filtro,
        NVL(TO_DATE(:data_limite_processamento, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_corte
    FROM dual
),

ARQUIVOS_PROCESSADOS AS (
    SELECT
        r.id            AS reg_0000_id,
        r.cod_fin       AS cod_fin_efd,
        r.dt_ini,
        r.dt_fin,
        r.cnpj,
        r.data_entrega,
        p.dt_ini_filtro,
        p.dt_fim_filtro,
        p.dt_corte,
        ROW_NUMBER() OVER (
            PARTITION BY r.cnpj, r.dt_ini
            ORDER BY r.data_entrega DESC, r.id DESC
        ) AS ordem,
        COUNT(*) OVER (
            PARTITION BY r.cnpj, r.dt_ini
        ) AS qtd_envios
    FROM sped.reg_0000 r
    JOIN PARAMETROS p
      ON r.cnpj = p.cnpj_filtro
    WHERE r.data_entrega <= p.dt_corte
),

TODOS_ARQUIVOS_VALIDOS AS (
    SELECT
        reg_0000_id,
        cod_fin_efd,
        dt_ini,
        dt_fin,
        cnpj,
        data_entrega,
        dt_ini_filtro,
        dt_fim_filtro,
        dt_corte,
        qtd_envios
    FROM ARQUIVOS_PROCESSADOS
    WHERE ordem = 1
),

ARQUIVOS_DO_PERIODO AS (
    SELECT *
    FROM TODOS_ARQUIVOS_VALIDOS
    WHERE dt_fin >= dt_ini_filtro
      AND dt_ini <= dt_fim_filtro
),

OUTROS_ARQUIVOS AS (
    SELECT *
    FROM TODOS_ARQUIVOS_VALIDOS
    WHERE NOT (
        dt_fin >= dt_ini_filtro
        AND dt_ini <= dt_fim_filtro
    )
),

C100_PERIODO AS (
    SELECT
        'PERIODO'                          AS origem_busca,
        arq.dt_ini                         AS periodo_efd_dt,
        arq.data_entrega,
        arq.cod_fin_efd,
        arq.qtd_envios,
        arq.dt_ini_filtro,
        arq.dt_fim_filtro,
        c100.reg_0000_id,
        c100.ind_oper,
        c100.ind_emit,
        c100.cod_part,
        c100.cod_mod,
        c100.cod_sit,
        c100.ser,
        c100.num_doc,
        c100.chv_nfe,
        CASE
            WHEN c100.dt_doc IS NOT NULL
             AND REGEXP_LIKE(TRIM(c100.dt_doc), '^\d{8}$')
            THEN TO_DATE(TRIM(c100.dt_doc), 'DDMMYYYY')
            ELSE NULL
        END AS dt_doc,
        CASE
            WHEN c100.dt_e_s IS NOT NULL
             AND REGEXP_LIKE(TRIM(c100.dt_e_s), '^\d{8}$')
            THEN TO_DATE(TRIM(c100.dt_e_s), 'DDMMYYYY')
            ELSE NULL
        END AS dt_e_s,
        c100.vl_doc,
        c100.ind_pgto,
        c100.vl_desc,
        c100.vl_abat_nt,
        c100.vl_merc,
        c100.ind_frt,
        c100.vl_frt,
        c100.vl_seg,
        c100.vl_out_da,
        c100.vl_bc_icms,
        c100.vl_icms,
        c100.vl_bc_icms_st,
        c100.vl_icms_st,
        c100.vl_ipi,
        c100.vl_pis,
        c100.vl_cofins,
        c100.vl_pis_st,
        c100.vl_cofins_st
    FROM sped.reg_c100 c100
    JOIN ARQUIVOS_DO_PERIODO arq
      ON arq.reg_0000_id = c100.reg_0000_id
),

C100_EXTEMPORANEA AS (
    SELECT
        'EXTEMPORANEA'                     AS origem_busca,
        arq.dt_ini                         AS periodo_efd_dt,
        arq.data_entrega,
        arq.cod_fin_efd,
        arq.qtd_envios,
        arq.dt_ini_filtro,
        arq.dt_fim_filtro,
        c100.reg_0000_id,
        c100.ind_oper,
        c100.ind_emit,
        c100.cod_part,
        c100.cod_mod,
        c100.cod_sit,
        c100.ser,
        c100.num_doc,
        c100.chv_nfe,
        CASE
            WHEN c100.dt_doc IS NOT NULL
             AND REGEXP_LIKE(TRIM(c100.dt_doc), '^\d{8}$')
            THEN TO_DATE(TRIM(c100.dt_doc), 'DDMMYYYY')
            ELSE NULL
        END AS dt_doc,
        CASE
            WHEN c100.dt_e_s IS NOT NULL
             AND REGEXP_LIKE(TRIM(c100.dt_e_s), '^\d{8}$')
            THEN TO_DATE(TRIM(c100.dt_e_s), 'DDMMYYYY')
            ELSE NULL
        END AS dt_e_s,
        c100.vl_doc,
        c100.ind_pgto,
        c100.vl_desc,
        c100.vl_abat_nt,
        c100.vl_merc,
        c100.ind_frt,
        c100.vl_frt,
        c100.vl_seg,
        c100.vl_out_da,
        c100.vl_bc_icms,
        c100.vl_icms,
        c100.vl_bc_icms_st,
        c100.vl_icms_st,
        c100.vl_ipi,
        c100.vl_pis,
        c100.vl_cofins,
        c100.vl_pis_st,
        c100.vl_cofins_st
    FROM sped.reg_c100 c100
    JOIN OUTROS_ARQUIVOS arq
      ON arq.reg_0000_id = c100.reg_0000_id
),

C100_BASE AS (
    SELECT
        b.*,
        CASE
            WHEN b.dt_doc IS NOT NULL AND b.dt_e_s IS NOT NULL THEN GREATEST(b.dt_doc, b.dt_e_s)
            ELSE COALESCE(b.dt_doc, b.dt_e_s)
        END AS dt_ref
    FROM (
        SELECT * FROM C100_PERIODO
        UNION ALL
        SELECT * FROM C100_EXTEMPORANEA
    ) b
)

SELECT
    origem_busca,
    TO_CHAR(periodo_efd_dt, 'YYYY/MM') AS periodo_efd,
    data_entrega                       AS data_entrega_efd_periodo,
    cod_fin_efd,
    qtd_envios,
    CASE ind_oper
        WHEN '0' THEN '0 - Entrada'
        WHEN '1' THEN '1 - Saída'
        ELSE ind_oper
    END AS ind_oper_desc,
    CASE ind_emit
        WHEN '0' THEN '0 - Emissão própria'
        WHEN '1' THEN '1 - Terceiros'
        ELSE ind_emit
    END AS ind_emit_desc,
    cod_part,
    cod_mod,
    cod_sit,
    CASE TRIM(cod_sit)
        WHEN '00' THEN '00 - Documento regular'
        WHEN '01' THEN '01 - Escrituração extemporânea de documento regular'
        WHEN '02' THEN '02 - Documento cancelado'
        WHEN '03' THEN '03 - Escrituração extemporânea de documento cancelado'
        WHEN '04' THEN '04 - NF-e, NFC-e ou CT-e - denegado'
        WHEN '05' THEN '05 - NF-e, NFC-e ou CT-e - Numeração inutilizada'
        WHEN '06' THEN '06 - Documento Fiscal Complementar'
        WHEN '07' THEN '07 - Escrituração extemporânea de documento complementar'
        WHEN '08' THEN '08 - Documento Fiscal emitido com base em Regime Especial ou Norma Específica'
        ELSE '99 - Código de situação não mapeado'
    END AS cod_sit_desc,
    ser,
    num_doc,
    chv_nfe,
    dt_doc,
    dt_e_s,
    dt_ref,
    vl_doc,
    CASE ind_pgto
        WHEN '0' THEN '0 - À vista'
        WHEN '1' THEN '1 - A prazo'
        WHEN '2' THEN '2 - Outros'
        WHEN '9' THEN '9 - Sem pagamento'
        ELSE ind_pgto
    END AS ind_pgto_desc,
    vl_desc,
    vl_abat_nt,
    vl_merc,
    CASE ind_frt
        WHEN '0' THEN '0 - Emitente'
        WHEN '1' THEN '1 - Destinatário'
        WHEN '2' THEN '2 - Terceiros'
        WHEN '9' THEN '9 - Sem frete'
        ELSE ind_frt
    END AS ind_frt_por_conta_de,
    vl_frt,
    vl_seg,
    vl_out_da,
    vl_bc_icms,
    vl_icms,
    vl_bc_icms_st,
    vl_icms_st,
    vl_ipi,
    vl_pis,
    vl_cofins,
    vl_pis_st,
    vl_cofins_st
FROM C100_BASE
WHERE origem_busca = 'PERIODO'
   OR (
        origem_busca = 'EXTEMPORANEA'
        AND dt_ref BETWEEN dt_ini_filtro AND dt_fim_filtro
   )
ORDER BY dt_ref, dt_doc, ser, num_doc;
