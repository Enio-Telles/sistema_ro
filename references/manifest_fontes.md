# Manifesto de fontes consideradas

## Pasta de dados considerada
- pasta de plano e pacote curado com SQLs e contratos
- pasta com referências fiscais (`CEST`, `NCM`, `CO_SEFIN`, `cfop`, `cst`)
- pasta com insumos de `NFe`, `NFE_eventos` e `Fisconforme`

## Mapeamento recomendado

### Referências
- `CEST/` -> `references/sefin/sitafe_cest*.parquet`
- `NCM/` -> `references/sefin/sitafe_ncm.parquet`
- `CO_SEFIN/` -> `references/sefin/sitafe_produto_sefin*.parquet`
- `cfop/` -> `references/fiscal/cfop.*`
- `cst/` -> `references/fiscal/cst.*`

### Documentos e eventos
- `NFe/` -> bronze de NFe
- `NFE_eventos/` -> bronze de eventos por chave de acesso

### Fisconforme
- `Fisconforme/` -> SQLs, cache e templates do domínio de não atendido

## Regra de implementação

Os arquivos grandes de referência não entram no Git. O repositório versiona:
- manifests
- contratos
- loaders
- checksums
- instruções de carga
