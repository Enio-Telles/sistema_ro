# Plano de Correção — Agregação, Conversão e Estoque

## Objetivo

Consolidar um plano técnico executável para corrigir divergências entre documentação, implementação real, contratos de Parquet, API e testes nos três eixos centrais do domínio fiscal orientado a mercadorias:

1. agregação de mercadorias/produtos
2. conversão de unidades
3. movimentação e estoque

O foco é fortalecer corretude funcional, rastreabilidade, preservação de decisões manuais e observabilidade, sem romper a trilha oficial atual:

```text
mdc_base -> agregacao -> fontes_agr validadas -> gold_v20 -> checagem pos-gold
```

## Escopo

### Trilha oficial alvo

- runtime oficial: `backend/app/runtime_gold_current_v2.py`
- alias operacional: `/api/current-v2`
- execução do pipeline: `backend/app/services/pipeline_exec_gold_v20.py`
- pipeline gold principal: `pipeline/run_gold_v20.py`

### Trilhas legadas a tratar

- `backend/app/runtime_main_v4.py`
- `backend/app/services/pipeline_exec_v8_service.py`
- `backend/app/services/pipeline_service_v6.py`
- `pipeline/run_cnpj_v6.py`

## Diagnóstico resumido

### 1. Agregação

Problemas principais:

- documentação canônica mais madura do que a implementação realmente executada
- ausência de `versao_agrupamento` no caminho ativo
- ausência de snapshot, merge/unmerge e histórico transacional real
- heurística automática baseada em descrição normalizada sem remoção explícita de acentos
- falta de materialização de casos ambíguos para auditoria

### 2. Conversão

Problemas principais:

- documentação descreve método antigo, diferente do motor atual (`item_unidades_v3` + `fatores_v4`)
- mistura entre heurística, diagnóstico, fator estrutural e override manual sem separação forte no output final
- `apply_manual_overrides` aplica override por `id_agrupado`, com risco de contaminar múltiplas unidades do mesmo agrupamento
- ausência de trilha explícita do fator heurístico original versus fator final

### 3. Estoque

Problemas principais:

- `mov_estoque_v2` ainda achata fatores por `id_agrupado` em pontos críticos, quando a granularidade natural é `id_agrupado + unid`
- cobertura forte nos derivados fiscais, mas fraca na integração `fatores_conversao -> mov_estoque`
- documentação de `mov_estoque` mais ampla do que a lógica claramente visível no código ativo

### 4. Contratos e observabilidade

Problemas principais:

- `parquets/contratos/*.md` ainda são referência placeholder
- persistência gold sem `run_id`, `input_hash`, `data_processamento` e versionamento de schema de forma auditável no payload operacional
- pouca visibilidade sobre reprocessamento com ativos manuais

---

## Decisões arquiteturais

### D1. Tornar `current-v2/gold_v20` a única trilha oficial

A superfície operacional e de frontend deve considerar apenas:

- `backend/app/runtime_gold_current_v2.py`
- `backend/app/services/pipeline_exec_gold_v20.py`
- `pipeline/run_gold_v20.py`

As trilhas legadas devem permanecer apenas como histórico ou fallback explicitamente rotulado, sem ambiguidade operacional.

### D2. Separar decisão heurística de decisão manual

Toda saída de agregação e conversão deve distinguir:

- valor heurístico original
- valor final aplicado
- tipo da decisão final
- origem da decisão final
- existência de intervenção manual

### D3. Preservar granularidade mínima correta

Nos pontos que afetam conversão e estoque, a granularidade padrão deve ser:

```text
id_agrupado + unid
```

Nunca reduzir para apenas `id_agrupado` quando a regra de negócio depender da unidade original.

### D4. Materializar auditoria em Parquet

Casos ambíguos, conflituosos ou descartados devem produzir datasets auxiliares persistidos, não apenas warnings em memória.

---

## Plano por fases

## Fase 1 — Governança da trilha oficial

### Objetivo

Eliminar ambiguidade entre trilha oficial e trilhas legadas.

### Arquivos alvo

- `backend/app/runtime_main_v4.py`
- `backend/app/services/pipeline_exec_v8_service.py`
- `backend/app/services/pipeline_service_v6.py`
- `docs/26_runtime_oficial_gold_v20.md`
- `docs/30_superficies_em_uso_agora.md`

### Ações

1. rotular explicitamente `main4/v6` como legado
2. manter `current-v2/gold_v20` como único caminho recomendado
3. registrar de forma central a matriz de superfícies em uso
4. incluir aviso de depreciação nas superfícies legadas

### Critérios de aceite

- nenhuma documentação principal trata `main4/v6` como runtime recomendada
- frontend continua apontando para `/api/current-v2`
- testes de superfícies oficiais permanecem verdes

