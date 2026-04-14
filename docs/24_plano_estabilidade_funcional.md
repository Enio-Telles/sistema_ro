# Plano de Estabilidade Funcional e Otimizacao

## Objetivo

Atualizar o plano de implementacao do `sistema_ro` com base no estado atual do repositorio e na reanalise dos projetos legados `audit_react` e `audit_pyside`, priorizando **plena funcionalidade estavel e otimizada** antes de continuar expandindo novas camadas.

---

## 1. Estado atual consolidado

A arquitetura alvo ja esta materializada em grande parte:

```text
mdc_base -> agregacao -> fontes_agr -> gold_produtos
```

### Ja implementado nesta trilha

- contratos prioritarios da camada `mdc_base`;
- materializacao inicial de `mdc_base` a partir das camadas atuais;
- materializacao da camada `agregacao` a partir do `mdc_base`;
- materializacao da camada `fontes_agr` a partir da silver + agregacao;
- review operacional da agregacao;
- contrato minimo e status do `mapa_manual_agregacao`;
- runtimes operacionais para status por camada, contratos, materializacao e execucao.

### Consequencia pratica

Antes de seguir para novas expansoes, o foco deve sair de "abrir mais versoes" e passar a ser:

1. consolidar contratos;
2. reduzir duplicacao de fluxo;
3. garantir consumo preferencial das camadas novas;
4. validar formulas e resultados finais;
5. endurecer observabilidade, testes e recuperacao.

---

## 2. Reanalise dos repositorios legados

## 2.1 `audit_react` — Fisconforme nao atendido

A implementacao de Fisconforme nao atendido no `audit_react` concentra em um unico router responsabilidades de:

- configuracao Oracle;
- consulta individual e em lote;
- cache Parquet;
- acervo de DSFs;
- persistencia local;
- geracao de notificacoes;
- geracao de ZIP;
- geracao de DOCX.

### Diagnostico

Esse desenho entrega funcionalidade, mas reduz estabilidade porque:

- mistura IO externo, cache, regra de negocio e montagem documental na mesma unidade;
- dificulta testes isolados;
- dificulta reaproveitamento da logica no backend moderno;
- aumenta risco de regressao em lote e em geracao de documentos.

### Recomendacao para `sistema_ro`

Nao copiar o router monolitico. A migracao correta e separar em modulos:

- `fisconforme_extract_service`
- `fisconforme_cache_service`
- `fisconforme_dsfs_service`
- `fisconforme_notification_service`
- `fisconforme_batch_service`
- `fisconforme_docx_service`

### Impacto no plano principal

A parte de Fisconforme nao atendido deve entrar no `sistema_ro` apenas depois de:

- contratos estaveis de cache e saida;
- padrao unico de persistencia por CNPJ;
- roteadores finos;
- servicos testaveis separadamente.

---

## 2.2 `audit_pyside` — agregacao, conversao e estoque

O `audit_pyside` confirma a regra de negocio correta, mas tambem deixa visivel o custo arquitetural do modelo antigo.

### Leitura principal

A classe `ServicoAgregacao` acumulou responsabilidades de:

- carga e cache de Parquet;
- agregacao manual e automatica;
- recalculo de `produtos_final`;
- regeneracao de `*_agr`;
- fatores de conversao;
- c170/c176 XML;
- movimentacao de estoque;
- calculos mensais/anuais/periodos;
- ressarcimento;
- logs e reversao de agrupamentos.

### Diagnostico

Esse desenho foi util no desktop, mas nao deve ser reproduzido no `sistema_ro` porque:

- cria acoplamento excessivo entre identidade, conversao, estoque e fiscal;
- dificulta recomputacao parcial confiavel;
- mistura camada operacional com orquestracao longa;
- eleva custo de manutencao e de teste.

### O que deve ser aproveitado

Do `audit_pyside`, devem ser preservados:

- a ordem oficial de dependencia do pipeline;
- a preocupacao com rastreabilidade;
- a logica de agrupamento e de reversao manual;
- a ideia de auditoria de artefatos defasados;
- a validacao incremental e o uso de contratos minimos.

### O que deve ser evitado

- servico unico de agregacao/orquestracao;
- reprocessamentos cascata acoplados a uma unica classe;
- recarga eager como comportamento padrao;
- mistura de UI, cache e ETL.

---

## 3. Revisao do objetivo de curto prazo

O objetivo imediato deixa de ser "implementar a proxima camada" e passa a ser:

> **fazer a arquitetura nova operar de forma previsivel, auditavel e estavel, com gold consumindo as camadas novas e sem regressao funcional nos blocos de agregacao, conversao, estoque e fisconforme.**

---

## 4. Prioridades revisadas

## Prioridade 1 — estabilizar contratos e consumo das novas camadas

### Escopo

- `mdc_base`
- `agregacao`
- `fontes_agr`
- `gold_produtos`

### Acoes

1. fazer o gold consumir `fontes_agr` como fonte preferencial;
2. validar schemas minimos de `c170_agr`, `nfe_agr`, `nfce_agr`, `bloco_h_agr`;
3. validar obrigatoriedade de `id_agrupado` nas tabelas de produto da trilha principal;
4. consolidar paths e referencias operacionais em um unico conjunto de helpers;
5. eliminar duplicacao entre camada antiga (`gold`, `silver`) e nova (`mdc_base`, `agregacao`, `fontes_agr`) onde houver redundancia operacional.

### Resultado esperado

- o `gold_produtos` deixa de depender diretamente de bruto/silver quando houver fonte agregada disponivel;
- a trilha nova passa a ser a trilha principal de fato.

---

## Prioridade 2 — endurecer agregacao e conversao

### Escopo

