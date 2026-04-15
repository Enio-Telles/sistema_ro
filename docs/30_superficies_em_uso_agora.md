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