---

## Fase 2 — Fortalecimento da agregação

### Objetivo

Elevar a implementação real de agregação ao nível de rastreabilidade já exigido pela documentação do domínio.

### Arquivos alvo

- `pipeline/mercadorias/aggregation_v2.py`
- `pipeline/mercadorias/mercadoria_pipeline_v2.py`
- `pipeline/mercadorias/grouping.py`
- `pipeline/manual_map_contract.py`
- `pipeline/run_gold_v20.py`

### Ações

#### 2.1. Normalização mais robusta

Em `pipeline/mercadorias/aggregation_v2.py`:

- substituir a normalização atual por uma rotina compartilhada que remova acentos
- manter upper/strip/colapso de espaços
- preservar o valor original para auditoria

#### 2.2. Colunas de proveniência da decisão

Adicionar aos outputs da agregação:

- `id_agrupado_auto`
- `id_agrupado_final`
- `origem_agrupamento`
- `regra_agrupamento`
- `manual_override_aplicado`
- `versao_agrupamento`

#### 2.3. Auditoria de ambiguidade

Gerar dataset auxiliar com grupos que apresentem sinais de ambiguidade, por exemplo:

- mesma `descricao_normalizada` com múltiplos NCM/CEST fortemente divergentes
- mesma `descricao_normalizada` com conjunto heterogêneo de unidades
- alta dispersão de GTIN

#### 2.4. Contrato do mapa manual

Em `pipeline/manual_map_contract.py`:

- manter obrigatórios:
  - `codigo_fonte`
  - `id_agrupado_manual`
- validar recomendados:
  - `regra_id`
  - `usuario`
  - `motivo`
  - `created_at`
  - `updated_at`
  - `ativo`
  - `observacao`
- validar unicidade por regra ativa

### Datasets novos sugeridos

- `gold/log_agregacao_ambiguidades`
- `gold/log_aplicacao_mapa_manual`

### Critérios de aceite

- agrupamento automático continua conservador
- mapa manual mantém precedência sem apagar o valor automático original
- saídas preservam rastreabilidade do caminho de decisão
- existe dataset persistido para ambiguidades de agrupamento

---

## Fase 3 — Separação entre heurística e override na conversão

### Objetivo

Impedir que o override manual esconda a heurística original e corrigir a granularidade de aplicação da decisão manual.

### Arquivos alvo

- `pipeline/conversao/item_unidades_v3.py`
- `pipeline/conversao/fatores_v4.py`
- `pipeline/conversao/overrides.py`
- `pipeline/conversao/structural_factors.py`
- `pipeline/run_gold_v20.py`

### Ações

#### 3.1. Preservar a trilha da heurística

Em `pipeline/conversao/fatores_v4.py`, manter explicitamente:

- `unid_ref_heuristica`
- `fator_heuristico`
- `tipo_fator_heuristico`
- `fonte_fator_heuristico`
- `confianca_fator_heuristica`
- `unid_ref_final`
- `fator_final`
- `tipo_fator_final`
- `fonte_fator_final`
- `confianca_fator_final`
- `override_aplicado`

A versão final consumida pelo estoque pode continuar usando aliases operacionais (`unid_ref`, `fator`, `tipo_fator`, `fonte_fator`), mas os campos base devem permanecer materializados.

#### 3.2. Corrigir granularidade do override

Em `pipeline/conversao/overrides.py`:

- permitir override por `id_agrupado + unid`
- aceitar fallback por `id_agrupado` apenas quando o contrato do override for explicitamente geral
- registrar qual chave foi usada na aplicação do override

#### 3.3. Diagnóstico ambíguo de conversão

Em `pipeline/conversao/item_unidades_v3.py`:

- gerar saída auxiliar quando o diagnóstico indicar sinais conflitantes para o mesmo `id_agrupado + unid`
- registrar evidência usada na definição de `unid_ref`

### Datasets novos sugeridos

- `gold/log_conversao_overrides`
- `gold/log_conversao_conflitos`
- `gold/log_diagnostico_conversao_ambiguo`

### Critérios de aceite

- override manual não contamina múltiplas unidades indevidamente
- heurística original permanece auditável após override
- conflito de diagnóstico gera log materializado

---

## Fase 4 — Correção da integração conversão -> estoque

### Objetivo

Garantir que `mov_estoque` use o fator correto na mesma granularidade da unidade original.

### Arquivos alvo

- `pipeline/estoque/mov_estoque_v2.py`
- `pipeline/estoque/mov_estoque_v3.py`
- `pipeline/estoque/resumo.py`
- `pipeline/run_gold_v20.py`

