# Runtime API v2

## Objetivo

A `runtime.py` expõe uma API paralela para leitura de datasets já materializados em Parquet.
Ela existe para acelerar a integração do backend com o pipeline sem depender de reescrever as rotas scaffold da v1.

## Endpoints

- `GET /api/v2/health`
- `GET /api/v2/agregacao/{cnpj}/grupos`
- `GET /api/v2/conversao/{cnpj}/fatores`
- `GET /api/v2/estoque/{cnpj}/overview`
- `GET /api/v2/fisconforme/{cnpj}`
- `POST /api/v2/pipeline/{cnpj}/run`

## Observação

No estado atual:
- os endpoints de agregação, conversão, estoque e fisconforme já leem previews reais de parquets ou cache, quando existirem;
- o endpoint de pipeline ainda está reservado para a próxima etapa de persistência automática por CNPJ.
