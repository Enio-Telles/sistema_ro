# Runtime Exec API v6c

## Objetivo

A `runtime_exec_v5.py` é a versão mais completa da execução validada no estado atual.
Ela:
- usa o `gold_v3`;
- prefere `itens_unificados_sefin` quando existir;
- informa referências ausentes;
- emite avisos quando a execução ocorre sem enriquecimento SEFIN preferencial.

## Endpoint principal

- `POST /api/v6c/pipeline/{cnpj}/run`

## Campos adicionais de resposta

- `selected_items_source`
- `using_sefin_items`
- `missing_references`
- `warnings`
- `pipeline_version`

## Interpretação prática

### `selected_items_source`
Mostra qual dataset foi usado como base de itens para o gold.

### `using_sefin_items`
Indica se a execução partiu de `itens_unificados_sefin`.

### `missing_references`
Lista os Parquets de referência não encontrados em `workspace/references/`.

### `warnings`
Explica quando a execução ocorreu com degradação operacional, por exemplo:
- sem conjunto completo de referências SEFIN;
- sem uso do enriquecimento SEFIN como base preferencial.

## Contratos de Resposta

### POST /api/v6c/pipeline/{cnpj}/run

Descrição: executa o pipeline Gold e persiste os outputs. Retorna um resumo da execução,
validação de entradas e informações sobre referências e avisos.

- Sucesso (campo `status` = `"ok"`) — campos principais:

```json
{
	"cnpj": "12.345.678/0001-90",
	"saved": {"gold_parquet": "parquets/gold/12.345.678-0001-90/gold.parquet"},
	"datasets": ["gold_parquet"],
	"rows": {"gold_parquet": 123},
	"status": "ok",
	"validation": {"ok": true, "missing": [], "empty": [], "stats": {"itens_df": 10, "c170_df": 100}},
	"pipeline_version": "gold_v3",
	"selected_items_source": "itens_unificados_sefin",
	"using_sefin_items": true,
	"missing_references": [],
	"warnings": []
}
```

- Validação falhou (campo `status` = `"validation_failed"`) — campos principais (retornados com status HTTP 200):

```json
{
	"cnpj": "12.345.678/0001-90",
	"status": "validation_failed",
	"selected_items_source": "itens_unificados_rebuilt",
	"using_sefin_items": false,
	"missing_references": ["referencia_x.parquet"],
	"ok": false,
	"missing": ["itens_df"],
	"empty": [],
	"stats": {"itens_df": 0, "c170_df": 0}
}
```

Observações:
- Os campos de validação (`ok`, `missing`, `empty`, `stats`) aparecem no topo da resposta quando a validação falha.
- `saved` é um mapeamento dos datasets persistidos; seu formato depende da implementação de persistência (`persist_gold_outputs_v2`).

### GET /api/v6c/pipeline/{cnpj}/status

Descrição: retorna um resumo de saúde/preparação dos inputs para execução do pipeline,
sem executar a pipeline.

```json
{
	"cnpj": "12.345.678/0001-90",
	"validation": {"ok": true, "missing": [], "empty": [], "stats": {"itens_df": 10, "c170_df": 100}},
	"missing_references": ["referencia_y.parquet"],
	"selected_items_source": "itens_unificados_sefin",
	"using_sefin_items": true
}
```

Campos (tipos e significado):
- `cnpj` (string): identificador de empresa pedido.
- `status` (string): `'ok'` ou `'validation_failed'` (apenas no endpoint `run`).
- `validation` (object): resultado de `validate_gold_inputs` com chaves `ok` (bool), `missing` (lista de nomes), `empty` (lista de nomes), `stats` (mapa nome->número de linhas).
- `saved` (object): mapeamento de nomes de datasets para local de armazenamento (implementação específica).
- `datasets` (array[string]): lista de datasets persistidos.
- `rows` (object): contagem de linhas por dataset persistido.
- `selected_items_source` (string): origem dos itens usados na execução.
- `using_sefin_items` (bool): se os itens SEFIN foram preferidos.
- `missing_references` (array[string]): referências/parquets ausentes em runtime.
- `warnings` (array[string]): avisos gerados pela execução.
