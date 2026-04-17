# Checklist de implementação — Runtime Exec v2 / Exec API v4 (08)

Data: 2026-04-16

| Item | Status | Evidência |
| --- | ---: | --- |
| Validação de insumos obrigatórios (`missing`/`empty`/`stats`) | Implementado | lógica de validação em [pipeline/run_gold_v20.py](pipeline/run_gold_v20.py) e helpers de validação em [pipeline/validation/validators.py](pipeline/validation/validators.py) |
| Reconstrução automática de `itens_unificados` quando faltam insumos | Implementado | [pipeline/run_gold_v20.py](pipeline/run_gold_v20.py), [pipeline/normalization/unified_items.py](pipeline/normalization/unified_items.py) |
| `POST /api/v4/pipeline/{cnpj}/run` — endpoint principal | Implementado | [backend/app/runtime_exec_v2.py](backend/app/runtime_exec_v2.py) |
| Resposta padronizada com `status`/`saved`/`datasets`/`validation` | Parcial | estrutura em serviços de execução (ver [backend/app/services/pipeline_exec_v3_service.py](backend/app/services/pipeline_exec_v3_service.py)); enriquecimento de metadados ainda em evolução |
