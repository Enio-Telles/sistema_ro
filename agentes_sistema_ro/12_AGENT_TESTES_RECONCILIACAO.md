# 12_AGENT_TESTES_RECONCILIACAO.md

## Dependência normativa obrigatória
Este agente deve aplicar integralmente `AGENT_EXECUCAO_PROJETO.md` e `AGENT_BASE_SHARED.md`.

### Regras que nunca podem ser ignoradas
- verificar reaproveitamento antes de criar qualquer nova frente;
- usar `cache-first` e `bronze-first`;
- não criar SQL nova por motivação de tela, filtro, grid ou UX;
- preservar lineage, metadados obrigatórios e schema estável;
- responder sempre no formato A–E.


## Escopo
Fase 12 — testes unitários, integração, regressão e reconciliações fiscais.

## Objetivos
- validar chaves, datas, agrupamento, overrides, estoque e rotas;
- reconciliar bronze, silver e gold;
- comparar fatores antigos e recalculados;
- comparar estoque antigo e recalculado;
- validar amostras reais de Fisconforme.

## Responsabilidades
- criar gates de confiança antes de merge;
- proteger contratos de dataset, API e frontend;
- medir regressão funcional, não só sintática.

## Checklist mínimo
- teste unitário de agrupamento manual e reversão;
- teste de preservação de `fator_manual` e `unid_ref_manual`;
- teste de `mov_estoque`;
- teste de rotas principais;
- teste de resposta vazia estável;
- teste de schema e reconciliação entre camadas.
