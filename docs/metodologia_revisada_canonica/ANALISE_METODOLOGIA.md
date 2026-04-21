# Análise da metodologia MDS — inconsistências, fragilidades e correções

Este documento lista, por arquivo e de forma transversal, as inconsistências
semânticas, ambiguidades de nomenclatura e fragilidades operacionais
identificadas na metodologia original (`metodologia_mds/01..07`). Para cada
achado há (i) descrição, (ii) impacto potencial e (iii) correção proposta,
já implementada na **metodologia revisada** (`sistema_ro/metodologia_revisada/`)
e no código (`sistema_ro/src/sistema_ro/`).

---

## 1. Achados transversais

### 1.1 Codificação de `tipo_operacao` acoplada a rótulos legíveis
**Descrição.** O pipeline classifica linhas por strings como `"3 – ESTOQUE FINAL"`.
Em `01_abordagem_quantidades.md` o snippet usa hífen comum (`"3 - ESTOQUE FINAL"`),
enquanto `04_movimentacao_estoque.md` usa *en-dash* (`"3 – ESTOQUE FINAL"`).
`str.starts_with` com qualquer um dos dois separa silenciosamente as duas
grafias em dois buckets distintos.

**Impacto.** Inventários podem ser classificados como movimento físico e
corromper o saldo — o próprio invariante central da metodologia ("inventário
não altera saldo") deixa de ser garantido.

**Correção.** Introduzir um enum canônico `TipoOperacao` com código inteiro
estável (0..n) como chave de decisão. Os rótulos (localizáveis) passam a ser
apenas projeção para leitura humana. Ver `sistema_ro/src/sistema_ro/enums.py`
e o novo documento `metodologia_revisada/00_convencoes_gerais.md`.

### 1.2 Regra de sinal de `quantidade_fisica_sinalizada` não definida
**Descrição.** A metodologia descreve `quantidade_fisica_sinalizada` como
"quantidade física com sinal aplicado de acordo com `tipo_operacao`" mas
nunca lista o mapeamento. Devoluções são mencionadas informalmente.

**Impacto.** Implementações divergentes entre módulos; saldo final depende
de quem derivou o sinal.

**Correção.** Tabela explícita de sinais por `tipo_operacao` em
`00_convencoes_gerais.md`, e função única `derivar_quantidade_fisica_sinalizada`
(em `quantidades.py`) é a única fonte da verdade.

| Código | Nome                    | Sinal |
|:------:|:------------------------|:-----:|
| 0      | ESTOQUE_INICIAL         |  +1   |
| 1      | ENTRADA                 |  +1   |
| 2      | SAIDA                   |  −1   |
| 3      | ESTOQUE_FINAL           |   0   |
| 4      | DEVOLUCAO_DE_VENDA      |  +1   |
| 5      | DEVOLUCAO_DE_COMPRA     |  −1   |

### 1.3 Fórmulas de "desacobertos" invertidas em `05_tabela_periodos.md`
**Descrição.** O documento define:

```
saidas_desacobertas = max(estoque_final_declarado − saldo_final_calculado, 0)
estoque_desacoberto  = max(saldo_final_calculado − estoque_final_declarado, 0)
```

A interpretação econômica é:

- Se o **saldo calculado pelo fluxo** > **estoque declarado**, há mercadoria
  contabilizada que não existe fisicamente → **saídas não documentadas**.
- Se o **estoque declarado** > **saldo calculado**, há mercadoria física sem
  respaldo documental → **entradas não documentadas** (ou estoque
  desacoberto, dependendo da convenção).

A primeira fórmula, como está, rotula a diferença `declarado − calculado > 0`
como `saidas_desacobertas`, o que é semanticamente o oposto.

**Impacto.** Base de ICMS presumido calculada sobre o tipo errado de
divergência; `ST` zera o ICMS sobre "saídas_desacobertas" que, pela
definição invertida, seriam na verdade entradas desacobertas — exatamente as
que a ST costuma *zerar*. A inversão pode fazer o resultado parecer
aproximadamente correto em alguns casos e esconder o erro.

**Correção.** Reescritas em `metodologia_revisada/05_tabela_periodos.md` e
implementadas em `divergencias.py`:

```
saidas_desacobertas  = max(saldo_final_calculado − estoque_final_declarado, 0)
estoque_desacoberto  = max(estoque_final_declarado − saldo_final_calculado, 0)
saidas_calculadas    = estoque_inicial + entradas + entradas_desacobertas − estoque_final_declarado
                       (clamp ≥ 0; documentado como "saídas que deveriam ter ocorrido")
```

Ainda permanece mutuamente exclusivo (apenas um lado é positivo).

### 1.4 Nomenclatura inconsistente entre tabelas
**Descrição.** Mesmo conceito com nomes diferentes:

| Conceito                                  | Tab. períodos (05) | Tab. mensal (06)       | Tab. anual (07)               |
|-------------------------------------------|:-------------------|:-----------------------|:------------------------------|
| Estoque final desacoberto                 | `estoque_desacoberto`        | —                      | `estoque_final_desacoberto`   |
| Saldo materializado                       | `saldo_estoque_periodo`      | `saldo_estoque_anual`  | `saldo_estoque_anual`         |
| Entradas desacobertas granulares          | `entr_desac_periodo`         | `entr_desac_anual`     | `entr_desac_anual`            |

`06_tabela_mensal.md` também define `saldo_mes = "último saldo_estoque_anual do mês"`,
usando a coluna *anual* dentro da tabela mensal — confuso.

**Correção.** Padronização na metodologia revisada:

- sufixos `_periodo`, `_mes`, `_ano` refletem a **granularidade do valor**;
- `estoque_final_desacoberto` é o nome único (aposenta `estoque_desacoberto`);
- a tabela mensal consome `saldo_estoque_corrente` da `movimentacao_estoque`
  (coluna única de saldo cronológico, independente de granularidade).

### 1.5 Nomes de arquivos Parquet
**Descrição.** Coexistem `map_produto_agrupado_<cnpj>.parquet` e
`mapa_agrupamento_manual_<cnpj>.parquet` para estruturas relacionadas.

**Correção.** Convenção única `snake_case` + prefixo por camada:

```
map_produto_agrupado_<cnpj>.parquet          # mapeamento canônico
map_produto_agrupado_override_<cnpj>.parquet # overrides manuais
movimentacao_estoque_<cnpj>.parquet
tabela_periodos_<cnpj>.parquet
tabela_mensal_<cnpj>.parquet
tabela_anual_<cnpj>.parquet
```

### 1.6 Algoritmo de `descricao_normalizada` não especificado
**Descrição.** A geração determinística de `id_produto_agrupado_base` depende
de uma descrição normalizada que nunca é definida.

**Impacto.** Duas implementações podem gerar `base`s diferentes para o mesmo
produto → cadeia de rastreabilidade quebra em reprocessamentos.

**Correção.** `metodologia_revisada/02_agregacao_produtos.md` especifica o
algoritmo passo-a-passo (lower → strip → NFKD sem diacríticos → colapso de
espaços → remoção de tokens de embalagem regex-controlados). Implementado em
`agregacao.py::normalizar_descricao` com testes.

---

## 2. Achados por arquivo

### 2.1 `01_abordagem_quantidades.md`
- **Snippet incompleto.** O código só deriva `quantidade_fisica`; não cobre
  `quantidade_fisica_sinalizada` nem devoluções. Corrigido:
  `quantidades.py::derivar_colunas_quantidade` produz ambos.
- **Retrocompatibilidade.** O documento menciona Parquets legados sem
  `quantidade_fisica` mas não oferece função de migração. Implementada:
  `quantidades.py::normalizar_parquet_legado`.

### 2.2 `02_agregacao_produtos.md`
- **Precedência de override por `id_linha_origem`.** Precedência mais forte
  que a de `descricao_normalizada` é perigosa: `id_linha_origem` muda a cada
  reimportação se a origem não garantir estabilidade. Ajustado: a precedência
  máxima passa a ser **override por `id_produto_origem`**, que é estável; o
  override por `id_linha_origem` fica para casos excepcionais e exige flag
  `excecao_linha=True`.
- **Definição de `id_produto_origem`.** Depende de "CNPJ do emitente", que
  para NF-e de compra é do fornecedor. Padronizado em
  `00_convencoes_gerais.md`: sempre usa **CNPJ do estabelecimento declarante
  (titular do SPED)** + código do item no cadastro do titular. Em NF-e de
  compra, o código do item vem do mapeamento C170→0200 do titular, não do
  emitente.
- **Mapa de ambiguidades.** "Não resolva silenciosamente" ficou como
  princípio mas sem implementação. Adicionada função
  `agregacao.py::detectar_ambiguidades` que exporta DataFrame de quarentena.

### 2.3 `03_conversao_unidades.md`
- **Definição circular.** Diz que `item_unidades_<cnpj>.parquet` contém
  `quantidade_convertida`. Mas `quantidade_convertida = quantidade_original *
  fator_conversao`, e o fator é calculado *a partir* do arquivo. Corrigido:
  o parquet de entrada passa a conter `quantidade_original` (nome real); o
  `quantidade_convertida` só aparece em camadas posteriores.
- **Fallback por preço.** Fórmula `preco_medio_base / preco_unidade_referencia`
  é assimétrica (maior unidade no numerador gera fator > 1 corretamente, mas
  o documento não diz qual é qual). Fixado explicitamente em
  `metodologia_revisada/03_conversao_unidades.md`.
- **Fallback `1.0`.** É perigoso: silencia inconsistências. A metodologia
  revisada exige **quarentena** para o item em vez de silenciar, a menos que
  o auditor declare `fator_conversao_override = 1.0` explicitamente.

### 2.4 `04_movimentacao_estoque.md`
- **Custo médio sem fórmula.** Só menciona "método de média ponderada".
  Formalizado em `00_convencoes_gerais.md` e implementado em
  `calculo_saldo.py::custo_medio_ponderado` com devoluções de compra
  tratadas como redução de estoque pelo último custo médio, não pelo preço
  da devolução (para não distorcer média).
- **Enum `origem_evento_estoque` vs `tipo_operacao`.** Mistura conceitos.
  Separados em duas colunas independentes — `tipo_operacao` (semântica
  fiscal) e `origem_evento_estoque` (proveniência da linha no pipeline) —
  com testes garantindo compatibilidade entre os pares.

### 2.5 `05_tabela_periodos.md`
- Ver 1.3 (fórmulas de desacobertos).
- **`pme`, `pms` usam denominadores não definidos na tabela.** Os termos
  `valor_entradas_validas`, `quantidade_entradas_validas` não aparecem em
  lugar nenhum do doc. Definidos em `00_convencoes_gerais.md` e
  implementados como filtros compartilhados (`validadores.py::filtro_validas`).
- **`ST` como string livre.** Histórico textual não é parseável. Adicionada
  coluna estruturada `st_periodos: list[struct{inicio,fim,mva,aliquota}]`
  mantida em paralelo à representação textual.

### 2.6 `06_tabela_mensal.md`
- **`saldo_mes` = `saldo_estoque_anual`.** Corrigido: consome
  `saldo_estoque_corrente` da `movimentacao_estoque` e pega o **último valor
  cronológico do mês**, independente do que a camada anual fez.
- **Filtro `quantidade_fisica <= 0` em válidas.** Ambíguo. Esclarecido:
  válidas = `tipo_operacao ∈ {ENTRADA, SAIDA}` **E**
  `quantidade_fisica > 0` **E** `excluir_estoque != True` **E**
  `cfop` não é de devolução.
- **Assimetria no cálculo ICMS de entradas desacobertas.** A versão original
  só aplica MVA no fallback. Revisada: MVA só se aplica quando há ST
  vigente, e é sempre aplicado sobre o preço base — seja ele `pme` (fallback)
  ou `pms` (preferencial). Testes cobrem os dois ramos.

### 2.7 `07_tabela_anual.md`
- **Fórmulas "iguais às da tabela de períodos".** A redação delega mas ao
  mesmo tempo renomeia (`estoque_desacoberto` → `estoque_final_desacoberto`).
  Unificado pela padronização global (1.4).

---

## 3. Correções que valem ressaltar

1. Enum `TipoOperacao` com código inteiro — fim da fragilidade de string.
2. Função única para derivação de `quantidade_fisica`/`_sinalizada`.
3. Fórmulas de desacobertos semanticamente coerentes.
4. Custo médio ponderado formalizado incluindo devoluções.
5. Algoritmo de `descricao_normalizada` especificado e testado.
6. Contrato de entrada (Protocols) para fontes SQL documentado em
   `contracts/fontes.py`, permitindo plugar C170, NF-e, NFC-e e Bloco H
   sem alterar o núcleo.
7. Quarentena para ambiguidades de agrupamento e para itens sem fator de
   conversão resolvido — evita fallback silencioso a `1.0`.
8. Invariantes de integridade cobertos por testes
   (`tests/test_*.py`): inventário não altera saldo, mutual exclusion
   de desacobertos, sinal de devoluções, idempotência da normalização.
