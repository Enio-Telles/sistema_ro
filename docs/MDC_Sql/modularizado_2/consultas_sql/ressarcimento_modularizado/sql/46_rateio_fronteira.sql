/*
===============================================================================
MÓDULO 46 - RATEIO FINAL DE QUANTIDADE
-------------------------------------------------------------------------------
Objetivo
- Aplicar o limite de quantidade da saída sobre cada entrada disponível.
- Produzir a quantidade efetivamente utilizável para a apuração do ressarcimento.
===============================================================================
*/

WITH base_fifo AS (
    SELECT * FROM memoria_fifo_peps_fronteira
)
SELECT
    bf.*,
    GREATEST(0, LEAST(bf.xml_qtd_comercial_entrada, bf.qtd_saida - bf.qtd_entrada_acumulada_anterior)) AS qtd_entrada_utilizada
FROM base_fifo bf
ORDER BY bf.dt_ini, bf.dt_emissao_saida, bf.num_item_saida, bf.xml_dhemi_entrada;
