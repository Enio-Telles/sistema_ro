WITH PARAMETROS AS (
    SELECT
        -- Parâmetro para o CPF
        :cpf_distribuido AS cpf_filtro,

        -- Parâmetro para a data (com fallback seguro caso seja nulo)
        NVL(TO_DATE(:data_filtro, 'DD/MM/YYYY'), TO_DATE('01/03/2026', 'DD/MM/YYYY')) AS dt_filtro
    FROM dual
),

BASE AS (
    SELECT DISTINCT
        b.co_cnpj_cpf AS CNPJ_CPF,
        p.NO_RAZAO_SOCIAL,
        b.usuario,
        TO_CHAR(b.data, 'DD/MM/YYYY HH24:MI:SS') AS data_completa,

        -- TRUNC remove a componente de horas (substitui a conversão dupla TO_DATE/TO_CHAR)
        TRUNC(b.data) AS data,

        b.tipo,
        b.cpf_distribuido,
        b.dsf,
        b.status,
        b.cancelado,
        b.ultimo
    FROM sismonitora.apex_a110_p202_distribuicao b
    JOIN (
        SELECT CO_CNPJ_CPF, NO_RAZAO_SOCIAL
        FROM BI.DM_PESSOA
    ) p ON p.CO_CNPJ_CPF = b.CO_CNPJ_CPF
)

SELECT DISTINCT
    b.CNPJ_CPF,
    b.NO_RAZAO_SOCIAL,
    b.TIPO,
    b.CPF_DISTRIBUIDO,
    b.DSF,
    b.STATUS,
    b.CANCELADO,
    b.ULTIMO
FROM BASE b
-- Join com os parâmetros para aplicar os filtros de CPF e Data
JOIN PARAMETROS p ON b.cpf_distribuido = p.cpf_filtro
WHERE
    b.ULTIMO = 'S'
    AND b.data > p.dt_filtro;
