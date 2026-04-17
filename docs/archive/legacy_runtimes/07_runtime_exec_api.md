# Runtime Exec API v3

## Objetivo

A `runtime_exec.py` expõe a API de execução do pipeline gold por CNPJ usando datasets já persistidos em `silver` e `gold`.

## Entradas esperadas no storage

Para o `POST /api/v3/pipeline/{cnpj}/run` funcionar, o workspace precisa ter ao menos:
- `silver/itens_unificados_<cnpj>.parquet`
- `silver/efd_c170_<cnpj>.parquet`
- `silver/nfe_itens_<cnpj>.parquet`
- `silver/nfce_itens_<cnpj>.parquet` (opcional)
- `silver/bloco_h_<cnpj>.parquet` (opcional)
- `gold/overrides_conversao_<cnpj>.parquet` (opcional)
- `silver/base_info_mercadorias_<cnpj>.parquet` (opcional)

## Saídas persistidas

O runner persiste automaticamente:
- `produtos_agrupados`
- `id_agrupados`
- `produtos_final`
- `item_unidades`
- `fatores_conversao`
- `mov_estoque`
- `aba_mensal`
- `aba_anual`
- `aba_periodos`
- `estoque_resumo`
- `estoque_alertas`

## Endpoints principais

- `GET /api/v3/health`
- `GET /api/v3/agregacao/{cnpj}/grupos`
- `GET /api/v3/conversao/{cnpj}/fatores`
- `GET /api/v3/estoque/{cnpj}/overview`
- `GET /api/v3/fisconforme/{cnpj}`
- `POST /api/v3/pipeline/{cnpj}/run`