### Ações

#### 4.1. Resolver fator por chave correta

Em `pipeline/estoque/mov_estoque_v2.py`:

- substituir joins baseados em `unique(subset=["id_agrupado"])`
- usar chave mínima correta, preferencialmente:

```text
id_agrupado + unid
```

quando disponível na tabela de movimento e na tabela de fatores.

#### 4.2. Tratamento de fallback

Quando a granularidade completa não estiver disponível:

- registrar fallback em log de auditoria
- explicitar `factor_resolution_mode`
- não ocultar o caso

#### 4.3. Consistência pós-gold reforçada

Expandir checagens para detectar:

- múltiplos fatores possíveis por item de estoque
- uso de fator genérico quando existia fator por unidade
- divergências sistemáticas entre `mov_estoque` e `fatores_conversao`

### Datasets novos sugeridos

- `gold/log_mov_estoque_factor_fallback`

### Critérios de aceite

- estoque usa fator compatível com unidade original
- fallback fica explicitamente auditável
- consistência pós-gold detecta achatamento indevido

---

## Fase 5 — Metadata, lineage e contratos reais de Parquet

### Objetivo

Transformar contratos placeholder em contratos operacionais auditáveis.

### Arquivos alvo

- `pipeline/persist_gold_v2.py`
- `backend/app/services/parquet_api.py`
- `parquets/contratos/fatores_conversao_CNPJ.parquet.md`
- `parquets/contratos/mov_estoque_CNPJ.parquet.md`
- contratos equivalentes dos datasets de agregação e estoque

### Ações

#### 5.1. Metadata mínima obrigatória

Em `pipeline/persist_gold_v2.py`, persistir metadata com:

- `run_id`
- `input_hash`
- `data_processamento`
- `pipeline_version`
- `schema_version`
- `upstream_datasets`
- `manual_assets_used`
- `row_count`
- `cnpj`

#### 5.2. Exposição da metadata na API

Em `backend/app/services/parquet_api.py`, expor:

- colunas
- tipos
- metadata do parquet
- `pipeline_version`
- `schema_version`

#### 5.3. Contratos reais por dataset

Atualizar `parquets/contratos/*.md` para refletir:

- chaves funcionais
- colunas mandatórias
- colunas derivadas
- metadata mandatória
- regras de compatibilidade retroativa

### Critérios de aceite

- cada dataset gold relevante carrega metadata operacional real
- contratos md deixam de ser placeholder
- preview da API consegue informar schema e metadata básica

---

## Fase 6 — Testes e validação de regressão

### Objetivo

Cobrir os pontos de maior risco funcional e impedir regressão silenciosa.

### Testes a criar ou reforçar

#### Agregação

- `tests/test_aggregation_v2.py`
  - remoção de acentos
  - precedência do mapa manual
  - preservação de `id_linha_origem`
  - geração de log de ambiguidade

#### Conversão

- `tests/test_item_unidades_v3.py`
- `tests/test_fatores_v4.py`
- `tests/test_overrides_conversao.py`
- `tests/test_reprocessamento_preserva_overrides.py`

Casos obrigatórios:

- override por agrupamento + unidade
- override geral por agrupamento
- preservação do fator heurístico original
- reprocessamento reaplicando ajuste manual

#### Estoque

- `tests/test_mov_estoque_v3.py`
- `tests/test_mov_estoque_multi_unidade.py`

Casos obrigatórios:

- múltiplos fatores no mesmo `id_agrupado`
- uso de fator correto por unidade
- fallback auditável quando a chave completa não existe

#### Persistência e contratos

- `tests/test_persist_gold_metadata.py`
- `tests/test_gold_contracts_runtime.py`

### Critérios de aceite

- regressão coberta nos pontos críticos de granularidade
- reprocessamento preserva ativos manuais
- metadata obrigatória validada por teste

---

## Patches concretos por arquivo

## Patch set A — agregação

### `pipeline/mercadorias/aggregation_v2.py`

Implementar:

- normalização com remoção de acentos
- colunas `id_agrupado_final`, `origem_agrupamento`, `regra_agrupamento`, `manual_override_aplicado`
- geração de dataframe de ambiguidade

### `pipeline/mercadorias/mercadoria_pipeline_v2.py`

Implementar:

- `versao_agrupamento`
- retorno de logs auxiliares
- enriquecimento de `id_agrupados` com origem e versão

### `pipeline/manual_map_contract.py`

Implementar:

- validação de metadados operacionais recomendados
- validação de unicidade de regra ativa

## Patch set B — conversão

### `pipeline/conversao/item_unidades_v3.py`

Implementar:

- log de conflito de diagnóstico
- `fonte_unid_ref_sugerida`
- colunas auditáveis de evidência

