# Checklist de implementação — fases 13 a 16

Data: 2026-04-16

Resumo: mapeamento item → status (Implementado / Pendente / Parcial) com evidências (caminhos no repositório).

| Item | Status | Evidência |
| --- | ---: | --- |
| Etapa 13.1 — registrar `match_rule`, `match_confidence` e `tipo_fator` | Implementado | [pipeline/mercadorias/grouping.py](pipeline/mercadorias/grouping.py), [pipeline/conversao/fatores_v4.py](pipeline/conversao/fatores_v4.py), [tests/test_grouping.py](tests/test_grouping.py) |
| Etapa 13.1 — registrar logs de agrupamento manual e reversão | Parcial | [pipeline/manual_aggregation_map_store.py](pipeline/manual_aggregation_map_store.py), [pipeline/mdc/build_from_existing_layers.py](pipeline/mdc/build_from_existing_layers.py) |
| Etapa 13.1 — registrar logs de fatores sem preço utilizável | Implementado | [pipeline/conversao/anomalias.py](pipeline/conversao/anomalias.py), [pipeline/persist_gold_v4.py](pipeline/persist_gold_v4.py) |
| Etapa 13.1 — registrar logs de reprocessamento por CNPJ | Pendente | (sem persistência explícita de histórico de runs localizada) |
| Etapa 13.1 — registrar alertas de estoque e inconsistências de inventário | Implementado (parcial) | [pipeline/estoque/resumo.py](pipeline/estoque/resumo.py), [pipeline/estoque/derivados_fiscais_v4.py](pipeline/estoque/derivados_fiscais_v4.py) |

| Etapa 13.2 — medir tempo de extração por query core | Pendente | (instrumentação de tempo não localizada) |
| Etapa 13.2 — medir tempo de transformação por domínio | Pendente | (instrumentação de tempo não localizada) |
| Etapa 13.2 — medir volume de linhas por dataset | Parcial | (manifests e previews disponíveis: [parquets/manifest_parquets.csv](parquets/manifest_parquets.csv), serviços de preview em backend) |
| Etapa 13.2 — medir taxa de reaproveitamento de cache no Fisconforme | Pendente | (telemetria de cache não localizada) |
| Etapa 13.2 — expor endpoint simples de health e readiness | Implementado | [backend/app/routers/health.py](backend/app/routers/health.py) |

| Etapa 14.1 — proteger caminhos de saída e gravação local | Pendente | (checagem adicional recomendada) |
| Etapa 14.1 — validar CNPJ/CPF e parâmetros de período | Parcial | [backend/app/config.py](backend/app/config.py) contém `cnpj_root`, validação específica não localizada |
| Etapa 14.1 — impedir path traversal em notificações e exportações | Pendente | (não localizado) |
| Etapa 14.1 — exigir schemas mínimos nas cargas de entrada | Parcial | contratos Parquet e validações parciais em `pipeline/*/contracts.py` |
| Etapa 14.1 — normalizar comportamento de falha parcial em lote | Pendente | (comportamento de falha parcial requer testes e políticas adicionais) |

| Etapa 14.2 — bloquear propagação de match ambíguo para o estoque | Pendente | (não há aplicação clara de threshold blocking no pipeline) |
| Etapa 14.2 — bloquear fator inválido fora de faixa esperada | Parcial | [pipeline/conversao/anomalias.py](pipeline/conversao/anomalias.py) cria alertas para fatores inválidos |
| Etapa 14.2 — impedir merge destrutivo sem snapshot de reversão | Parcial | [pipeline/manual_aggregation_map_store.py](pipeline/manual_aggregation_map_store.py) e contratos indicam suporte a snapshotting, mas processo de reversão completo é trabalho futuro |
| Etapa 14.2 — impedir perda de `id_linha_origem` e `codigo_fonte` | Implementado | [pipeline/normalization/keys.py](pipeline/normalization/keys.py), [pipeline/mercadorias/build_agregacao_from_mdc.py](pipeline/mercadorias/build_agregacao_from_mdc.py), testes relacionados |
| Etapa 14.2 — impedir mudanças silenciosas de contrato entre versões | Pendente | (requer CI/validation steps adicionais) |

| Etapa 15 — Homologação funcional | Pendente | (homologação por domínio requer ambiente e dados de amostra) |
| Etapa 16 — Produção e evolução | Pendente | (planejamento disponível, execução ainda pendente) |

Observação: itens marcados como "Parcial" têm artefatos (contratos, logs ou código) que cobrem parte do requisito; os itens "Pendente" não têm evidência suficiente no repositório atual.
