# Tabela de períodos

> Revisão de `05_tabela_periodos.md`. Mudanças críticas: **fórmulas de
> desacobertos reescritas** para que `saidas_desacobertas` represente, de
> fato, saídas não documentadas. Uniformização com `estoque_final_desacoberto`.

## Identificação fiscal (SITAFE)

Cada `id_produto_agrupado` ganha `co_sefin` pela precedência
`CEST + NCM → CEST → NCM` na etapa `item_unidades`.

## Objetivo

Para cada `(id_produto_agrupado, periodo_inventario)` a tabela confronta:

- saldo inicial do período;
- entradas e saídas físicas no período;
- entradas desacobertas (derivadas linha a linha na `movimentacao_estoque`);
- estoque final declarado no inventário que encerra o período;
- saldo final calculado pelo fluxo;
- divergências finais (saídas desacobertas **ou** estoque final desacoberto);
- bases e valores de ICMS presumidos.

## Campos

### Identificação

| Campo                | Tipo | Descrição |
|:---------------------|:-----|:----------|
| `codigo_periodo`     | int  | = `periodo_inventario` |
| `periodo_label`      | str  | `DD/MM/AAAA até DD/MM/AAAA` |
| `data_inicio`        | date | Primeiro dia do período |
| `data_fim`           | date | Último dia do período |
| `id_produto_agrupado`| str  | Chave mestra |
| `descricao_padrao`   | str  | Descrição do grupo |
| `unidade_referencia` | str  | Unidade final |

### Quantidades (na `unidade_referencia`)

| Campo                         | Origem | Descrição |
|:------------------------------|:-------|:----------|
| `estoque_inicial_periodo`     | mov    | Soma de `quantidade_fisica` com `tipo_operacao = ESTOQUE_INICIAL` |
| `entradas_periodo`            | mov    | Soma de `quantidade_fisica` de ENTRADA (cód 1) |
| `saidas_periodo`              | mov    | Soma de `|quantidade_fisica_sinalizada|` de SAIDA (cód 2) |
| `devolucoes_venda_periodo`    | mov    | Soma de `quantidade_fisica` de DEVOLUCAO_DE_VENDA |
| `devolucoes_compra_periodo`   | mov    | Soma de `|quantidade_fisica_sinalizada|` de DEVOLUCAO_DE_COMPRA |
| `estoque_final_declarado_periodo` | mov | Soma de `estoque_final_declarado` das linhas `ESTOQUE_FINAL` do período |
| `entradas_desacobertas_periodo`   | div | Soma de `entr_desac_corrente` do período (derivada na movimentação) |
| `saldo_final_calculado_periodo`   | mov | Último `saldo_estoque_corrente` antes do inventário que encerra o período |

### Divergências (corrigidas)

```
saidas_calculadas_periodo  = max(
    estoque_inicial_periodo + entradas_periodo + entradas_desacobertas_periodo
    - estoque_final_declarado_periodo,
    0
)

saidas_desacobertas_periodo = max(
    saldo_final_calculado_periodo - estoque_final_declarado_periodo,
    0
)

estoque_final_desacoberto_periodo = max(
    estoque_final_declarado_periodo - saldo_final_calculado_periodo,
    0
)
```

**Invariante:** `saidas_desacobertas_periodo` e
`estoque_final_desacoberto_periodo` são mutuamente exclusivos
(apenas um é positivo).

**Mudança semântica vs. versão antiga.** Na versão original, os dois campos
estavam trocados. A nova definição alinha com o significado econômico:

- `saldo_calculado > declarado` → calculamos mercadoria que não está no
  estoque físico → **saídas não documentadas**.
- `declarado > saldo_calculado` → há mercadoria física a mais que o fluxo
  justifica → **estoque desacoberto** (entradas não documentadas que não
  foram promovidas a `entradas_desacobertas` no fluxo).

### Preços médios e alíquotas

| Campo              | Descrição |
|:-------------------|:----------|
| `pme_periodo`      | `sum(valor_entradas_validas_periodo) / sum(quantidade_entradas_validas_periodo)` — ver `00_convencoes_gerais.md §7` |
| `pms_periodo`      | análogo para saídas |
| `aliquota_interna` | Do SITAFE (por co_sefin); fallback = última alíquota movimentada |
| `st_texto`         | Representação textual (legado) |
| `st_periodos`      | `list[struct{inicio, fim, mva, aliquota}]` — parseável |

### Bases e ICMS

```
if pms_periodo > 0:
    base_saida   = saidas_desacobertas_periodo * pms_periodo
    base_estoque = estoque_final_desacoberto_periodo * pms_periodo
else:
    base_saida   = saidas_desacobertas_periodo * pme_periodo * 1.30
    base_estoque = estoque_final_desacoberto_periodo * pme_periodo * 1.30

icms_saidas_desacobertas_periodo  = base_saida   * aliquota_interna / 100
icms_estoque_final_desacoberto_periodo = base_estoque * aliquota_interna / 100

if st_vigente(data_fim, st_periodos):
    icms_saidas_desacobertas_periodo = 0.0
    # ICMS sobre estoque final desacoberto é mantido.
```

## Arredondamento

Ver `00_convencoes_gerais.md §5`.

## Diferenças vs tabela anual

| Aspecto                | Tabela anual              | Tabela de períodos                 |
|:-----------------------|:--------------------------|:-----------------------------------|
| Unidade de agrupamento | Ano civil (`ano`)         | Período de inventário (`codigo_periodo`) |
| Sufixo                 | `_ano`                    | `_periodo`                         |
| Granularidade          | 1 linha por produto/ano   | 1 linha por produto/período        |
| Uso                    | Auditoria consolidada     | Auditoria fiscal customizada       |

## Saída

`dados/CNPJ/<cnpj>/analises/produtos/tabela_periodos_<cnpj>.parquet`.
