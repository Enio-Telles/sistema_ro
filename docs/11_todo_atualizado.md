# Todo list atualizada — estado real de implementação

## Diagnóstico geral

O repositório já cobre boa parte das fases 01 a 10 em nível estrutural e parte relevante das fases 11 a 13 em nível técnico.
O maior avanço recente foi a separação operacional entre:
- preparação da silver-base;
- execução validada do gold;
- preview por API dos datasets materializados.

Ainda existe uma lacuna importante:
- a execução validada principal ainda não usa como padrão a conversão v2 priorizada (`estrutural -> preço -> manual`) nem persiste o `log_conversao_anomalias`.

---

## Status por fase

### Fase 01 — Fundação do projeto
**Status:** concluída
- estrutura-base criada
- `pyproject.toml`, `.env.example`, `.gitignore`
- organização `backend/`, `pipeline/`, `sql/`, `references/`, `docs/`
- manifesto de dados e organização por camadas definidos
- convenções de datasets por CNPJ definidas

### Fase 02 — Extração bronze
**Status:** parcial
- catálogo SQL criado
- runner SQL criado
- job de extração bronze criado
- templates SQL core iniciais criados
- falta cliente Oracle concreto e rotina completa de extração por domínio

### Fase 03 — Normalização silver
**Status:** parcial forte
- normalização de chaves criada
- normalização de EFD, NFe/NFCe, Bloco H e Fisconforme criada
- `itens_unificados` criado
- `base_info_mercadorias` criado
- falta ampliar cobertura de mais registros e persistência sistemática da silver completa

### Fase 04 — Núcleo de mercadorias
**Status:** parcial forte
- identidade inicial criada
- builders de `produtos_agrupados`, `id_agrupados` e `produtos_final` criados
- pipeline de mercadorias criada
- falta score mais rico de agrupamento e revisão manual real

### Fase 05 — Conversão de unidades
**Status:** parcial forte
- `item_unidades` criado
- fator por preço criado
- override manual criado
- conversão v2 estrutural criada
- log de anomalias criado
- falta tornar a conversão v2 padrão da execução validada e persistir o log

### Fase 06 — Enriquecimento fiscal e SEFIN
**Status:** parcial
- loaders de referências criados
- inferência inicial de `co_sefin` criada
- vigência SEFIN criada
- falta integração sistemática da vigência na execução principal

### Fase 07 — Movimentação de estoque
**Status:** parcial forte
- `mov_estoque` criada
- cálculo inicial de `q_conv`, saldo e custo médio criado
- falta aderência mais completa a inventário, neutralizações e regras finas do domínio

### Fase 08 — Derivações analíticas de estoque
**Status:** parcial forte
- `aba_mensal`, `aba_anual`, `aba_periodos` criadas
- `estoque_resumo` e `estoque_alertas` criados
- falta integrar melhor `periodo_inventario` e regras mais fiéis dos documentos

### Fase 09 — Backend API
**Status:** parcial forte
- app v1 scaffold existe
- app v2 preview existe
- app v3/v4/v5 execução/preparação existem
- falta convergir versões e reduzir duplicação entre runtimes

### Fase 10 — Fisconforme não atendido
**Status:** parcial
- cache local criado
- normalização criada
- serviço de leitura criado
- endpoint de leitura criado
- falta consulta real ao banco, lote e geração de notificações

### Fase 11 — Frontend operacional
**Status:** inicial
- documentação do frontend criada
- falta implementação real do frontend

### Fase 12 — Testes e reconciliação
**Status:** parcial
- testes básicos de runtime, fatores, estoque, builders e validação criados
- falta suíte mais ampla de regressão e reconciliação fiscal

### Fase 13 — Observabilidade e operação
**Status:** inicial/parcial
- health endpoints existem
- log de anomalias de conversão existe
- falta telemetria, timings e logs mais amplos

### Fases 14 a 16
**Status:** majoritariamente pendentes
- hardening, homologação e rollout ainda não foram executados

---

## Todo list prioritária atual

### Bloco A — alinhar execução validada ao melhor pipeline atual
- [ ] fazer a execução validada usar `run_gold_pipeline_v2`
- [ ] persistir `log_conversao_anomalias`
- [ ] expor preview do log de anomalias por API
- [ ] integrar melhor a vigência SEFIN na execução validada
- [ ] criar resposta de execução com metadados de qualidade da conversão

### Bloco B — melhorar qualidade analítica do estoque
- [ ] reforçar `0 - ESTOQUE INICIAL`
- [ ] tratar melhor `3 - ESTOQUE FINAL`
- [ ] melhorar cálculo de `periodo_inventario`
- [ ] aproximar regras de saídas desacobertadas dos documentos funcionais
- [ ] adicionar testes específicos de inventário e transição de períodos

### Bloco C — consolidar runtimes da API
- [ ] reduzir redundância entre v2, v3, v4 e v5
- [ ] definir app principal recomendado
- [ ] documentar fluxo oficial `silver -> gold -> preview`
- [ ] padronizar contratos de resposta
- [ ] adicionar endpoint resumido de status do CNPJ

### Bloco D — Fisconforme não atendido
- [ ] implementar consulta individual real
- [ ] implementar consulta em lote
- [ ] integrar cache com reuso por CNPJ
- [ ] implementar geração de notificações
- [ ] integrar com dossiê e pasta de saída

### Bloco E — frontend
- [ ] iniciar frontend real a partir da especificação existente
- [ ] criar módulos de Mercadorias, Estoque e Fisconforme
- [ ] implementar tabelas operacionais com persistência de contexto
- [ ] implementar navegação por subabas
- [ ] ligar frontend às APIs runtime

---

## Próximo passo recomendado

**Próxima entrega técnica imediata:**
- tornar a execução validada baseada na conversão v2 e persistir `log_conversao_anomalias`.
