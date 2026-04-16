/*
===============================================================================
MÓDULO 66 - CÁLCULO REFEITO DO ST PRÉ-2022
-------------------------------------------------------------------------------
Objetivo
- Reproduzir a fórmula histórica de CALC_ST da query original.

Leitura crítica
- Este módulo é a camada mais pericial de toda a trilha pré-2022.
- O resultado deve ser tratado como cálculo reconstruído, não como valor
  jurídico automaticamente homologado.
===============================================================================
*/

WITH base_pre_2022 AS (
    SELECT * FROM base_documental_fronteira_ate_2022
)
SELECT
    b.*,
    CASE
        WHEN b.it_in_st = 'S' THEN
            CASE
                WHEN b.co_crt IN ('1', '4') THEN
                    ROUND(
                        ((((NVL(b.it_va_produto,0)+NVL(b.it_va_frete,0)+NVL(b.it_va_seguro,0)
                          -NVL(b.it_va_desconto,0)+NVL(b.it_va_outro,0)+NVL(b.it_va_ipi_item,0)
                          +NVL(b.rateio_frete_nf_item,0))
                          * (100 + NVL(b.it_pc_mva,0)) / 100
                          * NVL(b.it_pc_interna,0) / 100)
                        - NVL(b.cred_calc,0)) - NVL(b.rateio_icms_frete_nf_item,0), 2)
                ELSE
                    CASE
                        WHEN b.it_in_mva_ajustado = 'S' THEN
                            ROUND(
                                (((((NVL(b.it_va_produto,0)+NVL(b.it_va_frete,0)+NVL(b.it_va_seguro,0)
                                   -NVL(b.it_va_desconto,0)+NVL(b.it_va_outro,0)-NVL(b.icms_vicms,0))
                                   / NULLIF((1 - NVL(b.it_pc_interna,0) / 100), 0))
                                   + NVL(b.it_va_ipi_item,0)
                                   + NVL(b.rateio_frete_nf_item,0))
                                  * (100 + NVL(b.it_pc_mva,0)) / 100
                                  * NVL(b.it_pc_interna,0) / 100)
                                 - LEAST(NVL(b.icms_vicms,0), NVL(b.cred_calc,0))
                                 - NVL(b.rateio_icms_frete_nf_item,0), 2)
                        ELSE
                            ROUND(
                                ((((NVL(b.it_va_produto,0)+NVL(b.it_va_frete,0)+NVL(b.it_va_seguro,0)
                                  -NVL(b.it_va_desconto,0)+NVL(b.it_va_outro,0)+NVL(b.it_va_ipi_item,0)
                                  +NVL(b.rateio_frete_nf_item,0))
                                  * (100 + NVL(b.it_pc_mva,0)) / 100
                                  * NVL(b.it_pc_interna,0)) / 100)
                                  - LEAST(NVL(b.icms_vicms,0), NVL(b.cred_calc,0))
                                  - NVL(b.rateio_icms_frete_nf_item,0), 2)
                    END
            END
        ELSE NULL
    END AS calc_st_pre_2022,
    CASE
        WHEN b.it_in_st = 'N' THEN 'NAO_ST'
        WHEN b.co_crt IN ('1', '4') THEN 'BASE_SIMPLES_EMITENTE_SIMPLES'
        WHEN b.it_in_mva_ajustado = 'N' THEN 'BASE_SIMPLES_REGIME_NORMAL'
        ELSE 'BASE_DUPLA_REGIME_NORMAL'
    END AS metodo_calculo_pre_2022
FROM base_pre_2022 b
ORDER BY b.chave_acesso, b.prod_nitem;
