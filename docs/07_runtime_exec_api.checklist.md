# Checklist de implementação — Runtime Exec API (v3) (07)

Data: 2026-04-16

| Item | Status | Evidência |
| --- | ---: | --- |
| Entradas esperadas no storage (silver files) | Implementado | especificações em [docs/08_runtime_exec_v2_api.md](08_runtime_exec_v2_api.md) e checks em [pipeline/run_gold_v20.py](pipeline/run_gold_v20.py) |
| Saídas persistidas (`produtos_agrupados`, `fatores_conversao`, `mov_estoque`, etc.) | Implementado | [pipeline/persist_gold_v4.py](pipeline/persist_gold_v4.py), [pipeline/run_gold_v20.py](pipeline/run_gold_v20.py) |
| `POST /api/v3/pipeline/{cnpj}/run` (endpoint de execução) | Implementado | [backend/app/runtime_exec.py](backend/app/runtime_exec.py) e serviços de orquestração em [backend/app/services/pipeline_exec_v3_service.py](backend/app/services/pipeline_exec_v3_service.py) |
| Endpoints de preview (agregação/conversão/estoque) | Implementado | [backend/app/routers/agregacao.py](backend/app/routers/agregacao.py), [backend/app/routers/conversao.py](backend/app/routers/conversao.py) |

Observação: a execução validada persiste os artefatos gold e já é usada em fluxos de teste/CI; integração completa com triggers/cron ainda é evolução.
