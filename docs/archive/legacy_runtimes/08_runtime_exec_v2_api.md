# Runtime Exec API v4

## Objetivo

A `runtime_exec_v2.py` é a camada de execução validada do pipeline gold.
Ela reconstrói automaticamente `itens_unificados` e `base_info_mercadorias` quando possível e falha explicitamente quando faltarem insumos mínimos.

## Melhorias sobre a v3

- valida os insumos obrigatórios;
- informa `missing`, `empty` e `stats`;
- reconstrói `itens_unificados` se ele não existir, usando `efd_c170`, `nfe_itens`, `nfce_itens` e `bloco_h`;
- reconstrói `base_info_mercadorias` se ele não existir, usando `itens_unificados`.

## Endpoint principal

- `POST /api/v4/pipeline/{cnpj}/run`

## Resposta esperada

### Sucesso
- `status = ok`
- `saved`
- `datasets`
- `rows`
- `validation`

### Falha de validação
- `status = validation_failed`
- `missing`
- `empty`
- `stats`
