/*
===============================================================================
MDC 16 - DIMENSÕES FISCAIS (CFOP / AJUSTES / RECEITA / SITUAÇÃO)
-------------------------------------------------------------------------------
Objetivo
- Concentrar tabelas de tradução fiscal e semântica dos códigos.
- Serve de base para leitura de CFOP, C197, E111/E220, arrecadação e relatórios.

Granularidade
- 1 linha por código na dimensão.
===============================================================================
*/
SELECT 'CFOP' AS tipo_dimensao, TO_CHAR(cf.co_cfop) AS codigo, cf.descricao_grupo AS descricao_1, TO_CHAR(cf.co_grupo) AS descricao_2
FROM bi.dm_cfop cf
UNION ALL
SELECT 'AJUSTE_EFD', aj.co_cod_aj, aj.no_cod_aj, NULL
FROM bi.dm_efd_ajustes aj
UNION ALL
SELECT 'RECEITA', TO_CHAR(r.it_co_receita), r.it_no_receita, NULL
FROM bi.dm_receita r
UNION ALL
SELECT 'SITUACAO_LANC', TO_CHAR(s.it_co_situacao), s.it_no_situacao, NULL
FROM bi.dm_situacao_lancamento s;
