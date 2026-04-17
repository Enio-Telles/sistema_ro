# Mapa de Superfície — Oficial, Transição e Legado

## Objetivo

Reduzir paralelismo operacional no `sistema_ro`, deixando explícito o que deve ser tratado como:

- oficial;
- transição;
- legado.

## 1. Superfícies oficiais

### Gold / estoque / conversão

- Runtime oficial por versão: `runtime_gold_v20.py`
- Alias operacional: `runtime_gold_current_v2.py`
- Prefixos recomendados:
  - `/api/gold20`
  - `/api/current-v2`

### Fisconforme modular

- Runtime oficial por versão: `runtime_gold_v25.py`
- Alias operacional: `runtime_gold_current_v5.py`
- Prefixos recomendados:
  - `/api/gold25/fisconforme-v2`
  - `/api/current-v5/fisconforme-v2`

## 2. Superfícies de transição

Essas versões ainda podem ser usadas para comparação controlada e migração, mas não devem receber novas features principais.

### Gold

- `runtime_gold_v18`
- `runtime_gold_v19`

### Fisconforme

- `runtime_gold_v21`
- `runtime_gold_v22`
- `runtime_gold_v23`
- `runtime_gold_v24`

## 3. Superfícies legadas

Essas versões devem ser tratadas como históricas.

### Gold

- `runtime_gold_v14`
- `runtime_gold_v15`
- `runtime_gold_v16`
- `runtime_gold_v17`

### Aliases antigos

- `runtime_gold_current.py`

### Rotas legadas de Fisconforme

- `/api/current-v5/fisconforme`
- `/api/gold25/fisconforme`

## 4. Regra de evolução

### Não fazer

- não abrir novas features nas runtimes marcadas como legado;
- não promover rotas legadas de Fisconforme como referência principal;
- não criar novos aliases “current” sem necessidade real.

### Fazer

- concentrar novas evoluções de gold em `gold_v20/current-v2`;
- concentrar novas evoluções de Fisconforme em `gold_v25/current-v5` e `fisconforme-v2`;
- usar versões de transição apenas para validação comparativa e encerramento gradual.

## 5. Próxima limpeza recomendada

1. adicionar aviso explícito nas rotas legadas em documentação operacional;
2. mover o catálogo de superfícies para a runtime operacional em uso;
3. revisar quais runtimes de transição ainda precisam ser mantidas;
4. depois iniciar descomissionamento progressivo das rotas antigas.
