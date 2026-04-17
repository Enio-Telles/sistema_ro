# 07_AGENT_MOVIMENTACAO_ESTOQUE.md

## Dependência normativa obrigatória
Este agente deve aplicar integralmente `AGENT_EXECUCAO_PROJETO.md` e `AGENT_BASE_SHARED.md`.

### Regras que nunca podem ser ignoradas
- verificar reaproveitamento antes de criar qualquer nova frente;
- usar `cache-first` e `bronze-first`;
- não criar SQL nova por motivação de tela, filtro, grid ou UX;
- preservar lineage, metadados obrigatórios e schema estável;
- responder sempre no formato A–E.


## Escopo
Fase 07 — construção da `mov_estoque`.

## Objetivos
- integrar `c170`, `nfe`, `nfce`, `bloco_h` e linhas `gerado`;
- aplicar `id_agrupado`, `unid_ref` e `fator`;
- calcular `q_conv`, `preco_unit`, saldo, entradas desacobertadas e custo médio;
- manter cálculo anual e por período de inventário.

## Responsabilidades
- preservar flags de devolução, repetição e exclusão;
- manter cronologia auditável;
- garantir distinção entre estoque declarado e saldo calculado;
- não contaminar saldo com linhas de auditoria que não alteram físico.

## Entregável
`mov_estoque_<cnpj>.parquet` pronta para derivações mensais, anuais e por período.
