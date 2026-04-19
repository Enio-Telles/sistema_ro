# Agregação v2 — regra operacional

## Regra funcional adotada

A agregação automática deve ocorrer **estritamente por igualdade de descrição normalizada**.

### Descrição normalizada
A normalização usada nesta versão considera:
- conversão para maiúsculas;
- remoção de acentos;
- remoção de espaços em branco antes e depois;
- compressão de espaços internos repetidos.

Exemplo:
- `" Arroz Tipo 1 "` -> `"ARROZ TIPO 1"`
- `"arroz   tipo 1"` -> `"ARROZ TIPO 1"`
- `"Óleo  de soja"` -> `"OLEO DE SOJA"`

## Identificação do produto

Mesmo quando o agrupamento automático é por descrição, o sistema mantém a lista de atributos observados no grupo:
- código do produto
- descrição
- descrição complementar
- tipo item
- NCM
- CEST
- GTIN
- unidade

Esses atributos não mudam a regra de agrupamento automático nesta versão; eles servem para rastreabilidade e revisão manual.

## Regra manual

Produtos com descrições diferentes **não devem ser agregados automaticamente**.
Qualquer agregação entre descrições diferentes deve ocorrer por mapa manual (`mapa_manual_df`).

## Saídas principais

A agregação v2 gera:
- `map_produto_agrupado`
- `produtos_agrupados`
- `produtos_final`

Além do `id_agrupado` operacional, as saídas agora preservam rastreabilidade com:
- `id_agrupado_final`
- `id_agrupado_auto`
- `origem_agrupamento`
- `regra_agrupamento`
- `versao_agrupamento`

## Observação importante

Esta regra está alinhada com a diretriz funcional de que o agrupamento automático deve ser estrito por nome normalizado, enquanto todas as demais associações devem ser feitas manualmente.
