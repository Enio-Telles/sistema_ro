# Pipeline do sistema_ro

## Camadas

### Bronze
- executa SQLs core com filtros por contribuinte e período
- persiste extrações cruas por domínio
- preserva chaves físicas e datas originais

### Silver
- normaliza tipos, datas e chaves
- gera `id_linha_origem`
- gera `codigo_fonte`
- deduplica itens e documentos
- harmoniza campos entre EFD, NFe, NFCe e Fisconforme

### Gold
- constrói `mercadoria_id` e `apresentacao_id`
- executa agregação automática e manual
- calcula fatores de conversão
- constrói `mov_estoque`
- deriva mensal, anual, períodos e datasets de Fisconforme

## Domínios
- `pipeline/extraction`
- `pipeline/normalization`
- `pipeline/mercadorias`
- `pipeline/conversao`
- `pipeline/estoque`
- `pipeline/fisconforme`

## Regra principal

Estoque, agregação e conversão devem usar a mesma cadeia de rastreabilidade de mercadoria.
Qualquer perda de `id_linha_origem`, `codigo_fonte` ou `id_agrupado` é falha crítica de pipeline.
