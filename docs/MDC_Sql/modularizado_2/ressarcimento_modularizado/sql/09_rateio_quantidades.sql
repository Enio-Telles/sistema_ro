/*
===============================================================================
MÓDULO 09 - RATEIO DE QUANTIDADES
-------------------------------------------------------------------------------
Objetivo
- Determinar a quantidade da entrada efetivamente considerada para a saída.

Granularidade
- 1 linha por item de saída vinculado a um item de entrada.

Regra usada pela query original
- Consumo das entradas da mais antiga para a mais nova.

Observação crítica
- Há material no acervo que sugere atenção à literalidade da IN 22/2018 quanto às
  "entradas mais recentes". Por isso, este módulo merece parametrização futura do
  critério de consumo.
===============================================================================
*/

WITH base_enriquecida AS (
    SELECT * FROM base_vinculos_e_inferencia_sefin
),
base_rateio AS (
    SELECT
        b.*,
        SUM(NVL(b.qcom_entrada, 0)) OVER (
            PARTITION BY b.chave_saida, b.num_item_saida, b.cod_item
            ORDER BY
                CASE WHEN b.dt_ultima_entrada IS NULL THEN 1 ELSE 0 END,
                b.dt_ultima_entrada,
                b.chave_nfe_ultima_entrada,
                NVL(b.num_item_ult_entr, 0)
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS soma_qcom_entrada_acum,
        SUM(NVL(b.qcom_entrada, 0)) OVER (
            PARTITION BY b.chave_saida, b.num_item_saida, b.cod_item
        ) AS soma_qcom_entrada_total
    FROM base_enriquecida b
),
base_qtd AS (
    SELECT
        r.*,
        CASE
            WHEN NVL(r.qcom_saida, 0) <= 0 THEN 0
            WHEN NVL(r.qcom_entrada, 0) <= 0 THEN 0
            WHEN r.soma_qcom_entrada_acum <= r.qcom_saida THEN r.qcom_entrada
            WHEN r.soma_qcom_entrada_acum - NVL(r.qcom_entrada, 0) >= r.qcom_saida THEN 0
            ELSE r.qcom_saida - (r.soma_qcom_entrada_acum - NVL(r.qcom_entrada, 0))
        END AS qtd_considerada
    FROM base_rateio r
)
SELECT *
FROM base_qtd;
