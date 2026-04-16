/*
===============================================================================
CONSULTA BÁSICA COMPARTILHADA 06
BASE MÍNIMA DE AJUSTES DO BLOCO E
-------------------------------------------------------------------------------
Objetivo:
- disponibilizar uma camada única de reconciliação do Bloco E;
- servir ao ressarcimento (E111 / E210 / E220) e à mudança de tributação.

Observação:
- os nomes das tabelas podem variar conforme o banco efetivamente espelhe os
  registros analíticos da EFD. Ajuste para o seu ambiente.
===============================================================================
*/
SELECT
    e111.reg_0000_id,
    e111.cod_aj_apur,
    e111.descr_compl_aj,
    e111.vl_aj_apur,
    'E111' AS origem_bloco_e
FROM sped.reg_e111 e111
UNION ALL
SELECT
    e220.reg_0000_id,
    e220.cod_aj_apur,
    e220.descr_compl_aj,
    e220.vl_aj_apur,
    'E220' AS origem_bloco_e
FROM sped.reg_e220 e220;
