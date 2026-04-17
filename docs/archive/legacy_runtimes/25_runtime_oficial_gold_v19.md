# Runtime Oficial

## Runtime recomendada

A runtime oficial recomendada do projeto passa a ser:

- `backend/app/runtime_gold_v19.py`

Alias operacional atual:

- `backend/app/runtime_gold_current.py`

## Motivo

A trilha oficial consolidada e:

```text
mdc_base -> agregacao -> fontes_agr validadas -> gold_v19 -> checagem pos-gold
```

Essa escolha foi feita porque `gold_v19`:

- prefere `fontes_agr` validadas por schema;
- mantem fallback seguro para silver quando necessario;
- executa checagem pos-gold para estoque e derivados fiscais;
- preserva a arquitetura operacional nova do projeto.

## Uso recomendado

### Para operacao corrente

Usar preferencialmente:

- `backend/app/runtime_gold_current.py`
- prefixo `/api/current`

### Para diagnostico explicito por versao

Usar:

- `backend/app/runtime_gold_v19.py`
- prefixo `/api/gold19`

## Runtimes anteriores

As runtimes anteriores permanecem como historico de transicao e comparacao tecnica. Elas nao devem ser tratadas como referencia principal de operacao.

Mapa resumido:

- `runtime_gold_v14`: mdc_base inicial
- `runtime_gold_v15`: agregacao a partir do mdc
- `runtime_gold_v16`: fontes_agr inicial
- `runtime_gold_v17`: gold preferindo fontes_agr
- `runtime_gold_v18`: fontes_agr validadas
- `runtime_gold_v19`: runtime oficial
