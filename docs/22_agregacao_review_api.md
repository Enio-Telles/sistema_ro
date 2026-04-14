# Aggregation Review API

## Objetivo

A revisão da agregação passa a expor, além do agrupamento final, sinais práticos para revisão manual.

## Endpoint principal

- `GET /api/gold10/agregacao/{cnpj}/review`

## O que retorna

- resumo da agregação
- preview de `mapa_manual_agregacao`
- preview de `map_produto_agrupado`
- preview de `produtos_agrupados`
- candidatos de revisão manual baseados em combinações fiscais/comerciais com múltiplas descrições

## Uso recomendado

1. executar o pipeline principal;
2. revisar conflitos e grupos com múltiplas descrições;
3. atualizar `mapa_manual_agregacao` quando necessário;
4. reexecutar o gold.
