# Descomissionamento Progressivo

## Objetivo

Iniciar a retirada controlada de superfícies antigas sem quebrar compatibilidade imediata.

## Runtime operacional recomendada nesta fase

Usar preferencialmente:

- `backend/app/runtime_gold_current_v5.py`
- prefixo `/api/current-v5`

Essa runtime expõe ao mesmo tempo:

- recomendação oficial;
- catálogo de superfícies;
- mapa de depreciações;
- plano de descomissionamento.

## 1. Retirar primeiro do uso cotidiano

### Gold legado

- `runtime_gold_v14`
- `runtime_gold_v15`
- `runtime_gold_v16`
- `runtime_gold_v17`
- `runtime_gold_current`

### Substituição recomendada

- `runtime_gold_v20`
- `runtime_gold_current_v2`
- `runtime_gold_current_v5`

## 2. Rotas legadas de Fisconforme

### Evitar uso novo

- `/api/current-v5/fisconforme`
- `/api/gold25/fisconforme`

### Usar no lugar

- `/api/current-v5/fisconforme-v2`
- `/api/gold25/fisconforme-v2`

## 3. Superfícies de transição

Manter temporariamente apenas para comparações controladas:

- `runtime_gold_v18`
- `runtime_gold_v19`
- `runtime_gold_v21`
- `runtime_gold_v22`
- `runtime_gold_v23`
- `runtime_gold_v24`

## 4. Ordem recomendada de desligamento

1. parar de divulgar runtimes legadas em documentação operacional;
2. usar cabeçalhos de depreciação para rotas legadas;
3. revisar se ainda há consumidores reais das runtimes de transição;
4. remover primeiro as runtimes `v14` a `v17` e `runtime_gold_current`;
5. depois revisar as runtimes `v21` a `v24` quando o Fisconforme v2 estiver estabilizado.

## 5. Critério mínimo antes de remoção física

- existir rota substituta operacional;
- existir documentação de substituição;
- existir runtime oficial/alias recomendado cobrindo o caso de uso;
- não abrir novas features na superfície candidata à retirada.
