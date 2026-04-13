# Contrato sugerido — fisconforme_cadastral_<cnpj>.parquet

- camada: gold
- objetivo: cache cadastral por CNPJ
- uso: domínio Fisconforme

## Campos mínimos esperados
- `run_id`
- `input_hash`
- `data_processamento`
- chaves funcionais do domínio

## Observações
- contrato gerado como referência para implementação;
- o arquivo real deverá ser produzido pelo pipeline do projeto;
- manter alinhamento com a nomenclatura do novo repositório.
