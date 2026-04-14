# Inventory Quality API v6b

## Objetivo

A `runtime_exec_v4.py` passa a expor uma visão de qualidade do estoque junto da execução validada baseada no `gold_v3`.

## Endpoints relevantes

- `POST /api/v6b/pipeline/{cnpj}/run`
- `GET /api/v6b/estoque/{cnpj}/quality`

## O que a qualidade do estoque retorna

- resumo dos movimentos
- quantidade de linhas de `0 - ESTOQUE INICIAL`
- quantidade de linhas de `3 - ESTOQUE FINAL`
- quantidade de linhas com `periodo_inventario`
- soma de divergência entre estoque declarado e calculado
- preview de `mov_estoque`, `aba_anual` e `estoque_alertas`

## Uso recomendado

1. preparar a silver-base;
2. executar o gold validado pela v6b;
3. consultar a qualidade do estoque antes da análise detalhada.
