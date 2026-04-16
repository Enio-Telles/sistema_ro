/* ============================================================================
   105_resumo_status_pagamento_fronteira_completo.sql
   ----------------------------------------------------------------------------
   Objetivo:
   - consolidar a trilha Fronteira completa em visão resumida;
   - agrupar por receita e situação do lançamento/pagamento.

   Dependência lógica:
   - 104_resultado_final_fronteira_completo.sql
============================================================================ */

WITH base AS (
    SELECT * FROM resultado_final_fronteira_completo
)
SELECT
    receita,
    situacao_lancamento,
    status_pagamento,
    COUNT(*) AS qtd_itens,
    COUNT(DISTINCT chave_acesso) AS qtd_notas,
    SUM(NVL(valor_devido,0)) AS soma_valor_devido,
    SUM(NVL(valor_pago,0)) AS soma_valor_pago,
    SUM(NVL(saldo_aberto,0)) AS soma_saldo_aberto,
    SUM(NVL(vl_icms,0)) AS soma_vl_icms_item_lancado
FROM base
GROUP BY
    receita,
    situacao_lancamento,
    status_pagamento
ORDER BY
    receita,
    situacao_lancamento,
    status_pagamento;
