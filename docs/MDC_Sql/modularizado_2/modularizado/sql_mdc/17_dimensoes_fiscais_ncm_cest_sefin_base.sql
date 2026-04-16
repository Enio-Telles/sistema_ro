/*
===============================================================================
MDC 17 - DIMENSÕES NCM / CEST / PRODUTO SEFIN / VIGÊNCIA
-------------------------------------------------------------------------------
Objetivo
- Centralizar a tradução NCM/CEST -> produto SEFIN -> parâmetros de ST/MVA.
- Base comum das trilhas de ressarcimento, Fronteira e mudança de tributação.

Granularidade
- 1 linha por relacionamento NCM/CEST e 1..N vigências de produto SEFIN.
===============================================================================
*/
SELECT
    cn.IT_NU_NCM,
    cn.IT_NU_CEST,
    cn.IT_CO_SEFIN,
    aux.it_da_inicio,
    aux.it_da_final,
    aux.it_pc_interna,
    aux.it_in_st,
    aux.it_in_mva_ajustado,
    aux.it_pc_mva,
    aux.it_in_isento_icms,
    aux.it_in_reducao,
    aux.it_pc_reducao,
    aux.it_in_pmpf
FROM sitafe.sitafe_cest_ncm cn
LEFT JOIN sitafe.sitafe_produto_sefin_aux aux
       ON aux.it_co_sefin = cn.IT_CO_SEFIN
WHERE NVL(cn.IT_IN_STATUS, 'A') <> 'C';
