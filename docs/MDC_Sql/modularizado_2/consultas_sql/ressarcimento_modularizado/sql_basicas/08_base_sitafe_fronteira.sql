/*
===============================================================================
CONSULTA BÁSICA 08 - BASE DE FRONTEIRA / SITAFE POR ITEM
-------------------------------------------------------------------------------
Objetivo
- Trazer o cálculo item a item do Fronteira/SITAFE.
===============================================================================
*/

SELECT it_nu_chave_acesso,
       it_nu_item,
       it_co_rotina_calculo,
       it_co_sefin,
       it_vl_icms
FROM sitafe.sitafe_nfe_calculo_item
WHERE it_nu_chave_acesso = :chave_acesso
ORDER BY it_nu_chave_acesso, it_nu_item;
