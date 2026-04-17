# Runtime Silver API v5b

## Objetivo

A `runtime_silver_v2.py` prepara a silver-base e também tenta enriquecer `itens_unificados` com classificação e vigência SEFIN.

## Endpoint principal

- `POST /api/v5b/silver/{cnpj}/prepare-sefin`

## Saídas persistidas

- `silver/itens_unificados_<cnpj>.parquet`
- `silver/base_info_mercadorias_<cnpj>.parquet`
- `silver/itens_unificados_sefin_<cnpj>.parquet`

## Campos operacionais adicionais da resposta

- `references_status`
- `missing_references`
- `sefin_enrichment_applied`
- `sefin_enrichment`
- `warnings`

## Observação

O enriquecimento SEFIN depende da presença dos arquivos de referência no diretório configurado de referências.
Se eles não estiverem disponíveis, a preparação da silver continua e persiste ao menos os datasets-base.

Agora o endpoint distingue explicitamente:

- enriquecimento aplicado com sucesso;
- enriquecimento pulado por ausência de referências;
- fallback após erro capturado no enriquecimento.
