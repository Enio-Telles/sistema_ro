/*
===============================================================================
BASE COMPARTILHADA 11 - RATEIO DE FRETE VIA CTE
-------------------------------------------------------------------------------
Objetivo
- Fornecer um template único para localizar CTe vinculados à NF-e e repartir
  frete/ICMS-frete entre notas e itens.
===============================================================================
*/

SELECT
    cte_itens.it_nu_chave_cte,
    cte_itens.it_nu_chave_nfe,
    cte.it_tp_frete,
    cte.it_va_total_frete,
    cte.it_va_valor_icms,
    cte_itens.it_nu_doc,
    cte_itens.it_inf_tipo
FROM sitafe.sitafe_cte_itens cte_itens
LEFT JOIN sitafe.sitafe_cte cte
  ON cte.it_nu_chave_acesso = cte_itens.it_nu_chave_cte;
