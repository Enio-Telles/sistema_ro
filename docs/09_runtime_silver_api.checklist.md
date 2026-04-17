# Checklist de implementação — Runtime Silver API (v5) (09)

Data: 2026-04-16

| Item | Status | Evidência |
| --- | ---: | --- |
| `POST /api/v5/silver/{cnpj}/prepare` (preparação da silver-base) | Implementado | [backend/app/runtime_silver.py](backend/app/runtime_silver.py), [backend/app/services/silver_base_service.py](backend/app/services/silver_base_service.py) |
| Geração de `itens_unificados` e `base_info_mercadorias` | Implementado | [pipeline/normalization/unified_items.py](pipeline/normalization/unified_items.py), [pipeline/mercadorias/identity.py](pipeline/mercadorias/identity.py) |
| Persistência dos datasets em `silver` | Implementado | serviços em [backend/app/services/silver_base_service.py](backend/app/services/silver_base_service.py) e gravação via Polars |
| Fluxo recomendado documentado (`prepare` → `run`) | Implementado | [docs/09_runtime_silver_api.md](09_runtime_silver_api.md) |
