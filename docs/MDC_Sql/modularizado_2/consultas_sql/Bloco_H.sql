WITH PARAMETROS AS (
    SELECT 
        :CNPJ                                     AS cnpj_filtro,
        TO_DATE(:data_inicial, 'DD/MM/YYYY')      AS dt_ini_filtro,
        ADD_MONTHS(TO_DATE(:data_final, 'DD/MM/YYYY'), 2) AS dt_fim_filtro,
        NULLIF(:cod_item, '')                     AS cod_filtro, 
        NVL(TO_DATE(:data_limite_processamento, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_corte,
        TO_DATE(NULLIF(:data_inventario, ''), 'DD/MM/YYYY') AS dt_inv_especifica
    FROM dual
),

ARQUIVOS_RANKING AS (
    SELECT
        r.id AS reg_0000_id,
        r.cnpj,
        r.cod_fin AS cod_fin_efd,
        r.dt_ini,
        r.data_entrega,
        p.cod_filtro,
        p.dt_inv_especifica,
        ROW_NUMBER() OVER (
            PARTITION BY r.cnpj, r.dt_ini 
            ORDER BY r.data_entrega DESC
        ) AS rn
    FROM sped.reg_0000 r
    JOIN PARAMETROS p ON r.cnpj = p.cnpj_filtro
    WHERE 
        r.data_entrega <= p.dt_corte
        AND r.dt_ini BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro
),

estoque AS (
    SELECT 
        -- [INICIO DA ALTERAÇÃO] Campos H020
        h020.reg        AS REG_H020,
        h020.bc_icms    AS BC_ICMS_H020,
        h020.cst_icms   AS CST_ICMS_H020,
        h020.vl_icms    AS VL_ICMS_H020,
        -- [FIM DA ALTERAÇÃO]
        h005.dt_inv AS dt_inv_texto,
        TO_DATE(h005.dt_inv, 'DDMMYYYY') AS dt_inv,
        h005.mot_inv,
        CASE h005.mot_inv
            WHEN '01' THEN 'No final do periodo'
            WHEN '02' THEN 'Mudanca de tributacao (ICMS)'
            WHEN '03' THEN 'Baixa cadastral/paralisacao temporaria'
            WHEN '04' THEN 'Alteracao de regime de pagamento'
            WHEN '05' THEN 'Por determinacao dos fiscos'
            WHEN '06' THEN 'Controle ST - restituicao/ressarcimento'
            ELSE 'Nao informado'
        END AS mot_inv_desc,
        REPLACE(REPLACE(REPLACE(LTRIM(h010.cod_item, '0'), ' ', ''), '.', ''), '-', '') AS cod,
        h010.cod_item AS cod_original,
        r0200.descr_item,
        h010.txt_compl AS descricao_compl,
        h010.unid,
        h010.vl_unit, 
        h010.vl_item,
        h010.qtd AS qtde,
        TO_CHAR(arq.dt_ini, 'MM/YYYY') AS periodo_arquivo_sped,
        arq.cod_fin_efd,
        arq.data_entrega AS Data_entrega_efd_periodo
    FROM sped.reg_h010 h010
    INNER JOIN ARQUIVOS_RANKING arq ON h010.reg_0000_id = arq.reg_0000_id
    INNER JOIN sped.reg_0200 r0200 ON h010.cod_item = r0200.cod_item 
                                   AND h010.reg_0000_id = r0200.reg_0000_id
    LEFT JOIN sped.reg_h005 h005 ON h005.reg_0000_id = h010.reg_0000_id
    -- [INICIO DA ALTERAÇÃO] Join com H020
    LEFT JOIN sped.reg_h020 h020 ON h020.reg_h010_id = h010.id 
                                 AND h020.reg_0000_id = h010.reg_0000_id
    -- [FIM DA ALTERAÇÃO]
    WHERE 
        arq.rn = 1 
        AND (
            arq.cod_filtro IS NULL 
            OR REPLACE(REPLACE(REPLACE(LTRIM(h010.cod_item, '0'), ' ', ''), '.', ''), '-', '') = arq.cod_filtro
        )
        AND (
            arq.dt_inv_especifica IS NULL 
            OR TO_DATE(h005.dt_inv, 'DDMMYYYY') = arq.dt_inv_especifica
        )
),

estoque_rept_cod AS (
    SELECT 
        cod,                             
        COUNT(*) AS rept_cod,
        COUNT(DISTINCT unid) AS qtd_unid_distintas,
        LISTAGG(unid, ', ') WITHIN GROUP (ORDER BY unid) AS unidades_distintas
    FROM (
        SELECT DISTINCT cod, unid FROM estoque
    )
    GROUP BY cod
),

estoque_ajustado AS (
    SELECT

        e.dt_inv,
        e.mot_inv,
        e.mot_inv_desc,
        e.cod,
        e.cod_original,
        rc.rept_cod,
        e.descr_item,
        e.descricao_compl,
        e.unid,
        CASE WHEN rc.qtd_unid_distintas > 1 THEN rc.unidades_distintas ELSE NULL END AS unidades_distintas,
        e.vl_unit,
        e.vl_item,
        e.qtde,
                        e.REG_H020,
        e.BC_ICMS_H020,
        e.CST_ICMS_H020,
        e.VL_ICMS_H020,
        e.periodo_arquivo_sped,
        e.cod_fin_efd,
        e.Data_entrega_efd_periodo

        
    FROM estoque e
    JOIN estoque_rept_cod rc ON rc.cod = e.cod
    ORDER BY e.dt_inv DESC, e.cod
)
SELECT * FROM estoque_ajustado