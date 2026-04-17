# Conversion Quality API v7

## Objetivo

A `runtime_quality.py` expõe uma visão focada em qualidade da conversão, separada da execução do pipeline.

## Endpoint principal

- `GET /api/v7/conversao/{cnpj}/quality`

## O que retorna

- resumo quantitativo da conversão
- preview de `item_unidades`
- preview de `fatores_conversao`
- preview de `log_conversao_anomalias`

## Uso recomendado

Usar esta API para:
- validar se a conversão estrutural está sendo aplicada;
- inspecionar proporção de fatores `estrutural`, `preco` e `manual`;
- revisar anomalias antes de analisar o estoque.
