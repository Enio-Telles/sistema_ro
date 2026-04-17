# Checklist de implementação — fases 05 a 08

Data: 2026-04-15

Resumo: mapeamento item → status (Implementado / Pendente) com evidências (caminhos no repositório).

| Item | Status | Evidência |
| --- | ---: | --- |
| Etapa 5.1 — gerar `item_unidades_<cnpj>.parquet` | Implementado | [pipeline/conversao/item_unidades_v3.py](pipeline/conversao/item_unidades_v3.py), [pipeline/persist_gold_v4.py](pipeline/persist_gold_v4.py) |
| Etapa 5.1 — escolher `unid_ref` por regra explícita e fallback controlado | Implementado | [pipeline/conversao/fatores_v4.py](pipeline/conversao/fatores_v4.py) |
| Etapa 5.1 — calcular fator estrutural por embalagem, volume, peso e multiplicidade | Implementado | [pipeline/conversao/structural_factors.py](pipeline/conversao/structural_factors.py) |
| Etapa 5.1 — registrar `tipo_fator`, `fonte_fator` e `confianca_fator` | Implementado | [pipeline/conversao/fatores_v4.py](pipeline/conversao/fatores_v4.py), [tests/test_fatores_v4.py](tests/test_fatores_v4.py) |
| Etapa 5.1 — persistir `fatores_conversao_<cnpj>.parquet` | Implementado | [pipeline/persist_gold_v4.py](pipeline/persist_gold_v4.py), [pipeline/run_gold_v20.py](pipeline/run_gold_v20.py) |
| Etapa 5.2 — preservar `fator_manual` e `unid_ref_manual` | Implementado | [pipeline/conversao/overrides.py](pipeline/conversao/overrides.py), [tests/test_resumo_alertas.py](tests/test_resumo_alertas.py) |
| Etapa 5.2 — recalcular fatores quando a unidade de referência mudar | Implementado | [pipeline/conversao/overrides.py](pipeline/conversao/overrides.py), [pipeline/conversao/fatores_v4.py](pipeline/conversao/fatores_v4.py) |
| Etapa 5.2 — criar log de produtos sem preço médio utilizável | Implementado | [pipeline/conversao/anomalias.py](pipeline/conversao/anomalias.py), [pipeline/persist_gold_v4.py](pipeline/persist_gold_v4.py) |
| Etapa 5.2 — criar log de reconciliação após reagrupamento | Implementado | [pipeline/estoque/resumo.py](pipeline/estoque/resumo.py), [docs/MDC_Sql/modularizado_2/sql/13_reconciliacao_bloco_e.sql](docs/MDC_Sql/modularizado_2/sql/13_reconciliacao_bloco_e.sql) |
| Etapa 5.2 — bloquear propagação automática de fator ambíguo | Implementado | [pipeline/conversao/fatores_v4.py](pipeline/conversao/fatores_v4.py) |

| Etapa 6.1 — carregar `sitafe_cest.parquet`, `sitafe_cest_ncm.parquet` e `sitafe_ncm.parquet` | Implementado | [pipeline/references/loaders.py](pipeline/references/loaders.py), [parquets/manifest_parquets.csv](parquets/manifest_parquets.csv) |
| Etapa 6.1 — carregar `sitafe_produto_sefin.parquet` | Implementado | [pipeline/references/loaders.py](pipeline/references/loaders.py), [parquets/manifest_parquets.csv](parquets/manifest_parquets.csv) |
| Etapa 6.1 — inferir `co_sefin` por `CEST+NCM`, `CEST` e `NCM` | Implementado | [pipeline/references/sefin_classification.py](pipeline/references/sefin_classification.py) |
| Etapa 6.1 — registrar descrição do `co_sefin` inferido | Implementado | [pipeline/references/sefin_classification.py](pipeline/references/sefin_classification.py) |
| Etapa 6.1 — salvar logs de classificação sem correspondência | Implementado | [pipeline/mdc/build_from_existing_layers.py](pipeline/mdc/build_from_existing_layers.py), [references/README.md](references/README.md) |

| Etapa 6.2 — carregar `sitafe_produto_sefin_aux.parquet` | Implementado | [pipeline/references/loaders.py](pipeline/references/loaders.py), [parquets/manifest_parquets.csv](parquets/manifest_parquets.csv) |
| Etapa 6.2 — resolver vigência por data de emissão/saída | Implementado | [pipeline/references/sefin_vigencia.py](pipeline/references/sefin_vigencia.py), [docs/MDC_Sql/modularizado_2/tabela_periodo.md](docs/MDC_Sql/modularizado_2/tabela_periodo.md) |
| Etapa 6.2 — anexar `it_pc_interna`, `it_in_st`, `it_pc_mva` e parâmetros | Implementado | [pipeline/mdc/build_from_existing_layers.py](pipeline/mdc/build_from_existing_layers.py), [pipeline/references/sefin_classification.py](pipeline/references/sefin_classification.py) |
| Etapa 6.2 — distinguir atributos `inferido` e atributos de origem auxiliar | Implementado | [pipeline/references/sefin_projection.py](pipeline/references/sefin_projection.py) |
| Etapa 6.2 — persistir datasets enriquecidos para consumo do estoque | Implementado | [pipeline/persist_gold_v4.py](pipeline/persist_gold_v4.py), [pipeline/run_gold_v20.py](pipeline/run_gold_v20.py) |

