/* =========================================================================================
   NFe ENTRADAS + CO-SEFIN + PRODUTO SEFIN + VIGÊNCIA AUX
   Versão com normalização forte da AUX
   ========================================================================================= */

WITH
parametros AS (
    SELECT
        REGEXP_REPLACE(TRIM(:CNPJ), '[^0-9]', '') AS cnpj_filtro,
        NVL(TO_DATE(:DATA_INICIAL, 'DD/MM/YYYY'), DATE '2006-01-01') AS data_inicial,
        NVL(TO_DATE(:DATA_FINAL, 'DD/MM/YYYY') + 1 - (1 / 86400), TRUNC(SYSDATE) + 1 - (1 / 86400)) AS data_final
    FROM dual
),

/* 1º nível: NCM + CEST */
sitafe_cest_ncm_ref AS (
    SELECT
        it_nu_ncm,
        it_nu_cest,
        it_co_sefin,
        sp_nu_cest_ncm
    FROM (
        SELECT
            TRIM(it_nu_ncm)  AS it_nu_ncm,
            TRIM(it_nu_cest) AS it_nu_cest,
            it_co_sefin,
            sp_nu_cest_ncm,
            ROW_NUMBER() OVER (
                PARTITION BY TRIM(it_nu_ncm), TRIM(it_nu_cest)
                ORDER BY sp_nu_cest_ncm DESC NULLS LAST, it_co_sefin
            ) AS rn
        FROM sitafe.sitafe_cest_ncm
        WHERE it_in_status <> 'C'
    )
    WHERE rn = 1
),

/* 2º nível: CEST */
sitafe_cest_ref AS (
    SELECT
        it_nu_cest,
        it_co_sefin
    FROM (
        SELECT
            TRIM(it_nu_cest) AS it_nu_cest,
            it_co_sefin,
            ROW_NUMBER() OVER (
                PARTITION BY TRIM(it_nu_cest)
                ORDER BY it_co_sefin
            ) AS rn
        FROM sitafe.sitafe_cest
        WHERE it_in_status <> 'C'
    )
    WHERE rn = 1
),

/* 3º nível: NCM */
sitafe_ncm_ref AS (
    SELECT
        it_nu_ncm,
        it_co_sefin
    FROM (
        SELECT
            TRIM(a.it_nu_ncm) AS it_nu_ncm,
            b.it_nu_classificacao AS it_co_sefin,
            ROW_NUMBER() OVER (
                PARTITION BY TRIM(a.it_nu_ncm)
                ORDER BY b.it_nu_classificacao
            ) AS rn
        FROM sitafe.sitafe_ncm a
        LEFT JOIN sitafe.sitafe_ncm_gr_classif_produto b
               ON b.tuk = a.tuk
        WHERE a.it_in_status_ncm <> 'C'
    )
    WHERE rn = 1
),

/* Produto SEFIN */
sitafe_produto_sefin_ref AS (
    SELECT
        it_co_sefin,
        it_no_produto
    FROM (
        SELECT
            it_co_sefin,
            it_no_produto,
            ROW_NUMBER() OVER (
                PARTITION BY it_co_sefin
                ORDER BY it_no_produto
            ) AS rn
        FROM sitafe.sitafe_produto_sefin
    )
    WHERE rn = 1
),

/* AUX com normalização forte */
sitafe_produto_sefin_aux_ref AS (
    SELECT
        TRIM(TO_CHAR(it_co_sefin)) AS it_co_sefin_key,
        it_co_sefin,
        it_da_inicio,
        it_da_final,
        it_pc_interna,
        it_in_st,
        it_in_reducao,
        it_in_isento_icms,

        CASE
            WHEN REGEXP_LIKE(TRIM(TO_CHAR(it_da_inicio)), '^[0-9]{8}$')
            THEN TO_DATE(TRIM(TO_CHAR(it_da_inicio)), 'YYYYMMDD')
        END AS dt_inicio_vigencia,

        CASE
            WHEN it_da_final IS NULL THEN DATE '9999-12-31'
            WHEN REGEXP_LIKE(TRIM(TO_CHAR(it_da_final)), '^[0-9]{8}$')
            THEN TO_DATE(TRIM(TO_CHAR(it_da_final)), 'YYYYMMDD')
            ELSE DATE '9999-12-31'
        END AS dt_final_vigencia
    FROM sitafe.sitafe_produto_sefin_aux
),

