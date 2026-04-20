# Tabela mensal

> Revisão de `06_tabela_mensal.md`. Mudanças: `saldo_mes` consome
> `saldo_estoque_corrente` (coluna única); filtro "válidas" padronizado;
> fórmula de ICMS sobre entradas desacobertas torna explícita a aplicação
> de MVA e a condição de ST.

## Identificação fiscal (SITAFE)

Idem `05_tabela_periodos.md`.

## Papel da tabela

Resumo por `(ano, mes, id_produto_agrupado)`. Não recalcula saldo — apenas
agrega valores da `movimentacao_estoque` no mês.

## Campos

### Identificação

| Campo                 | Tipo        | Descrição |
|:----------------------|:------------|:----------|
| `ano`                 | int         | |
| `mes`                 | int (1-12)  | |
| `id_produto_agrupado` | str         | |
| `descricao_padrao`    | str         | |
| `unidades_mes`        | list[str]   | Unidades originais do mês |
| `unidade_referencia`  | str         | Unidade única do grupo |

### Entradas e saídas

| Campo                        | Descrição |
|:-----------------------------|:----------|
| `valor_entradas_mes`         | `sum(preco_item)` de ENTRADA |
| `quantidade_entradas_mes`    | `sum(quantidade_fisica)` de ENTRADA |
| `valor_saidas_mes`           | `sum(|preco_item|)` de SAIDA |
| `quantidade_saidas_mes`      | `sum(|quantidade_fisica_sinalizada|)` de SAIDA |
| `preco_medio_entradas_mes`   | `sum(valor_entradas_validas_mes) / sum(quantidade_entradas_validas_mes)` — ver `00_convencoes_gerais.md §7` |
| `preco_medio_saidas_mes`     | análogo |

### Saldos e estoque

| Campo                  | Descrição |
|:-----------------------|:----------|
| `saldo_mes`            | Último `saldo_estoque_corrente` da `movimentacao_estoque` no mês |
| `custo_medio_mes`      | Último `custo_medio_corrente` no mês |
| `valor_estoque_mes`    | `saldo_mes * custo_medio_mes` |

### Entradas desacobertas

| Campo                            | Descrição |
|:---------------------------------|:----------|
| `entradas_desacobertas_mes`      | Soma mensal de `entr_desac_corrente` |
| `icms_entradas_desacobertas_mes` | Ver fórmula abaixo — **só** se há ST vigente no mês |

### Substituição tributária

| Campo               | Tipo   | Descrição |
|:--------------------|:-------|:----------|
| `st_texto`          | str    | Histórico textual |
| `st_periodos`       | list[struct] | Parseável |
| `sujeito_a_st`      | str    | "S"/"N" |
| `mva_original`      | float  | `it_pc_mva` da última movimentação válida do mês |
| `mva_ajustado`      | float  | Cálculo pela legislação |

## Fórmulas

### Médias

Filtros de validade em `00_convencoes_gerais.md §7`. Preço médio:

```
preco_medio_entradas_mes = soma(valor_entradas_validas) / soma(quantidade_entradas_validas)
preco_medio_saidas_mes   = soma(valor_saidas_validas)   / soma(quantidade_saidas_validas)
```

Se qualquer denominador = 0, o numerador também deve ser 0; caso contrário
registrar alerta.

### ICMS de entradas desacobertas

A regra anterior aplicava MVA só no ramo de fallback, o que é assimétrico.
A versão revisada:

```
if not st_vigente(mes, st_periodos):
    icms_entradas_desacobertas_mes = 0.0
elif entradas_desacobertas_mes <= 0:
    icms_entradas_desacobertas_mes = 0.0
elif preco_medio_saidas_mes > 0:
    # Preço de saída já embute margem → não usar MVA.
    icms_entradas_desacobertas_mes = (
        preco_medio_saidas_mes
        * entradas_desacobertas_mes
        * aliquota_interna / 100
    )
else:
    # Fallback: preço de entrada não embute margem → aplicar MVA.
    icms_entradas_desacobertas_mes = (
        preco_medio_entradas_mes
        * entradas_desacobertas_mes
        * aliquota_interna / 100
        * mva_efetivo
    )
```

`mva_efetivo` vem do MVA ajustado conforme alíquota interestadual/interna.

## Arredondamento

Ver `00_convencoes_gerais.md §5`.

## Saída

`dados/CNPJ/<cnpj>/analises/produtos/tabela_mensal_<cnpj>.parquet`.