| Etapa 7.1 — integrar `c170`, `nfe`, `nfce`, `bloco_h` e linhas `gerado` | Implementado | [pipeline/estoque/mov_estoque_v2.py](pipeline/estoque/mov_estoque_v2.py), [pipeline/estoque/mov_estoque_v3.py](pipeline/estoque/mov_estoque_v3.py) |
| Etapa 7.1 — aplicar `id_agrupado`, `unid_ref` e `fator` | Implementado | [pipeline/estoque/mov_estoque_v2.py](pipeline/estoque/mov_estoque_v2.py) |
| Etapa 7.1 — calcular `q_conv`, `preco_unit` e sinal da operação | Implementado | [pipeline/estoque/mov_estoque_v2.py](pipeline/estoque/mov_estoque_v2.py) |
| Etapa 7.1 — produzir `saldo_estoque_anual`, `entr_desac_anual` e `custo_medio_anual` | Implementado | [pipeline/estoque/mov_estoque_v2.py](pipeline/estoque/mov_estoque_v2.py) |
| Etapa 7.1 — preservar flags de devolução, repetição e exclusão de estoque | Implementado | [pipeline/estoque/mov_estoque_v2.py](pipeline/estoque/mov_estoque_v2.py) |

| Etapa 7.2 — criar `periodo_inventario` por reinício de estoque inicial | Implementado | [pipeline/estoque/periodos.py](pipeline/estoque/periodos.py) |
| Etapa 7.2 — calcular `saldo_estoque_periodo` | Implementado | [pipeline/estoque/mov_estoque_v2.py](pipeline/estoque/mov_estoque_v2.py) |
| Etapa 7.2 — calcular `entr_desac_periodo` | Implementado | [pipeline/estoque/mov_estoque_v2.py](pipeline/estoque/mov_estoque_v2.py) |
| Etapa 7.2 — calcular `custo_medio_periodo` | Implementado | [pipeline/estoque/mov_estoque_v2.py](pipeline/estoque/mov_estoque_v2.py) |
| Etapa 7.2 — salvar `mov_estoque_<cnpj>.parquet` pronta para agregações derivadas | Implementado | [pipeline/persist_gold_v4.py](pipeline/persist_gold_v4.py) |

| Etapa 8.1 — gerar `aba_mensal_<cnpj>.parquet` | Implementado | [pipeline/estoque/derivados_fiscais_v4.py](pipeline/estoque/derivados_fiscais_v4.py), [pipeline/persist_gold_v4.py](pipeline/persist_gold_v4.py) |
| Etapa 8.1 — resumir entradas, saídas, estoque e custo médio por mês | Implementado | [pipeline/estoque/derivados_fiscais_v4.py](pipeline/estoque/derivados_fiscais_v4.py) |
| Etapa 8.1 — calcular `ICMS_entr_desacob` com regra de ST do mês | Implementado | [pipeline/estoque/derivados_fiscais_v4.py](pipeline/estoque/derivados_fiscais_v4.py) |
| Etapa 8.1 — materializar campos `_periodo` na visão mensal | Implementado | [pipeline/estoque/derivados_fiscais_v4.py](pipeline/estoque/derivados_fiscais_v4.py) |
| Etapa 8.1 — incluir listas de unidades do mês e unidades de referência do mês | Implementado | [pipeline/estoque/derivados_fiscais_v4.py](pipeline/estoque/derivados_fiscais_v4.py) |

| Etapa 8.2 — gerar `aba_anual_<cnpj>.parquet` | Implementado | [pipeline/estoque/derivados_fiscais_v4.py](pipeline/estoque/derivados_fiscais_v4.py), [pipeline/persist_gold_v4.py](pipeline/persist_gold_v4.py) |
| Etapa 8.2 — gerar `aba_periodos_<cnpj>.parquet` | Implementado | [pipeline/estoque/derivados_fiscais_v4.py](pipeline/estoque/derivados_fiscais_v4.py) |
| Etapa 8.2 — calcular `saidas_desacob` e `estoque_final_desacob` | Implementado | [pipeline/estoque/derivados_fiscais_v4.py](pipeline/estoque/derivados_fiscais_v4.py) |
| Etapa 8.2 — calcular `ICMS_saidas_desac` e `ICMS_estoque_desac` | Implementado | [pipeline/estoque/derivados_fiscais_v4.py](pipeline/estoque/derivados_fiscais_v4.py) |
| Etapa 8.2 — produzir `estoque_resumo_<cnpj>.parquet` e `estoque_alertas_<cnpj>.parquet` | Implementado | [pipeline/estoque/resumo.py](pipeline/estoque/resumo.py), [pipeline/persist_gold_v4.py](pipeline/persist_gold_v4.py) |

Observação: marquei como "Implementado" itens que têm implementação de código, testes e/ou contratos Parquet no repositório. Se preferir, posso ajustar status para "Parcial" quando for necessário separar work‑items menores (ex.: testes adicionais, CI, validações de produção).
