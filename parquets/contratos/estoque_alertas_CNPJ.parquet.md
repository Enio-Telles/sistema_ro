# Contrato sugerido — estoque_alertas_<cnpj>.parquet

- camada: gold
- objetivo: anomalias e divergências de estoque
- uso: fila de trabalho

## Campos mínimos esperados
- `run_id`
- `input_hash`
- `data_processamento`
- chaves funcionais do domínio

## Observações
- contrato gerado como referência para implementação;
- o arquivo real deverá ser produzido pelo pipeline do projeto;
- manter alinhamento com a nomenclatura do novo repositório.
