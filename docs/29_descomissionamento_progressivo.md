# Descomissionamento Progressivo

## Objetivo

Consolidar a retirada controlada de superfícies antigas sem quebrar compatibilidade imediata.

## Runtime operacional recomendada nesta fase

Usar preferencialmente:

- `backend/app/runtime_gold_current_v5.py`
- prefixo `/api/current-v5`

Essa runtime expõe ao mesmo tempo:

- recomendação oficial;
- catálogo de superfícies;
- mapa de depreciações;
- plano de descomissionamento.

## 1. Já retiradas do repositório e do uso cotidiano

### Gold legado removido fisicamente

- `runtime_gold_v14`
- `runtime_gold_v15`
- `runtime_gold_v16`
- `runtime_gold_v17`
- `runtime_gold_v18`
- `runtime_gold_v19`
- `runtime_gold_current`

### Fisconforme de transição já removido fisicamente

- `runtime_gold_v21`
- `runtime_gold_v22`
- `runtime_gold_v23`
- `runtime_gold_v24`
- `runtime_gold_current_v3`

### Substituição recomendada

- `runtime_gold_v20`
- `runtime_gold_current_v2`
- `runtime_gold_current_v5`
- `runtime_gold_v25`

## 2. Rotas legadas de Fisconforme

### Evitar uso novo

- `/api/current-v3/fisconforme`
- `/api/current-v3/fisconforme-v2`
- `/api/current-v5/fisconforme`
- `/api/gold25/fisconforme`

### Usar no lugar

- `/api/current-v5/fisconforme-v2`
- `/api/gold25/fisconforme-v2`

## 3. Superfícies de transição

Não restam runtimes ou aliases de transição em arquivo. Manter apenas documentação de migração quando estritamente necessário.

## 4. Ordem recomendada de desligamento

1. manter `v14` a `v19`, `v21` a `v24`, `runtime_gold_current` e `runtime_gold_current_v3` apenas como histórico técnico;
2. usar apenas as superfícies oficiais/aliases operacionais atuais;
3. não reabrir wrappers ou aliases de transição quando a runtime oficial já cobre integralmente o escopo.

## 5. Critério mínimo antes de remoção física

- existir rota substituta operacional;
- existir documentação de substituição;
- existir runtime oficial/alias recomendado cobrindo o caso de uso;
- não abrir novas features na superfície candidata à retirada.
