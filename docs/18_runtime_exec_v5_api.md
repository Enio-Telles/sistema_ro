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
