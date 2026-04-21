# Conversão de unidades

> Revisão de `03_conversao_unidades.md`. Mudanças: nome do campo de entrada
> `quantidade_original` (não mais `quantidade_convertida`); fórmula explícita
> de fallback por preço; quarentena no lugar de fallback silencioso.

## Objetivo

Expressar todas as quantidades e valores de um `id_produto_agrupado` em uma
**unidade de referência** comum, preservando overrides do auditor e rastreando
a origem de cada fator.

## Entradas

| Arquivo                               | Campos relevantes                                     |
|:--------------------------------------|:------------------------------------------------------|
| `item_unidades_<cnpj>.parquet`        | `quantidade_original`, `unidade_original`             |
| `produtos_final_<cnpj>.parquet`       | catálogo: código, NCM, unidade cadastrada             |
| `descricao_produtos_<cnpj>.parquet`   | descrição e unidades utilizadas                       |
| `map_produto_agrupado_<cnpj>.parquet` | `id_produto_origem → id_produto_agrupado`             |

**Vínculo preferencial:** `descricao_produtos → map_produto_agrupado`.
Fallback para `produtos_final` só quando não houver correspondência.

## Escolha da unidade de referência

Por ordem de precedência (primeira não-nula vence):

1. `unidade_referencia_override` (manual);
2. `unidade_referencia_sugerida` (da camada de agregação — tipicamente a
   unidade com maior volume movimentado);
3. `unidade_referencia_auto` (automática, com coerência física: massa com
   massa, volume com volume).

O valor final é guardado em `unidade_referencia`.

## Cálculo do fator de conversão

`fator_conversao` é tal que `quantidade_original * fator_conversao` produz a
quantidade na `unidade_referencia`. Precedência de origem:

| Prioridade | `fator_conversao_origem` | Critério |
|:----------:|:-------------------------|:---------|
| 1          | `manual`                 | `fator_conversao_override` preenchido pelo auditor. |
| 2          | `fisico`                 | Equivalência física declarada (ex.: 500 ml = 0,5 L → fator 0,5). |
| 3          | `catalogo`               | Ficha técnica / catálogo do fabricante. |
| 4          | `preco`                  | Fallback por preço médio (ver abaixo). |
| 5          | `quarentena`             | Item sem informação suficiente. `fator_conversao` = `NULL` e o item é excluído do pipeline até resolução. |

### Fallback por preço — fórmula explícita

Dado o grupo `id_produto_agrupado` com unidade de referência `u_ref`:

```
preco_medio_por_unidade_original    = soma(valor_entradas) / soma(quantidade_original)   [na unidade original]
preco_medio_por_unidade_referencia  = soma(valor_entradas) / soma(quantidade_convertida) [no grupo, u_ref]
fator_conversao_preco               = preco_medio_por_unidade_original / preco_medio_por_unidade_referencia
```

Só aplicável se o grupo já tiver ao menos um item com `fator_conversao`
conhecido (para existir `preco_medio_por_unidade_referencia`). Caso contrário,
vai para quarentena.

### Política anti-fallback-silencioso

A metodologia anterior permitia `fator_conversao = 1.0` como último recurso.
**Isso é proibido.** Itens sem informação vão para quarentena com
`fator_conversao_origem = 'quarentena'` e não participam dos cálculos até o
auditor decidir.

## Reconciliação

Em reprocessamentos:

- Overrides manuais **nunca** são sobrescritos automaticamente.
- Ao migrar fatores entre versões de agrupamento, verificar igualdade de
  `id_produto_agrupado` **e** `unidade_referencia`. Se algum mudar, descartar
  o fator e registrar log.
- `fator_conversao_origem` sempre preenchido.

## Uso a jusante

- `movimentacao_estoque`: calcula `quantidade_convertida = quantidade_original
  * fator_conversao`.
- Tabelas mensal/periodos/anual: harmonizam médias e bases.
