# Plano Integrado - Docs, Estoques e References

## Objetivo

Concentrar em um unico ponto o backlog que estava espalhado entre:

- planos de fases;
- status revisado;
- docs de estoque;
- docs de referencias;
- plano de estabilidade funcional.

O objetivo aqui nao e criar outro roadmap, e sim registrar o que ja foi fechado e o que ainda falta no eixo estoque + SEFIN.

## Sintese consolidada

### O que ja esta consolidado

- `references/` no Git permanece como manifesto e contrato; `workspace/references/` continua obrigatorio em runtime;
- `runtime_silver_v2`, `current-v2`, `current-v5` e `main` ja formam a trilha operacional principal;
- o backlog principal saiu de "abrir superficies" e voltou para corretude de dominio.

### Contratos centrais de estoque

Os documentos de estoque convergem nestes contratos:

1. `mov_estoque` precisa distinguir saldo calculado de inventario final declarado;
2. `periodo_inventario` deve ser eixo real de auditoria;
3. `aba_periodos` deve carregar janela temporal explicita;
4. anual e periodos devem preferir a quantidade auditavel do inventario final;
5. a vigencia SEFIN deve ser resolvida por janela temporal, nao por heuristica solta.

## O que ja foi fechado

- `mov_estoque` materializa `__qtd_decl_final_audit__`;
- `aba_anual_v4` e `aba_periodos_v4` preferem a quantidade declarada auditavel;
- `aba_periodos_v4` expone `data_inicio`, `data_fim` e `periodo_label`;
- `aba_mensal_v4`, `aba_anual_v4` e `aba_periodos_v4` resolvem ST/aliquota/MVA por interseccao temporal quando `sitafe_produto_sefin_aux` esta disponivel;
- o gold oficial informa disponibilidade da vigencia temporal em runtime, cobertura efetiva por aba e motivos de nao cobertura.

## O que ainda falta

### Prioridade 1 - corretude de estoque

- reforcar bordas de `0 - ESTOQUE INICIAL` e `3 - ESTOQUE FINAL`;
- endurecer divergencias de inventario em `mov_estoque`;
- ampliar testes com multiplos inventarios por `id_agrupado`.

### Prioridade 2 - corretude fiscal derivada

- revisar `saidas_desacob` e `estoque_final_desacob` com casos dirigidos;
- continuar refinando ST apenas quando houver ganho funcional claro;
- validar melhor os casos em que a vigencia resolvida diverge do fallback do movimento.

### Prioridade 3 - observabilidade

- refletir os contratos de inventario e periodo no manifesto de datasets;
- ampliar checks de consistencia para `aba_periodos`;
- levar sinais de cobertura temporal parcial para status operacional mais resumido quando fizer sentido.

## Decisao de planejamento

Para manter o plano simples e util:

1. `docs/24_plano_estabilidade_funcional.md` fica como plano principal;
2. este documento fica como consolidacao tematica de estoque + referencias;
3. novas entregas nesse eixo devem priorizar corretude e observabilidade, nao nova superficie.
