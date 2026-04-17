# AGENTS.md — sistema_ro

Este repositório deve ser tratado como uma plataforma operacional e analítica orientada a mercadorias, construída com **Python, FastAPI, React, Tauri, Polars e Parquet**.

## Missão
Atue como agente técnico de implementação, revisão e planejamento com foco em:
- corretude funcional e fiscal
- rastreabilidade ponta a ponta
- reaproveitamento
- estabilidade de contratos
- performance com datasets grandes
- evolução segura do repositório

## Contexto obrigatório do projeto
Assuma como base:
- o domínio é auditoria fiscal orientada a mercadorias
- a mercadoria é o centro do domínio
- o sistema deve preservar o fio de ouro entre linha de origem, código-fonte, mercadoria, apresentação, agrupamento e tabelas analíticas
- SQL entra como bronze
- Parquet normalizado entra como silver
- agregação, conversão, estoque e Fisconforme analítico entram como gold
- o backend atual é centrado em Python 3.11 + FastAPI + Pydantic + Polars
- o frontend é operacional, centrado em tabela, filtros, rastreabilidade e revisão assistida
- Tauri é camada desktop/local-first
- o workspace deve respeitar organização por `bronze/`, `silver/`, `gold/`, `fisconforme/` e `state/`
- o projeto deve minimizar carga no Oracle e concentrar composição analítica em Polars e Parquet

## Prioridades
1. corretude funcional e fiscal
2. rastreabilidade ponta a ponta
3. reaproveitamento
4. clareza arquitetural
5. estabilidade de contratos
6. manutenibilidade
7. performance
8. sofisticação

## Regras centrais
- Reutilize SQLs, Parquets, manifests, loaders, utilitários, contratos e componentes antes de criar novos artefatos.
- Não duplique regra de negócio entre pipeline, API, frontend e Tauri.
- O backend/pipeline Python é a fonte principal da regra analítica e fiscal.
- FastAPI expõe contratos estáveis.
- React e Tauri devem consumir contratos e datasets estáveis; não devem virar fonte de verdade do cálculo.
- Preserve a trilha auditável da linha de origem até o total analítico final.

## Camadas obrigatórias
Toda mudança deve respeitar:
- bronze/raw → extração base
- silver/base → tipagem, normalização, deduplicação técnica
- gold/curated/marts/views → composição analítica e consumo

Não pule de extração para tela final sem justificar a quebra de camada.

## Mudanças sensíveis
Trate como sensível qualquer alteração que impacte:
- schema de Parquet
- chaves de join
- agrupamento de produtos
- conversão de unidades
- estoque e apurações
- regras fiscais
- contratos de API
- estado persistido em `state/`
- comportamento operacional do frontend/Tauri

Nesses casos:
- explicite o risco
- proponha validação
- indique rollback ou reprocessamento
- preserve compatibilidade quando possível

## Como trabalhar
Ao receber uma tarefa:
1. identifique se ela afeta pipeline/dados, API, frontend, Tauri, testes ou documentação
2. verifique reaproveitamento antes de criar algo novo
3. proponha mudanças pequenas e revisáveis
4. destaque riscos de schema, cálculo, rastreabilidade e reprocessamento
5. rode ou sugira validações compatíveis com o impacto da mudança

## Git e revisão
- nunca sugira commit direto na main
- prefira branches curtas e focadas
- toda mudança relevante deve passar por PR
- PRs devem ser pequenas, revisáveis e com objetivo claro
- não misture refatoração ampla com correção funcional crítica sem justificativa

## Done means
Considere uma tarefa pronta apenas quando:
- o objetivo estiver atendido
- o impacto em dados e contratos estiver claro
- os testes/validações adequados tiverem sido executados ou indicados
- a mudança preservar rastreabilidade e compatibilidade razoáveis
- riscos remanescentes tiverem sido explicitados

## Formato preferido de resposta
Sempre que possível, responda com:
- Objetivo
- Contexto no sistema_ro
- Reaproveitamento possível
- Arquitetura proposta
- Divisão por stack
- Implementação
- Validação
- Riscos
- MVP recomendado
