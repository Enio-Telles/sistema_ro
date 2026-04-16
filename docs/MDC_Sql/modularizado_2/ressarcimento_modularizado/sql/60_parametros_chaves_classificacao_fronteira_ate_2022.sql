/*
===============================================================================
MÓDULO 60 - PARÂMETROS, CHAVES-ALVO E CLASSIFICAÇÃO FISCAL PRÉ-2022
-------------------------------------------------------------------------------
Objetivo
- Substituir a lista hardcoded de chaves por uma camada parametrizável.
- Materializar a vigência da classificação fiscal do produto Sefin.

Observação tributária
- Esta etapa não apura ressarcimento por si só.
- Ela apenas prepara a prova documental e a matriz fiscal que sustentará a
  reconstrução do cálculo em cenário anterior à validação item a item do
  Fronteira pós-2022.
===============================================================================
*/

WITH chaves_alvo AS (
    /* Substitua por tabela de staging ou parâmetro externo. */
    SELECT chave_acesso
    FROM tabela_chaves_alvo
),
classificacao_vigente AS (
    SELECT
        a.it_co_sefin,
        TO_DATE(a.it_da_inicio, 'YYYYMMDD') AS dt_inicio_vig,
        CASE
            WHEN TRIM(a.it_da_final) IS NULL THEN DATE '2999-12-31'
            ELSE TO_DATE(a.it_da_final, 'YYYYMMDD')
        END AS dt_final_vig,
        a.it_pc_interna,
        a.it_in_st,
        a.it_pc_mva,
        a.it_in_mva_ajustado,
        a.it_in_convenio,
        a.it_in_isento_icms,
        a.it_in_reducao,
        a.it_pc_reducao,
        a.it_in_pgto_saida,
        a.it_in_combustivel,
        a.it_in_reducao_credito,
        a.it_in_pmpf
    FROM sitafe.sitafe_produto_sefin_aux a
)
SELECT
    c.chave_acesso,
    cv.*
FROM chaves_alvo c
CROSS JOIN classificacao_vigente cv
ORDER BY c.chave_acesso, cv.it_co_sefin, cv.dt_inicio_vig;
