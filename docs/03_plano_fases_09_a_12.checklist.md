# Checklist de implementação — fases 09 a 12

Data: 2026-04-16

Resumo: mapeamento item → status (Implementado / Pendente) com evidências (caminhos no repositório).

| Item | Status | Evidência |
| --- | ---: | --- |
| Etapa 9.1 — `GET /api/v1/agregacao/{cnpj}/grupos` | Implementado | [backend/app/routers/agregacao.py](backend/app/routers/agregacao.py), [backend/app/main.py](backend/app/main.py) |
| Etapa 9.1 — `GET /api/v1/conversao/{cnpj}/fatores` | Implementado | [backend/app/routers/conversao.py](backend/app/routers/conversao.py), [backend/app/main.py](backend/app/main.py) |
| Etapa 9.1 — `GET /api/v1/estoque/{cnpj}/movimentos` | Implementado | [backend/app/routers/estoque.py](backend/app/routers/estoque.py), [backend/app/main.py](backend/app/main.py) |
| Etapa 9.1 — `GET /api/v1/estoque/{cnpj}/apuracao/mensal` | Implementado | [backend/app/routers/estoque.py](backend/app/routers/estoque.py) |
| Etapa 9.1 — `GET /api/v1/estoque/{cnpj}/apuracao/anual` e `/periodos` | Implementado | [backend/app/routers/estoque.py](backend/app/routers/estoque.py) |

| Etapa 9.2 — criar rotas de reprocessamento por domínio | Implementado | [backend/app/routers/agregacao.py](backend/app/routers/agregacao.py), [backend/app/routers/conversao.py](backend/app/routers/conversao.py) |
| Etapa 9.2 — separar reprocesso de agregação, conversão e estoque | Implementado (parcial) | [backend/app/pipeline_router_v6.py](backend/app/pipeline_router_v6.py), [backend/app/routers/agregacao.py](backend/app/routers/agregacao.py) |
| Etapa 9.2 — registrar `pipeline_run_id` e dependências da execução | Pendente | (sem evidência clara de persistência de run_id) |
| Etapa 9.2 — permitir reprocesso incremental por CNPJ e período | Pendente | (endpoints atuais aceitam `cnpj`, sem controle de período documentado) |
| Etapa 9.2 — persistir histórico mínimo de runs e logs | Pendente | (histórico de runs não localizado) |

| Etapa 10.1 — endpoint de configuração Oracle do Fisconforme | Parcial | [backend/app/config.py](backend/app/config.py), [backend/app/services/fisconforme_refresh_service_v3.py](backend/app/services/fisconforme_refresh_service_v3.py) |
| Etapa 10.1 — criar `consulta-cadastral` com cache por CNPJ | Implementado (stub) | [backend/app/routers/fisconforme.py](backend/app/routers/fisconforme.py) |
| Etapa 10.1 — criar `consulta-lote` com retorno por CNPJ | Implementado (stub) | [backend/app/routers/fisconforme.py](backend/app/routers/fisconforme.py) |
| Etapa 10.1 — separar cache de cadastral e cache de malhas | Pendente/Parcial | [pipeline/fisconforme](pipeline/fisconforme) (providers exist) |
| Etapa 10.1 — persistir resultados em `dados/CNPJ/<cnpj>/fisconforme/` | Parcial | [backend/app/services/fisconforme_refresh_service_v3.py](backend/app/services/fisconforme_refresh_service_v3.py) references provider and storage |

| Etapa 10.2 — geração de notificações individuais e em lote | Implementado (stubs) | [backend/app/routers/fisconforme.py](backend/app/routers/fisconforme.py) |

| Etapa 11.1 — Frontend (Mercadorias / Estoque) | Pendente | (documentação existe, frontend não implementado) |
| Etapa 11.2 — Frontend (Fisconforme) | Pendente | (documentação existe, frontend não implementado) |

| Etapa 12.1 — testar normalização de chaves e datas | Implementado | [tests/test_keys.py](tests/test_keys.py), [pipeline/normalization](pipeline/normalization) |
| Etapa 12.1 — testar agrupamento automático e manual | Implementado | [tests/test_build_agregacao_from_mdc_v2.py](tests/test_build_agregacao_from_mdc_v2.py), [pipeline/mercadorias/grouping.py](pipeline/mercadorias/grouping.py) |
| Etapa 12.1 — testar preservação de override na conversão | Implementado | [tests/test_resumo_alertas.py](tests/test_resumo_alertas.py), [pipeline/conversao/overrides.py](pipeline/conversao/overrides.py) |
| Etapa 12.1 — testar cálculo da `mov_estoque` | Implementado | [tests/test_mov_estoque.py](tests/test_mov_estoque.py), [pipeline/estoque/mov_estoque_v2.py](pipeline/estoque/mov_estoque_v2.py) |
| Etapa 12.1 — testar rotas principais do backend | Pendente | (testes de integração HTTP não localizados) |

| Etapa 12.2 — reconciliar totais entre bronze, silver e gold | Parcial | [tests/test_estoque_divergence_rollup.py](tests/test_estoque_divergence_rollup.py), [pipeline/run_gold_v20.py](pipeline/run_gold_v20.py) |
| Etapa 12.2 — comparar estoque antigo vs estoque recalculado | Implementado (coberto por testes) | [tests/test_estoque_divergence_rollup.py](tests/test_estoque_divergence_rollup.py) |
| Etapa 12.2 — validar coerência entre EFD, NFe/NFCe, DIMP e estoque | Parcial | [pipeline/estoque/derivados_fiscais_v4.py](pipeline/estoque/derivados_fiscais_v4.py), tests exist for cases |

Observação: os endpoints existem (scaffold) e várias rotas retornam previews; muitos handlers são stubs que devolvem estrutura JSON. Posso transformar stubs em handlers reais se desejar.
