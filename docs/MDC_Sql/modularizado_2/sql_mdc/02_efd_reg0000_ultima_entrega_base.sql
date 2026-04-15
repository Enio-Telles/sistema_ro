/*
===============================================================================
MDC 02 - EFD REG_0000 / ÚLTIMA ENTREGA VÁLIDA
-------------------------------------------------------------------------------
Objetivo
- Resolver a versão válida da EFD por competência.
- Reproduzir a lógica central usada nas trilhas de ressarcimento, inventário,
  auditoria EFD x documentos e relatórios EFD Master.

Granularidade
- 1 linha por competência válida do contribuinte.
===============================================================================
*/
WITH parametros AS (
    SELECT
        REGEXP_REPLACE(TRIM(:CNPJ_CPF), '[^0-9]', '') AS cnpj_cpf,
        NVL(TO_DATE(:DATA_INICIAL, 'DD/MM/YYYY'), DATE '1900-01-01') AS data_inicial,
        NVL(TO_DATE(:DATA_FINAL,   'DD/MM/YYYY'), TRUNC(SYSDATE))    AS data_final,
        NVL(TO_DATE(:DATA_LIMITE_PROCESSAMENTO, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS data_corte
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
