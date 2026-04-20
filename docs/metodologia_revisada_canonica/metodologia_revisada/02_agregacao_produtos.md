# Agregação de produtos

> Revisão de `02_agregacao_produtos.md`. Mudanças: algoritmo de
> `descricao_normalizada` formalizado, precedência de overrides reordenada
> (estabilidade > especificidade), mapeamento de CNPJ padronizado no §3 de
> [`00_convencoes_gerais.md`](00_convencoes_gerais.md).

## Objetivo

Agrupar itens fiscalmente idênticos (mesmo NCM/CEST, mesma unidade
compatível, mesma "descrição canônica") em um `id_produto_agrupado`, de
forma determinística, auditável e reversível.

## Cadeia de chaves

```
linha original → id_linha_origem
                → id_produto_origem              (estável, baseada em CNPJ do titular)
                → id_produto_agrupado_base       (determinístico por descrição normalizada + NCM/CEST/unidade)
                → id_produto_agrupado            (base OR override manual)
```

## Algoritmo de `descricao_normalizada`

A função `agregacao.normalizar_descricao(s: str) -> str` aplica, nesta ordem:

1. `s.strip()` — recorta espaços.
2. `s.casefold()` — minúsculas Unicode-aware.
3. `unicodedata.normalize("NFKD", s)` + remoção de marcas diacríticas.
4. Substitui qualquer sequência de caracteres não alfanuméricos por um único
   espaço.
5. Remove tokens de embalagem/unidade redundantes via regex configurável
   (default: `\b\d+\s?(ml|l|g|kg|un|und|unid|cx|pct|pct)\b`).
6. Colapsa múltiplos espaços e recorta de novo.

Os passos são idempotentes (aplicar duas vezes gera o mesmo resultado) e a
função é coberta por testes.

## `id_produto_agrupado_base`

```
id_produto_agrupado_base = hashlib.sha1(
    f"{descricao_normalizada}|{ncm}|{cest or ''}|{unidade_norm}".encode("utf-8")
).hexdigest()[:16]
```

- Determinístico.
- Independe de CNPJ — o mesmo produto em estabelecimentos distintos recebe
  a mesma `base`.
- `unidade_norm` segue a tabela de `03_conversao_unidades.md`.

## Precedência de overrides

A ordem (primeira regra aplicável vence) é:

1. **override por `id_produto_origem`** — mapeia chave estável do produto
   no titular. **Prioridade máxima.**
2. **override por `id_linha_origem`** — apenas se a linha tiver
   `excecao_linha=True` explícito. Utilizado para corrigir a classificação
   de uma única linha sem afetar o produto inteiro.
3. **override por `descricao_normalizada` unívoca** — só se não houver
   ambiguidade.
4. **automático via `id_produto_agrupado_base`**.

A motivação da reordenação: `id_linha_origem` pode mudar entre cargas se a
fonte não garantir PKs estáveis; `id_produto_origem` é sempre estável porque
é derivado do cadastro do titular.

## Critérios de elegibilidade

Dois itens só podem compartilhar `id_produto_agrupado` se:

1. mesmo NCM (8 dígitos);
2. mesmo CEST (ou ambos vazios);
3. unidades de medida **fisicamente compatíveis** (mesmo "grupo físico",
   ex.: massa, volume, unidade discreta) e com fator de conversão conhecido.

Itens que violem (1) ou (2) nunca são agregados automaticamente. Se houver
insistência via override manual, a ferramenta de validação registra um
aviso auditável.

## Ambiguidades e quarentena

- `id_produto_origem` mapeando para múltiplas `descricao_normalizada`
  inconsistentes → linha exportada para `quarentena_produtos_origem.parquet`
  com motivo `id_produto_origem_multivalorado`.
- `descricao_normalizada` mapeando para múltiplos NCM → motivo
  `descricao_com_ncm_divergente`.

A quarentena é gerada por `agregacao.detectar_ambiguidades` e deve ser
revisada pelo auditor **antes** da geração da `movimentacao_estoque`. O
pipeline falha se houver itens em quarentena não resolvidos (em vez de
silenciosamente agregar).

## Tabelas produzidas

- `mapeamentos/map_produto_agrupado_<cnpj>.parquet` —
  vincula `id_produto_origem → id_produto_agrupado`.
- `mapeamentos/map_produto_agrupado_override_<cnpj>.parquet` —
  overrides manuais, com `versao_agrupamento` e justificativa.
- `cadastros/tabela_mestre_produtos_agrupados_<cnpj>.parquet` —
  atributos padrão do grupo (descrição padrão, NCM, CEST, unidade de
  referência, `origem_agrupamento`, `qtd_descricoes_grupo`).

## Integridade

- Nunca quebrar a cadeia `id_linha_origem → id_produto_agrupado`.
- Sempre registrar `versao_agrupamento` ao aplicar override.
- Nunca resolver silenciosamente: quarentena é obrigatória.
