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
- status da execucao: `GET /api/current-v2/pipeline/{cnpj}/status`

### Para diagnostico explicito por versao

Usar:

- `backend/app/runtime_gold_v20.py`
- prefixo `/api/gold20`
- status da execucao: `GET /api/gold20/pipeline/{cnpj}/status`

## Contrato incremental de status da execucao

As superficies oficiais `gold_v20/current-v2` expõem um resumo de prontidao do gold antes do `run`.

Campos principais:

- `validation`
- `selected_items_source`
- `using_aggregated_sources`
- `fontes_agr_validation`
- `references_status`
- `missing_references`
- `sefin_context`
- `temporal_resolution_summary`
- `conversion_quality_summary`
- `quality_attention_required`
- `attention_flags`
- `warnings`

Leitura pratica:

- `references_status` expoe o diagnostico bruto das referencias SEFIN disponiveis em runtime.
- `sefin_context.status` distingue `sefin_enriched_items`, `aggregated_sources`, `fallback_missing_references` e `fallback_without_sefin`.
- `sefin_context.references_complete` indica se o conjunto de referencias SEFIN esta completo.
- `sefin_context.using_sefin_enriched_items` indica uso direto de `itens_unificados_sefin`.
- `sefin_context.temporal_resolution_summary` replica o diagnostico de cobertura temporal usado na revisao de qualidade.
- `temporal_resolution_summary` informa cobertura efetiva de `aba_mensal`, `aba_anual` e `aba_periodos` quando esses datasets gold ja existem.
- `quality_attention_required` e `attention_flags` destacam `temporal_resolution_partial` quando ainda ha abas com interseccao temporal incompleta.
- `conversion_quality_summary` resume diagnostico de conversao, overrides e mapa manual ja carregados.

## Contrato incremental de run

O `POST .../pipeline/{cnpj}/run` tambem devolve `temporal_resolution_summary`, `quality_attention_required` e `attention_flags`.

Isso evita depender apenas do status resumido por CNPJ para identificar:

- disponibilidade da referencia de vigencia em runtime;
- cobertura temporal parcial apos a persistencia do gold;
- quais abas fiscais ainda exigem revisao por falta de interseccao temporal ou ausencia de `co_sefin_agr`.

## Observacao

A runtime antiga `runtime_gold_current.py` permanece como historico de consolidacao da trilha `gold_v19`, mas a referencia operacional nova passa a ser `current-v2`.
