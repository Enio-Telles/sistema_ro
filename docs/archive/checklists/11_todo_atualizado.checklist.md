# Checklist de implementação — Todo atualizado (11)

Data: 2026-04-16

Resumo: mapeamento rápido das pendências listadas em `docs/11_todo_atualizado.md`.

| Item prioritário | Status | Evidência |
| --- | ---: | --- |
| Fazer a execução validada usar `run_gold_pipeline_v2` | Implementado | chamada em [backend/app/services/pipeline_exec_v3_service.py](backend/app/services/pipeline_exec_v3_service.py) → `run_and_persist_gold_pipeline_v2` |
| Persistir `log_conversao_anomalias` | Implementado | persistência em [pipeline/persist_gold_v4.py](pipeline/persist_gold_v4.py) |
| Expor preview do `log_conversao_anomalias` por API | Implementado | serviço de qualidade em [backend/app/services/conversao_quality_service.py](backend/app/services/conversao_quality_service.py) |
| Integrar vigência SEFIN na execução validada | Pendente | enriquecimento SEFIN parcialmente aplicado em [pipeline/references/enrichment.py] — integração completa pendente |
| Criar resposta de execução com metadados de qualidade da conversão | Parcial | serviços retornam `validation`/`stats` em execuções, mas metadados completos ainda em evolução |

Próximo passo recomendado: priorizar integração SEFIN e persistência de metadados de execução antes de consolidar frontends.
