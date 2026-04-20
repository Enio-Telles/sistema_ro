# Abordagem de quantidades — convertidas, físicas e sinalizadas

> Revisão do documento original `01_abordagem_quantidades.md`.
> Mudanças principais: decisão por enum inteiro (`tipo_operacao`), derivação
> única via função canônica e tabela explícita de sinais. Ver
> [`00_convencoes_gerais.md`](00_convencoes_gerais.md) §1 e §2.

## Objetivo

Separar três visões da mesma quantidade física:

- a **declarada no documento** (`quantidade_convertida`, já na unidade de referência);
- a **fisicamente movimentada** (`quantidade_fisica`, que zera em inventários);
- a **movimentação com sinal** (`quantidade_fisica_sinalizada`, que entra no
  saldo cronológico).

## Campos

| Campo                          | Descrição |
|:-------------------------------|:----------|
| `quantidade_original`          | Quantidade tal como extraída da fonte, na unidade original. |
| `quantidade_convertida`        | `quantidade_original * fator_conversao`. Permanece preenchida em inventários para conferência. |
| `quantidade_fisica`            | `quantidade_convertida` para movimentos; `0` para `tipo_operacao == ESTOQUE_FINAL`. |
| `quantidade_fisica_sinalizada` | `quantidade_fisica * sinal(tipo_operacao)`. Usada no saldo cronológico. |
| `estoque_final_declarado`      | Quantidade convertida da linha, preenchida apenas quando `tipo_operacao == ESTOQUE_FINAL`; `0` caso contrário. |

## Regras de derivação

Uma única função (`quantidades.derivar_colunas_quantidade`) produz os quatro
campos derivados (`quantidade_fisica`, `quantidade_fisica_sinalizada`,
`estoque_final_declarado`) a partir de `quantidade_convertida` e
`tipo_operacao`. Sinais estão em `00_convencoes_gerais.md §1`.

Pseudo-código (Polars):

```python
sinais = pl.col("tipo_operacao").replace_strict(
    {0: 1.0, 1: 1.0, 2: -1.0, 3: 0.0, 4: 1.0, 5: -1.0},
    return_dtype=pl.Float64,
)

df = (
    df.with_columns([
        pl.when(pl.col("tipo_operacao") == 3)
          .then(pl.lit(0.0))
          .otherwise(pl.col("quantidade_convertida").cast(pl.Float64).fill_null(0.0))
          .alias("quantidade_fisica"),
        pl.when(pl.col("tipo_operacao") == 3)
          .then(pl.col("quantidade_convertida").cast(pl.Float64))
          .otherwise(pl.lit(0.0))
          .alias("estoque_final_declarado"),
    ])
    .with_columns(
        (pl.col("quantidade_fisica") * sinais).alias("quantidade_fisica_sinalizada")
    )
)
```

## Compatibilidade retroativa

Parquets gerados antes da introdução de `quantidade_fisica` /
`quantidade_fisica_sinalizada` podem ser migrados em tempo de leitura pela
função `quantidades.normalizar_parquet_legado`, que adiciona as colunas
ausentes executando a derivação acima.

## Invariantes testáveis

1. **Inventário não altera saldo.** Para qualquer DataFrame,
   `sum(quantidade_fisica_sinalizada)` independe da presença de linhas com
   `tipo_operacao == ESTOQUE_FINAL`.
2. **Devolução inverte sinal.** Para uma devolução de compra sobre N
   unidades, `quantidade_fisica_sinalizada = -N`.
3. **`estoque_final_declarado` só em inventário.** Em linhas com
   `tipo_operacao != ESTOQUE_FINAL`, `estoque_final_declarado == 0`.
4. **Auditoria preservada.** `quantidade_convertida` nunca é modificada pela
   derivação.
