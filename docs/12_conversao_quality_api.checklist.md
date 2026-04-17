# Checklist de implementação — Conversion Quality API (v7) (12)

Data: 2026-04-16

| Item | Status | Evidência |
| --- | ---: | --- |
| `GET /api/v7/conversao/{cnpj}/quality` (endpoint) | Parcial | serviço de qualidade existe em [backend/app/services/conversao_quality_service.py](backend/app/services/conversao_quality_service.py); router de exposição pode estar em runtime_quality.py |
| Resumo quantitativo da conversão | Implementado | [backend/app/services/conversao_quality_service.py](backend/app/services/conversao_quality_service.py) |
| Preview de `item_unidades` e `fatores_conversao` | Implementado | previews gerados a partir de [pipeline/conversao/fatores_v4.py](pipeline/conversao/fatores_v4.py) e serviços de preview |
| Preview de `log_conversao_anomalias` | Implementado | geração em [pipeline/conversao/anomalias.py](pipeline/conversao/anomalias.py), preview via serviços de qualidade |

Observação: o serviço de qualidade está presente; a rota pública v7 pode ser um wrapper runtime em evolução.