### `pipeline/conversao/fatores_v4.py`

Implementar:

- separação entre colunas heurísticas e finais
- `override_aplicado`
- resolução explícita do caminho de decisão final

### `pipeline/conversao/overrides.py`

Implementar:

- join por `id_agrupado + unid` quando disponível
- fallback explícito por `id_agrupado`
- `build_override_log` persistível

## Patch set C — estoque

### `pipeline/estoque/mov_estoque_v2.py`

Implementar:

- join de fatores por granularidade correta
- `factor_resolution_mode`
- log de fallback

### `pipeline/estoque/mov_estoque_v3.py`

Implementar:

- checagens de enriquecimento fiscal sem quebrar a granularidade do fator

## Patch set D — persistência e API

### `pipeline/persist_gold_v2.py`

Implementar metadata real:

- `run_id`
- `input_hash`
- `data_processamento`
- `pipeline_version`
- `schema_version`
- `manual_assets_used`

### `backend/app/services/parquet_api.py`

Expor:

- schema
- metadata
- `pipeline_version`
- `schema_version`

### `backend/app/services/gold_consistency_service.py`

Expandir validações:

- proveniência de decisão
- fallback de fator
- presença dos logs auxiliares críticos

---

## MVP recomendado

O menor recorte com maior valor imediato é:

1. oficializar apenas `current-v2/gold_v20`
2. corrigir `pipeline/conversao/overrides.py` para granularidade por unidade
3. corrigir `pipeline/estoque/mov_estoque_v2.py` para não achatar fator por `id_agrupado`
4. adicionar metadata mínima real em `pipeline/persist_gold_v2.py`
5. criar logs Parquet para:
   - ambiguidades de agregação
   - overrides aplicados
   - conflitos de conversão
6. cobrir o recorte com testes de reprocessamento e multi-unidade

---

## Gestão no GitHub

### Branches sugeridas

- `feat/officialize-gold-v20-runtime`
- `feat/agregacao-rastreabilidade-v1`
- `feat/conversao-override-granularidade`
- `feat/estoque-factor-resolution`
- `feat/gold-metadata-lineage`
- `test/reprocessamento-manual-assets`

### Estratégia de PR

- PRs pequenas e focadas
- uma fase por PR quando possível
- draft PR para fases que mexam em múltiplas camadas
- CI obrigatória antes do merge
- revisão obrigatória para mudanças em `pipeline/conversao/*`, `pipeline/estoque/*` e `pipeline/persist_gold_v2.py`

### Checklist mínimo por PR

- corretude funcional
- impacto em rastreabilidade
- impacto em schema
- cobertura de testes
- compatibilidade com `/api/current-v2`
- observabilidade/logs adicionados ou ajustados

---

## Backlog operacional sugerido

### Issue 1

**Oficializar trilha current-v2/gold_v20 e marcar v6/main4 como legado**

### Issue 2

**Fortalecer rastreabilidade da agregação com logs e proveniência de decisão**

### Issue 3

**Separar heurística e override manual na conversão**

### Issue 4

**Corrigir resolução de fator na integração com mov_estoque**

### Issue 5

**Persistir metadata real e alinhar contratos de Parquet**

### Issue 6

**Cobrir reprocessamento, multi-unidade e ativos manuais com testes**

---

## Riscos e trade-offs

### R1. Corrigir granularidade pode alterar outputs existentes

Mitigação:

- versionar schema quando necessário
- validar comparação antes/depois em datasets reais
- registrar fallback em vez de mudar silenciosamente

### R2. Expor heurística e valor final aumenta largura dos Parquets

Mitigação:

- priorizar corretude e auditoria
- avaliar compactação e colunas opcionais depois

### R3. Descontinuar trilhas legadas pode afetar fluxos informais

Mitigação:

- manter runtime legada apenas como histórico
- documentar explicitamente que não é mais referência operacional

---

## Definição de pronto

Uma fase será considerada pronta quando:

1. código estiver na trilha oficial `current-v2/gold_v20`
2. documentação correspondente estiver alinhada
3. schema impactado estiver explicitado
4. testes cobrirem o risco principal da fase
5. observabilidade mínima estiver materializada em log/metadata

---

## Resultado esperado

Ao final das fases principais, o repositório deve operar com estas propriedades:

- uma única trilha gold oficial clara
- agregação com rastreabilidade materializada
- conversão com separação explícita entre heurística e manual
- reprocessamento preservando ativos manuais
- estoque consumindo fator na granularidade correta
- Parquets com metadata auditável
- contratos e documentação alinhados ao código real
- cobertura de testes concentrada nos riscos fiscais e operacionais mais sensíveis
