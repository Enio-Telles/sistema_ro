# Referências do sistema_ro

## Referências fiscais obrigatórias
- `sitafe_cest.parquet`
- `sitafe_cest_ncm.parquet`
- `sitafe_ncm.parquet`
- `sitafe_produto_sefin.parquet`
- `sitafe_produto_sefin_aux.parquet`

## Uso esperado

Esses arquivos devem ser tratados como dimensões estáticas ou de baixa mutação.
A aplicação não deve depender de consulta Oracle pesada para obter esses dados toda vez.

## Responsabilidades

- `sitafe_cest.parquet` — fallback por CEST
- `sitafe_cest_ncm.parquet` — correspondência ideal por CEST+NCM
- `sitafe_ncm.parquet` — fallback por NCM
- `sitafe_produto_sefin.parquet` — descrição do `co_sefin`
- `sitafe_produto_sefin_aux.parquet` — vigência e parâmetros tributários históricos

## Regra operacional

Atualizações dessas referências devem ser versionadas e registradas com data de carga, origem e checksum.
