# Plano Integrado — Docs, Estoques e References

## Objetivo

Consolidar em um único ponto o que está distribuído em:

- `docs/01_plano_fases_01_a_04.md`
- `docs/02_plano_fases_05_a_08.md`
- `docs/03_plano_fases_09_a_12.md`
- `docs/04_plano_fases_13_a_16.md`
- `docs/11_todo_atualizado.md`
- `docs/13_status_revisado_implementacao.md`
- `docs/16_referencias_e_parquets_operacao.md`
- `docs/24_plano_estabilidade_funcional.md`
- `docs/estoques/*`
- `references/README.md`
- `references/manifest_fontes.md`

O foco é transformar esses documentos em backlog operacional coerente com o estado atual do código.

## Síntese consolidada

### Fases 01 a 06

- `references/` no Git é fonte de manifesto, contratos e instruções de carga.
- `workspace/references/` em runtime continua sendo obrigatório para o enriquecimento SEFIN.
- a silver com SEFIN já existe como superfície operacional em `runtime_silver_v2`;
- o backlog remanescente dessa faixa é reduzir lacunas de vigência tributária no consumo do gold.

### Fases 07 e 08

Os documentos de estoque convergem em quatro contratos centrais:

1. `mov_estoque` deve preservar inventário auditável com distinção entre saldo calculado e estoque final declarado;
2. `periodo_inventario` deve ser eixo real de recomposição e auditoria;
3. `aba_periodos` deve carregar janela temporal explícita do período;
4. tabelas anual/períodos devem preferir a quantidade declarada auditável do inventário final.

### Fases 09 a 13

- a trilha operacional de API já foi consolidada em `silver_v2`, `current-v2`, `current-v5` e `main`;
- status e overview já apontam para referências, preparo silver com SEFIN e gold oficial;
- o backlog mais relevante saiu de “abrir novas superfícies” e voltou para corretude de domínio, especialmente estoque e vigência SEFIN.

## Gaps identificados ao cruzar documentos com o código

### Já fechados nesta entrega

- `mov_estoque_v2` agora materializa `__qtd_decl_final_audit__`, alinhando o nome do contrato documental ao dataset operacional;
- `aba_anual_v4` e `aba_periodos_v4` passam a preferir `__qtd_decl_final_audit__` quando a coluna estiver disponível;
- `aba_periodos_v4` agora materializa `data_inicio`, `data_fim` e `periodo_label`.
- `aba_periodos_v4` agora também consegue resolver ST/alíquota/MVA por interseção temporal com `sitafe_produto_sefin_aux` quando a referência é injetada pela trilha oficial do gold.
- `aba_mensal_v4` e `aba_anual_v4` passam a usar a mesma referência oficial para resolver ST/alíquota/MVA pelas janelas mensal e anual, com fallback conservador para os atributos propagados da `mov_estoque`.

### Ainda pendentes

- expandir a mesma resolução temporal de vigência para as visões mensal e anual;
- revisar refinamentos da regra de ST depois da janela temporal já materializada em mensal/anual/períodos;
- reforçar neutralizações e bordas de inventário no cálculo de `mov_estoque`;
- aproximar `saidas_desacob` e `estoque_final_desacob` das trilhas documentais mais completas do legado.

## Backlog integrado revisado

### Prioridade 1 — vigência SEFIN no eixo temporal

- usar `data_inicio`/`data_fim` da `aba_periodos` como base para interseção com vigências SEFIN;
- substituir heurística “qualquer `it_in_st` no período” por resolução temporal do período;
- expor diagnóstico de vigência aplicada no status do gold quando houver diferença entre fallback e vigência resolvida.

### Prioridade 2 — estoque auditável

- revisar `0 - ESTOQUE INICIAL` e `3 - ESTOQUE FINAL` com casos dirigidos de reinício;
- endurecer divergências de inventário no `mov_estoque`;
- ampliar testes de fronteira para múltiplos inventários por `id_agrupado`.

### Prioridade 3 — observabilidade de contratos

- refletir contratos de inventário/período no manifesto de datasets;
- ampliar checks de consistência para `aba_periodos`;
- reportar ausência de `aba_periodos` e divergências de inventário no status operacional.

## Decisão de implementação desta rodada

Para manter risco baixo e aderência alta aos documentos:

1. consolidar o plano em `docs` em vez de abrir um novo roadmap paralelo;
2. implementar primeiro o contrato de inventário/período já descrito nos documentos de estoque;
3. deixar os refinamentos adicionais de ST e os testes de regressão ampliados como próxima fatia.
