# Tabela anual

> Revisão de `07_tabela_anual.md`. Mudanças: nomenclatura alinhada à tabela
> de períodos (`estoque_final_desacoberto_ano` em vez de variantes); mesmas
> fórmulas corrigidas de divergência.

## Identificação fiscal (SITAFE)

Igual às tabelas mensal/periodos — `co_sefin` por `CEST + NCM → CEST → NCM`.

## Objetivo

Agregação anual por `(ano, id_produto_agrupado)`, consolidando:

- estoque inicial do ano;
- entradas e saídas físicas do ano;
- estoque final declarado (último inventário do ano);
- saldo final calculado pelo fluxo;
- divergências (entradas desacobertas ao longo do ano, saídas desacobertas
  e estoque final desacoberto no fechamento);
- bases e ICMS presumidos.

## Campos

### Identificação

| Campo                 | Tipo |
|:----------------------|:-----|
| `ano`                 | int  |
| `id_produto_agrupado` | str  |
| `descricao_padrao`    | str  |
| `unidade_referencia`  | str  |

### Quantidades

| Campo                              | Descrição |
|:-----------------------------------|:----------|
| `estoque_inicial_ano`              | `quantidade_fisica` das linhas `ESTOQUE_INICIAL` |
| `entradas_ano`                     | `quantidade_fisica` de ENTRADA |
| `saidas_ano`                       | `|quantidade_fisica_sinalizada|` de SAIDA |
| `devolucoes_venda_ano`             | `quantidade_fisica` de DEVOLUCAO_DE_VENDA |
| `devolucoes_compra_ano`            | `|quantidade_fisica_sinalizada|` de DEVOLUCAO_DE_COMPRA |
| `estoque_final_declarado_ano`      | `estoque_final_declarado` do último inventário do ano |
| `entradas_desacobertas_ano`        | `sum(entr_desac_corrente)` no ano |
| `saldo_final_calculado_ano`        | Último `saldo_estoque_corrente` antes do inventário de fechamento |

### Divergências (fórmulas idênticas às da tabela de períodos)

```
saidas_calculadas_ano  = max(
    estoque_inicial_ano + entradas_ano + entradas_desacobertas_ano
    - estoque_final_declarado_ano,
    0
)

saidas_desacobertas_ano      = max(saldo_final_calculado_ano - estoque_final_declarado_ano, 0)
estoque_final_desacoberto_ano = max(estoque_final_declarado_ano - saldo_final_calculado_ano, 0)
```

### Preços e ICMS

Idem tabela de períodos, com sufixo `_ano`. ST vigente no ano zera
`icms_saidas_desacobertas_ano`; ICMS sobre estoque final desacoberto
sempre permanece.

## Arredondamento

Ver `00_convencoes_gerais.md §5`.

## Saída

`dados/CNPJ/<cnpj>/analises/produtos/tabela_anual_<cnpj>.parquet`.
