# Superfícies em Uso Agora

## Objetivo

Este documento substitui o uso disperso de versões e aliases em documentos operacionais.

## Use agora

### Gold / estoque / conversão

- Runtime por versão: `runtime_gold_v20.py`
- Alias operacional preferido: `runtime_gold_current_v2.py`
- Prefixos preferidos:
  - `/api/gold20`
  - `/api/current-v2`

### Fisconforme modular

- Runtime por versão: `runtime_gold_v25.py`
- Alias operacional preferido: `runtime_gold_current_v5.py`
- Prefixos preferidos:
  - `/api/gold25/fisconforme-v2`
  - `/api/current-v5/fisconforme-v2`

## Use apenas para transição

Estas superfícies ainda podem ser usadas para comparação técnica controlada, mas não devem ser tratadas como referência principal.

- `runtime_gold_v18`
- `runtime_gold_v19`
- `runtime_gold_v21`
- `runtime_gold_v22`
- `runtime_gold_v23`
- `runtime_gold_v24`

## Não divulgar como superfície principal

- `runtime_gold_v14`
- `runtime_gold_v15`
- `runtime_gold_v16`
- `runtime_gold_v17`
- `runtime_gold_current`
- rotas legadas de `fisconforme`

## Regra prática

Quando houver dúvida operacional:

1. usar `current-v2` para gold;
2. usar `current-v5/fisconforme-v2` para Fisconforme;
3. usar versões de transição apenas para comparação ou migração.

## Status resumido por CNPJ

Para orientação operacional rápida por contribuinte, usar:

- `GET /api/current-v2/status/{cnpj}`
- `GET /api/current-v5/status/{cnpj}`
- `GET /api/current-v2/pipeline/{cnpj}/status`
- `GET /api/gold20/pipeline/{cnpj}/status`

Esse resumo consolida:

- prontidão de referências obrigatórias;
- prontidão mínima para preparar silver;
- prontidão mínima para executar gold;
- prontidão de SEFIN;
- listas de pendências por etapa;
- próxima ação recomendada;
- aliases e prefixos oficiais de gold e Fisconforme.

Nos endpoints `pipeline/.../status`, o foco é a execução gold oficial:

- validação dos inputs do gold;
- origem operacional dos itens;
- contexto SEFIN usado pela execução;
- resumo da qualidade operacional da conversão antes do `run`.

## Interpretação rápida de `next_action`

- `validar_referencias`: faltam referências obrigatórias antes de avançar.
- `carregar_silver_base`: referências estão prontas, mas ainda faltam bases mínimas.
- `preparar_silver`: já existe carga mínima e o próximo passo é consolidar silver.
- `executar_gold`: silver mínima para gold já existe.
- `revisar_quality`: os principais artefatos gold já foram materializados.
