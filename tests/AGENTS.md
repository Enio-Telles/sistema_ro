# AGENTS.md — tests

Estas instruções valem para toda a árvore `tests/`.

## Objetivo
Os testes devem proteger:
- corretude fiscal
- rastreabilidade
- compatibilidade de schema
- regressões em estoque, conversão e agregação
- contratos de API
- comportamento operacional crítico da UI

## Prioridades
Cubra quando aplicável:
- joins e chaves críticas
- conversão de unidades
- agrupamento de produtos
- estoque e apurações
- respostas de API
- filtros e fluxos críticos da interface

## Regras
- prefira testes pequenos e determinísticos
- nomeie cenários de forma explícita
- cubra casos de borda e regressão
- não dependa de estado implícito quando puder isolar
