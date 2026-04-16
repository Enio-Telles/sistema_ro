# Checklist de implementação — Runtime API v2 (06)

Data: 2026-04-16

| Item | Status | Evidência |
| --- | ---: | --- |
| `GET /api/v2/health` | Implementado | [backend/app/runtime_main_v2.py](backend/app/runtime_main_v2.py), [backend/app/routers/health.py](backend/app/routers/health.py) |
| `GET /api/v2/agregacao/{cnpj}/grupos` | Implementado | [backend/app/routers/agregacao.py](backend/app/routers/agregacao.py) |
| `GET /api/v2/conversao/{cnpj}/fatores` | Implementado | [backend/app/routers/conversao.py](backend/app/routers/conversao.py), [pipeline/conversao/fatores_v4.py](pipeline/conversao/fatores_v4.py) |
| `GET /api/v2/estoque/{cnpj}/overview` | Implementado | [backend/app/routers/estoque.py](backend/app/routers/estoque.py), [pipeline/estoque/resumo.py](pipeline/estoque/resumo.py) |
| `GET /api/v2/fisconforme/{cnpj}` | Parcial | [backend/app/routers/fisconforme.py](backend/app/routers/fisconforme.py) (stubs) |
| `POST /api/v2/pipeline/{cnpj}/run` | Pendente | Execução automática por CNPJ ainda requer integração/consenso (ver runtime_exec services) |

Notas: A runtime v2 oferece previews quando os parquets existem; a orquestração de runs por CNPJ ainda é evolutiva.
