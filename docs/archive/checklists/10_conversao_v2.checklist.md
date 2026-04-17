# Checklist de implementação — Conversão v2 (10)

Data: 2026-04-16

| Item | Status | Evidência |
| --- | ---: | --- |
| Priorização: `estrutural` → `preco` → `manual` | Implementado | [pipeline/conversao/fatores_v4.py](pipeline/conversao/fatores_v4.py), [pipeline/conversao/structural_factors.py](pipeline/conversao/structural_factors.py) |
| Fator estrutural — detecção por `descr_item`/`descr_compl` | Implementado | [pipeline/conversao/structural_factors.py](pipeline/conversao/structural_factors.py) |
| Fator por preço (fallback) | Implementado | [pipeline/conversao/price_factors.py](pipeline/conversao/price_factors.py) |
| Override manual e aplicação em lote | Implementado | [pipeline/conversao/overrides.py](pipeline/conversao/overrides.py) |
| `log_conversao_anomalias` (alertas de fator) | Implementado | persistência em [pipeline/persist_gold_v4.py](pipeline/persist_gold_v4.py), geração em [pipeline/conversao/anomalias.py](pipeline/conversao/anomalias.py) |
