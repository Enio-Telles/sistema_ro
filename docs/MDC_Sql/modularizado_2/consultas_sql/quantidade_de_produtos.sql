WITH PARAMETROS AS (
    SELECT
        :CNPJ AS cnpj_filtro,
        TO_DATE(:data_inicial, 'DD/MM/YYYY') AS dt_ini_filtro,
        TO_DATE(:data_final,   'DD/MM/YYYY') AS dt_fim_filtro,
        NVL(TO_DATE(:data_limite_processamento, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_corte,
        :codigo_item AS cod_item_filtro
    FROM dual
),

ARQUIVOS_RANKING AS (
    SELECT
        r.id as reg_0000_id,
        r.cnpj,
        r.dt_ini,
        r.data_entrega,
        p.dt_corte,
        p.cod_item_filtro,
        ROW_NUMBER() OVER (
            PARTITION BY r.cnpj, r.dt_ini
            ORDER BY r.data_entrega DESC
        ) AS rn
    FROM sped.reg_0000 r
    JOIN PARAMETROS p ON r.cnpj = p.cnpj_filtro
    WHERE
        r.data_entrega <= p.dt_corte
        AND r.dt_ini BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro
)

SELECT COUNT(*) AS qtd_total_combinacoes
FROM (
    SELECT DISTINCT
        c170.cod_item,
        r0200.descr_item,
        c170.descr_compl
    FROM sped.reg_c170 c170
    INNER JOIN ARQUIVOS_RANKING arq
        ON arq.reg_0000_id = c170.reg_0000_id

    INNER JOIN sped.reg_c100 c100
        ON c100.id = c170.reg_c100_id

    LEFT JOIN sped.reg_0200 r0200
        ON r0200.reg_0000_id = c170.reg_0000_id
        AND r0200.cod_item = c170.cod_item

    WHERE arq.rn = 1
      /* FILTRO DINÂMICO DE COD */
      AND (
            arq.cod_item_filtro IS NULL
            OR replace(replace(replace(LTRIM(c170.cod_item, '0'), ' ',''), '.', ''),'-','') = arq.cod_item_filtro
          )
);
