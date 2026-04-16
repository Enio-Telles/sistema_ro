-- efd_reg_0000.sql
-- grupo: core
-- dominio: EFD reg 0000
-- objetivo: abertura do arquivo EFD e período
-- parametros esperados: cnpj, periodo_inicio, periodo_fim
-- observacao: controla recorte do contribuinte
-- status: template curado para implementação no novo projeto
-- regra: selecionar apenas colunas necessárias e preservar chaves físicas

/* :cnpj :periodo_inicio :periodo_fim */
WITH parametros AS (
    SELECT
        REGEXP_REPLACE(TRIM(:cnpj), '[^0-9]', '') AS cnpj_cpf,
        NVL(TO_DATE(:periodo_inicio, 'YYYY-MM-DD'), DATE '1900-01-01') AS data_inicial,
        NVL(TO_DATE(:periodo_fim,   'YYYY-MM-DD'), TRUNC(SYSDATE))    AS data_final,
        TRUNC(SYSDATE) AS data_corte
    FROM dual
)
SELECT *
FROM (
    SELECT
        r.id AS reg_0000_id,
        r.cnpj,
        r.dt_ini,
        r.dt_fin,
        r.cod_fin,
        r.ie,
        r.im,
        r.nome,
        r.uf,
        r.data_entrega,
        ROW_NUMBER() OVER (
            PARTITION BY r.cnpj, r.dt_ini, NVL(r.dt_fin, r.dt_ini)
            ORDER BY r.data_entrega DESC, r.id DESC
        ) AS rn
    FROM sped.reg_0000 r
    JOIN parametros p
      ON r.cnpj = p.cnpj_cpf
    WHERE r.data_entrega <= p.data_corte
      AND r.dt_ini BETWEEN p.data_inicial AND p.data_final
)
WHERE rn = 1
ORDER BY dt_ini DESC, data_entrega DESC;
