# Runtime Silver API v5

## Objetivo

A `runtime_silver.py` prepara a base silver mínima necessária para alimentar a execução gold.

## Endpoint principal

- `POST /api/v5/silver/{cnpj}/prepare`

## O que ele faz

- lê `efd_c170`, `nfe_itens`, `nfce_itens` e `bloco_h` já persistidos em `silver`;
- gera `itens_unificados`;
- gera `base_info_mercadorias`;
- persiste esses dois datasets em `silver`.

## Fluxo recomendado

1. carregar datasets silver-base do CNPJ;
2. chamar `POST /api/v5/silver/{cnpj}/prepare`;
3. chamar `POST /api/v4/pipeline/{cnpj}/run` para gerar o gold validado.
