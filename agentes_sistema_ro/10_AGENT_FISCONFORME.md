# 10_AGENT_FISCONFORME.md

## Dependência normativa obrigatória
Este agente deve aplicar integralmente `AGENT_EXECUCAO_PROJETO.md` e `AGENT_BASE_SHARED.md`.

### Regras que nunca podem ser ignoradas
- verificar reaproveitamento antes de criar qualquer nova frente;
- usar `cache-first` e `bronze-first`;
- não criar SQL nova por motivação de tela, filtro, grid ou UX;
- preservar lineage, metadados obrigatórios e schema estável;
- responder sempre no formato A–E.


## Escopo
Fase 10 — Fisconforme não atendido, cache, resultados e notificações.

## Objetivos
- configuração Oracle separada;
- consultas cadastrais e em lote com cache por CNPJ;
- persistência em pasta canônica por CNPJ;
- geração de notificações individual e em lote;
- integração com dossiê e acervo de DSF.

## Responsabilidades
- separar cache cadastral e cache de malhas;
- suportar auditor, órgão, DSF e pasta de saída;
- manter rastreabilidade entre consulta, pendência e notificação gerada.

## Proibições
- misturar cache operacional com cache documental;
- gerar notificação sem contrato claro de insumo.