- `mapa_manual_agregacao`
- `map_produto_agrupado`
- `produtos_final`
- `item_unidades`
- `fatores_conversao`

### Acoes

1. garantir contrato unico para `codigo_fonte`, `id_linha_origem` e `descricao_normalizada`;
2. validar precedencia do mapa manual sobre o agrupamento automatico em toda recomputacao;
3. revisar diagnostico de necessidade de conversao para virar entrada operacional obrigatoria;
4. ligar `diagnostico_conversao_unidade_base` a `item_unidades` e `fatores_conversao`;
5. adicionar testes de regressao para:
   - agrupamento automatico;
   - override manual;
   - divergencia de unidade;
   - ausencia de `unid_ref`.

### Resultado esperado

- identidade de produto e conversao passam a ser deterministicas e rastreaveis.

---

## Prioridade 3 — estabilizar estoque e derivados fiscais

### Escopo

- `mov_estoque`
- `aba_mensal`
- `aba_anual`
- `aba_periodos`
- `estoque_resumo`
- `estoque_alertas`

### Acoes

1. adaptar o pipeline principal para usar `fontes_agr` como entrada do estoque;
2. consolidar uma unica versao recomendada de derivados fiscais, evitando proliferacao de v2/v3/v4 paralelas;
3. validar formulas de ICMS, ST e MVA com casos dirigidos;
4. revisar arredondamentos e fallback de aliquotas;
5. padronizar o uso de `co_sefin`, `aliq_interna`, `it_in_st`, `it_pc_mva` nas tabelas finais.

### Resultado esperado

- estoques e derivados passam a refletir a arquitetura nova sem trilhas paralelas conflitantes.

---

## Prioridade 4 — redesenhar a entrada de Fisconforme nao atendido

### Escopo

Migracao conceitual do legado `audit_react` para o `sistema_ro`.

### Acoes

1. quebrar a funcionalidade em servicos pequenos e testaveis;
2. definir contrato de cache por CNPJ para cadastral, malhas e notificacoes;
3. isolar configuracao Oracle da regra de negocio;
4. separar lote, DSF e notificacao em modulos independentes;
5. criar testes para:
   - consulta individual;
   - consulta em lote;
   - carga do cache;
   - geracao de notificacao;
   - geracao de ZIP/DOCX.

### Resultado esperado

- Fisconforme entra no `sistema_ro` sem repetir o acoplamento do router legado.

---

## Prioridade 5 — observabilidade, recuperacao e performance

### Escopo

- logs por camada;
- diagnostico de artefatos ausentes/defasados;
- medicionamento dos tempos reais.

### Acoes

1. expandir status por camada para informar tambem datasets defasados;
2. adicionar validacao de schema nos pontos de materializacao;
3. registrar tempos de `mdc_base`, `agregacao`, `fontes_agr` e `gold_produtos`;
4. padronizar mensagens de falha por contexto (`cnpj`, camada, dataset, etapa);
5. consolidar testes para materializacao e rerun parcial.

### Resultado esperado

- diagnostico rapido de regressao;
- menor custo de suporte e manutencao.

---

## 5. Sequencia recomendada antes do proximo grande passo

### Fase A — congelar a arquitetura nova como trilha oficial

- adaptar o gold para consumir `fontes_agr`;
- adicionar validacao de schema nas entradas novas;
- revisar nomes/versionamento das trilhas paralelas.

### Fase B — fechar corretude funcional

- revisar conversao de unidades;
- revisar formulas de estoque e fiscalidade;
- testar override manual de agregacao e reflexo nas tabelas finais.

### Fase C — elevar robustez operacional

- ampliar status por camada;
- ampliar logs e medidas de tempo;
- adicionar testes de regressao do fluxo completo.

### Fase D — so depois expandir novos dominios

- migrar Fisconforme nao atendido em servicos;
- subir ressarcimento e reconciliacoes adicionais;
- preparar frontend definitivo.

---

## 6. Backlog revisado de alta prioridade

### Alta prioridade imediata

- [ ] adaptar `gold_produtos` para preferir `fontes_agr`
- [ ] validar schema de `fontes_agr`
- [ ] consolidar uma unica trilha recomendada de derivados fiscais
- [ ] ligar `diagnostico_conversao_unidade_base` ao fluxo operacional real
- [ ] ampliar testes de fluxo `mdc_base -> agregacao -> fontes_agr -> gold`

### Alta prioridade seguinte

- [ ] implementar diagnostico de datasets defasados por camada
- [ ] reduzir duplicacao entre paths/dataset refs antigos e novos
- [ ] desenhar servicos do Fisconforme nao atendido sem router monolitico

### Media prioridade

- [ ] endurecer persistencia e template operacional do `mapa_manual_agregacao`
- [ ] expor preview e conflito de `fontes_agr` por API
- [ ] medir tempos reais das etapas novas

---

## 7. Criterio para voltar a implementar novas features

Antes de abrir uma nova frente grande, o projeto deve cumprir:

1. `gold_produtos` lendo `fontes_agr` como preferencia real;
2. testes cobrindo agregacao, conversao e estoque nas camadas novas;
3. formulas fiscais estabilizadas em uma trilha unica recomendada;
4. observabilidade minima de status, schema e defasagem;
5. plano de migracao do Fisconforme desacoplado do legado.

---

## 8. Veredito executivo

O `sistema_ro` ja saiu da fase de conceito e entrou em arquitetura operacional. O maior risco agora nao e faltar camada nova; e sim continuar expandindo sem consolidar o que ja foi materializado.

Portanto, o proximo passo recomendado de codigo deve ser:

> **fazer o gold consumir `fontes_agr` como trilha oficial, com validacao de schema e testes de regressao, antes de continuar expandindo novos dominios.**
