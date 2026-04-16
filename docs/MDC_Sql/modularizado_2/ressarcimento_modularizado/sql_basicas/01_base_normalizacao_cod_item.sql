/*
===============================================================================
CONSULTA BÁSICA COMPARTILHADA 01
TEMPLATE DE NORMALIZAÇÃO DE CÓDIGO DO ITEM
-------------------------------------------------------------------------------
Objetivo:
- padronizar a chave de item usada nas duas abordagens;
- reduzir ruído de zeros à esquerda, pontos, espaços e hífens.

Atenção:
- normalização melhora rastreabilidade, mas NÃO substitui tabela de
  equivalência de itens quando houver mudança real de cadastro.
===============================================================================
*/
SELECT
    t.cod_item AS cod_item_original,
    REPLACE(REPLACE(REPLACE(LTRIM(t.cod_item, '0'), ' ', ''), '.', ''), '-', '') AS cod_item_normalizado
FROM (
    SELECT :cod_item AS cod_item FROM dual
) t;
