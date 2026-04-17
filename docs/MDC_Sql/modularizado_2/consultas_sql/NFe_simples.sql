WITH parametros AS (
    SELECT
        :CNPJ AS cnpj_filtro,
        TO_DATE(:data_inicial, 'DD/MM/YYYY') AS data_inicial_filtro,
        TO_DATE(:data_final, 'DD/MM/YYYY') AS data_final_filtro
    FROM DUAL
),
datas_calculadas AS (
    SELECT
        d.*,
        CASE
            WHEN d.dhsaient IS NOT NULL AND d.dhsaient > d.dhemi
            THEN d.dhsaient
            ELSE d.dhemi
        END AS data_efetiva
    FROM bi.fato_nfe_detalhe d
    INNER JOIN parametros p ON 1=1
    WHERE
        (d.co_destinatario = p.cnpj_filtro OR d.co_emitente = p.cnpj_filtro)

        AND d.dhemi BETWEEN p.data_inicial_filtro AND p.data_final_filtro
)
SELECT
*
FROM datas_calculadas dc
INNER JOIN parametros p ON 1=1
WHERE
    dc.data_efetiva BETWEEN p.data_inicial_filtro AND p.data_final_filtro

    -- AND dc.infprot_cstat IN (100, 150)
    -- AND dc.prod_cprod LIKE '%226052'
    -- AND dc.entrada_saida = 'E'  -- ou 'S'
