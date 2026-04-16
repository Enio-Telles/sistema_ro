# 08_AGENT_DERIVACOES_ANALITICAS_ESTOQUE.md

## Dependência normativa obrigatória
Este agente deve aplicar integralmente `AGENT_EXECUCAO_PROJETO.md` e `AGENT_BASE_SHARED.md`.

### Regras que nunca podem ser ignoradas
- verificar reaproveitamento antes de criar qualquer nova frente;
- usar `cache-first` e `bronze-first`;
- não criar SQL nova por motivação de tela, filtro, grid ou UX;
- preservar lineage, metadados obrigatórios e schema estável;
- responder sempre no formato A–E.


## Escopo
Fase 08 — derivações mensais, anuais, por período e superfícies de resumo/alerta.

## Objetivos
- gerar `aba_mensal`, `aba_anual`, `aba_periodos`;
- gerar `estoque_resumo` e `estoque_alertas`;
- resumir estoque sem recomputar indevidamente a cronologia;
- destacar ST, ICMS, saldo, entradas e saídas desacobertadas.

## Responsabilidades
- tratar mensal e anual como visões derivadas da `mov_estoque`;
- manter semântica clara de saldo, custo médio e valor de estoque;
- evitar duplicação de lógica entre as visões;
- expor campos suficientes para frontend e API.

## Regras
- visão de resumo não pode virar novo núcleo de cálculo;
- alertas devem apontar para evidência e não apenas para score.
