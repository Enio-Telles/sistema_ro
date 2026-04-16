/*
===============================================================================
CONSULTA BÁSICA 09 - PRODUTO SEFIN, NCM/CEST E VIGÊNCIA
-------------------------------------------------------------------------------
Objetivo
- Traduzir NCM/CEST em código Sefin e parâmetros fiscais vigentes.
===============================================================================
*/

WITH cesta_produto AS (
    SELECT c.it_co_sefin,
           c.it_nu_ncm,
           c.it_nu_cest,
           c.it_in_status,
           h.it_da_inicio,
           h.it_da_final,
           h.it_pc_interna,
           h.it_in_st,
           h.it_in_mva_ajustado,
           h.it_pc_mva
    FROM sitafe.sitafe_cest_ncm c
    JOIN sitafe.sitafe_produto_sefin_aux h ON h.it_co_sefin = c.it_co_sefin
    WHERE NVL(c.it_in_status, 'A') <> 'C'
)
SELECT *
FROM cesta_produto
WHERE it_nu_ncm = :ncm
  AND (:cest IS NULL OR it_nu_cest = :cest)
ORDER BY it_co_sefin, it_da_inicio;