/* Base somente entradas */
nfe_base AS (
    SELECT
        d.chave_acesso,
        d.prod_nitem,
        d.dhemi,
        d.dhsaient,
        d.co_emitente,
        d.xnome_emit,
        d.xfant_emit,
        d.co_destinatario,
        d.xnome_dest,
        d.ide_co_mod,
        d.ide_serie,
        d.nnf,
        d.infprot_cstat,
        d.versao,
        d.co_tp_nf,
        d.prod_xprod,
        d.prod_ncm,
        d.prod_cest,
        d.icms_vicms,
        d.icms_vbc,
        d.prod_vprod,
        d.prod_vfrete,
        d.prod_vseg,
        d.prod_voutro,
        d.prod_vdesc,
        d.tot_vnf,
        TRUNC(
            CASE
                WHEN d.dhsaient IS NOT NULL AND d.dhemi IS NOT NULL THEN GREATEST(d.dhsaient, d.dhemi)
                ELSE NVL(d.dhsaient, d.dhemi)
            END
        ) AS dt_referencia_sefin_aux
    FROM bi.fato_nfe_detalhe d
    CROSS JOIN parametros p
    WHERE
        (
            d.dhemi BETWEEN p.data_inicial AND p.data_final
            OR d.dhsaient BETWEEN p.data_inicial AND p.data_final
        )
        AND (
            (REGEXP_REPLACE(TRIM(d.co_emitente), '[^0-9]', '') = p.cnpj_filtro AND d.co_tp_nf = 0)
            OR
            (REGEXP_REPLACE(TRIM(d.co_destinatario), '[^0-9]', '') = p.cnpj_filtro AND d.co_tp_nf = 1)
        )
),

/* Resolve CO-SEFIN */
nfe_com_sefin AS (
    SELECT
        b.*,
        COALESCE(scn.it_co_sefin, sc.it_co_sefin, sn.it_co_sefin) AS it_co_sefin,
        CASE
            WHEN scn.it_co_sefin IS NOT NULL THEN '1 - CEST_NCM'
            WHEN sc.it_co_sefin  IS NOT NULL THEN '2 - CEST'
            WHEN sn.it_co_sefin  IS NOT NULL THEN '3 - NCM'
            ELSE '0 - NAO ENCONTRADO'
        END AS it_co_sefin_origem,
        scn.sp_nu_cest_ncm
    FROM nfe_base b
    LEFT JOIN sitafe_cest_ncm_ref scn
           ON scn.it_nu_ncm  = TRIM(b.prod_ncm)
          AND scn.it_nu_cest = TRIM(b.prod_cest)
    LEFT JOIN sitafe_cest_ref sc
           ON sc.it_nu_cest = TRIM(b.prod_cest)
    LEFT JOIN sitafe_ncm_ref sn
           ON sn.it_nu_ncm = TRIM(b.prod_ncm)
),

/* Enriquecimento final */
nfe_enriquecida AS (
    SELECT
        n.*,
        ps.it_no_produto,
        psa.it_da_inicio AS it_da_inicio_aux,
        psa.it_da_final  AS it_da_final_aux,
        psa.it_pc_interna,
        psa.it_in_st,
        psa.it_in_reducao,
        psa.it_in_isento_icms,
        ROW_NUMBER() OVER (
            PARTITION BY n.chave_acesso, n.prod_nitem
            ORDER BY psa.dt_inicio_vigencia DESC NULLS LAST,
                     psa.dt_final_vigencia  DESC NULLS LAST
        ) AS rn_aux
    FROM nfe_com_sefin n
    LEFT JOIN sitafe_produto_sefin_ref ps
           ON ps.it_co_sefin = n.it_co_sefin
    LEFT JOIN sitafe_produto_sefin_aux_ref psa
           ON psa.it_co_sefin_key = TRIM(TO_CHAR(n.it_co_sefin))
          AND psa.dt_inicio_vigencia IS NOT NULL
          AND n.dt_referencia_sefin_aux >= psa.dt_inicio_vigencia
          AND n.dt_referencia_sefin_aux <= psa.dt_final_vigencia
)

SELECT
    chave_acesso,
    dhemi,
    dhsaient,
    co_emitente,
    xnome_emit,
    xfant_emit,
    co_destinatario,
    xnome_dest,
    ide_co_mod,
    ide_serie,
    nnf,
    infprot_cstat,
    versao,
    prod_nitem,
    prod_xprod,
    prod_ncm AS prod_co_ncm,
    prod_cest,
    icms_vicms AS icms_vicm,
    icms_vbc,
    (
        NVL(prod_vprod,  0)
      + NVL(prod_vfrete, 0)
      + NVL(prod_vseg,   0)
      + NVL(prod_voutro, 0)
      - NVL(prod_vdesc,  0)
    ) AS preco_item,
    tot_vnf,
    it_co_sefin,
    it_co_sefin_origem,
    sp_nu_cest_ncm,
    it_no_produto,
    dt_referencia_sefin_aux,
    it_da_inicio_aux,
    it_da_final_aux,
    it_pc_interna,
    it_in_st,
    it_in_reducao,
    it_in_isento_icms
FROM nfe_enriquecida
WHERE rn_aux = 1
ORDER BY dhemi, chave_acesso, prod_nitem;