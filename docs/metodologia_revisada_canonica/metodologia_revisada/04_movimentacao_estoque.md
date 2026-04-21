# Movimentação de estoque

> Revisão de `04_movimentacao_estoque.md`. Mudanças: separação clara entre
> `tipo_operacao` e `origem_evento_estoque`, custo médio formalizado, uma
> única coluna `saldo_estoque_corrente` materializada.

## Papel da tabela

Visão cronológica e auditável de todos os eventos que impactam o estoque de
um `id_produto_agrupado`. Construída combinando:

- linhas de NF-e / NFC-e (via `contracts.FonteNFe`, `FonteNFCe`);
- linhas de C170 (via `FonteC170`);
- linhas de inventário do Bloco H (via `FonteBlocoH`);
- linhas sintéticas geradas pelo pipeline (estoque inicial derivado, fechamentos).

## Colunas

| Campo                          | Fonte          | Descrição |
|:-------------------------------|:---------------|:----------|
| `id_linha_origem`              | input          | PK física da linha na fonte |
| `id_produto_origem`            | input          | Chave produto-por-titular |
| `id_produto_agrupado`          | mapeamento     | Chave mestra do grupo |
| `data_evento`                  | input          | Timestamp do evento |
| `tipo_operacao`                | derivado/input | Enum (ver §1 de `00_convencoes_gerais.md`) |
| `origem_evento_estoque`        | derivado       | Enum de proveniência (ver §2) |
| `evento_sintetico`             | derivado       | Bool — `True` se o pipeline gerou a linha |
| `quantidade_original`          | input          | Na unidade original |
| `unidade_original`             | input          | Unidade da fonte |
| `unidade_referencia`           | catálogo       | Unidade do grupo |
| `fator_conversao`              | catálogo       | Multiplicador unidade_original→unidade_referencia |
| `quantidade_convertida`        | derivado       | `quantidade_original * fator_conversao` |
| `quantidade_fisica`            | derivado       | 0 em inventários; ver `01_abordagem_quantidades.md` |
| `quantidade_fisica_sinalizada` | derivado       | Com sinal de `tipo_operacao` |
| `estoque_final_declarado`      | derivado       | = `quantidade_convertida` só em inventários |
| `preco_item`                   | input          | Valor total na linha (positivo) |
| `cfop`                         | input          | Para identificar devoluções |
| `finnfe`                       | input (NF-e)   | Para identificar devoluções |
| `excluir_estoque`              | input/override | Linha marcada para exclusão pelo auditor |
| `saldo_estoque_corrente`       | derivado       | Saldo cronológico até esta linha |
| `custo_medio_corrente`         | derivado       | Custo médio ponderado até esta linha |
| `periodo_inventario`           | derivado       | Inteiro sequencial entre inventários |

## Geração

1. **Ingestão.** Unificar as 4 fontes (normalizando schema para o contrato
   comum). A ordem cronológica é por `data_evento`, desempatando por
   prioridade: inventário inicial (0) < entrada (1) < saída (2) < inventário
   final (3) no mesmo dia.
2. **Mapeamento.** Aplicar `map_produto_agrupado` e overrides.
3. **Conversão.** Calcular `quantidade_convertida` (ver doc 03).
4. **Derivação de quantidades.** Função canônica
   (`quantidades.derivar_colunas_quantidade`).
5. **Saldo cronológico e custo médio.** `calculo_saldo.aplicar_saldo_e_custo`
   percorre cada grupo em ordem cronológica.
6. **Período de inventário.** Incrementa `periodo_inventario` a cada linha
   com `tipo_operacao == ESTOQUE_INICIAL` (inclusive sintéticas).
7. **Validação.** `validadores.checar_movimentacao` — integridade de chaves,
   quarentena pendente, saldo não explode, etc.

## Regras de cálculo

- **Saldo.** `saldo_estoque_corrente[i] = saldo_estoque_corrente[i-1] +
  quantidade_fisica_sinalizada[i]`, por grupo.
- **Custo médio.** Ver `00_convencoes_gerais.md §6`.
- **Devoluções.**
  - Devolução de venda (`tipo_operacao = 4`): soma no saldo
    (`quantidade_fisica_sinalizada > 0`) mas o preço **não** recomputa
    custo médio (é retorno de mercadoria já saída).
  - Devolução de compra (`tipo_operacao = 5`): subtrai do saldo, avaliada
    pelo **custo médio corrente** para não distorcer o PME.

## Controle de unidades

Cada linha usa `unidade_original` e `fator_conversao` próprios; após
conversão, todas as quantidades compartilham a `unidade_referencia` do
grupo. Linhas com `fator_conversao = NULL` **não entram** na movimentação
(vão para quarentena de conversão).

## Integridade

- `quantidade_original`, `qtd`, `prod_qcom`, `prod_qtrib` — preservadas para
  auditoria, mesmo sem uso direto.
- Linhas sem `id_produto_agrupado` vão para `quarentena_mapeamento.parquet`.
- A geração da tabela é idempotente quando a mesma combinação de fontes +
  mapeamentos + overrides é fornecida.
