# Checklist de implementação — Frontend operacional (05)

Data: 2026-04-16

Resumo: mapeamento item → status (Implementado / Pendente / Parcial) com evidências.

| Item | Status | Evidência |
| --- | ---: | --- |
| Módulos principais — Mercadorias (dados) | Implementado | [pipeline/mercadorias/build_agregacao_from_mdc_v2.py](pipeline/mercadorias/build_agregacao_from_mdc_v2.py), [pipeline/mercadorias/builders.py](pipeline/mercadorias/builders.py) |
| Módulos principais — Mercadorias (UI: subabas e revisão assistida) | Pendente | (frontend não encontrado no repositório) |
| Módulos principais — Estoque (dados) | Implementado | [pipeline/estoque/mov_estoque_v2.py](pipeline/estoque/mov_estoque_v2.py), [pipeline/estoque/derivados_fiscais_v4.py](pipeline/estoque/derivados_fiscais_v4.py) |
| Módulos principais — Estoque (UI: subabas reais) | Pendente | (frontend não encontrado) |
| Módulos principais — Fisconforme (serviço e APIs) | Parcial | [backend/app/routers/fisconforme.py](backend/app/routers/fisconforme.py), [pipeline/fisconforme/provider_oracle_v2.py](pipeline/fisconforme/provider_oracle_v2.py) |
| Agregação — artefatos (`lista_descricoes`, `lista_desc_compl`, `ids_origem_agrupamento`) | Implementado | [pipeline/mercadorias/build_agregacao_from_mdc.py](pipeline/mercadorias/build_agregacao_from_mdc.py), [docs/MDC_Sql/modularizado_2/tabela_mensal.md](docs/MDC_Sql/modularizado_2/tabela_mensal.md) |
| Conversão — campos exibidos (`fator`, `tipo_fator`, `confianca_fator`, `fator_manual`) | Implementado | [pipeline/conversao/fatores_v4.py](pipeline/conversao/fatores_v4.py), [pipeline/conversao/overrides.py](pipeline/conversao/overrides.py) |
| Estoque — trilha cronológica e KPIs (dados) | Implementado | [pipeline/estoque/mov_estoque_v2.py](pipeline/estoque/mov_estoque_v2.py), [pipeline/estoque/resumo.py](pipeline/estoque/resumo.py) |
| UX transversal (filtros, paginação, exportação, persistência de estado) | Pendente | (frontend não encontrado) |
| Persistência de estado por módulo (filters/cols/period) | Pendente | (frontend/state implementation missing) |

Observação: os artefatos de dados necessários já existem no backend/pipeline; a implementação do frontend (UI) ainda não existe neste repositório.
