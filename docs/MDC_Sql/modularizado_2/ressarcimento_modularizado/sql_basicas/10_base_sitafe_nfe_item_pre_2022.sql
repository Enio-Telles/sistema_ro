/*
===============================================================================
BASE COMPARTILHADA 10 - ITEM FISCAL SITAFE PRÉ-2022
-------------------------------------------------------------------------------
Objetivo
- Expor os campos mais usados de sitafe.sitafe_nfe_item para trilhas
  históricas anteriores à granularidade do Fronteira pós-2022.
===============================================================================
*/

SELECT
    i.it_nu_chave_acesso,
    i.it_nu_item,
    i.it_co_sefin,
    i.it_pc_icms,
    i.it_va_produto,
    i.it_va_frete,
    i.it_va_seguro,
    i.it_va_desconto,
    i.it_va_outro,
    i.it_va_ipi_item
FROM sitafe.sitafe_nfe_item i;
