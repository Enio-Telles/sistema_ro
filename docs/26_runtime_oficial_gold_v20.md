# Runtime Oficial V2

## Runtime recomendada

A runtime oficial recomendada do projeto passa a ser:

- `backend/app/runtime_gold_v20.py`

Alias operacional atual:

- `backend/app/runtime_gold_current_v2.py`

## Motivo

A trilha oficial consolidada fica:

```text
mdc_base -> agregacao -> fontes_agr validadas -> gold_v20 -> checagem pos-gold
```

Essa escolha foi feita porque `gold_v20`:

- prefere `fontes_agr` validadas por schema;
- mantem fallback seguro para silver quando necessario;
- executa checagem pos-gold para estoque e derivados fiscais;
- integra `diagnostico_conversao_unidade_base` ao fluxo operacional de conversao.

## Uso recomendado

### Para operacao corrente

Usar preferencialmente:

- `backend/app/runtime_gold_current_v2.py`
- prefixo `/api/current-v2`

### Para diagnostico explicito por versao

Usar:

- `backend/app/runtime_gold_v20.py`
- prefixo `/api/gold20`

## Observacao

A runtime antiga `runtime_gold_current.py` permanece como historico de consolidacao da trilha `gold_v19`, mas a referencia operacional nova passa a ser `current-v2`.
