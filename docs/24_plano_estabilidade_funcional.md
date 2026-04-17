# Plano de Estabilidade Funcional e Otimizacao

## Objetivo

Consolidar o `sistema_ro` como trilha operacional estavel antes de abrir novas frentes grandes. O foco e fazer a arquitetura nova operar com previsibilidade, corretude fiscal e baixo retrabalho.

## Premissas

- a arquitetura alvo ja existe em boa parte: `mdc_base -> agregacao -> fontes_agr -> gold_produtos`;
- o risco principal nao e falta de camada nova, e sim expandir sem consolidar contratos, formulas e observabilidade;
- os legados `audit_react` e `audit_pyside` devem servir como referencia de regra de negocio, nao como modelo de acoplamento.

## Leitura dos legados

### `audit_react`

Licao principal: nao repetir router monolitico para Fisconforme.

Direcao:

- separar extracao, cache, DSFs, lote, notificacao e DOCX em servicos pequenos;
- manter contratos estaveis de cache e saida antes de migrar a funcionalidade completa.

### `audit_pyside`

Licao principal: nao repetir servico unico que mistura agregacao, conversao, estoque e orquestracao.

Preservar:

- ordem oficial do pipeline;
- rastreabilidade;
- agrupamento manual e reversao;
- validacao incremental.

Evitar:

- servico unico de orquestracao;
- reprocessamento cascata acoplado;
- mistura de UI, cache e ETL.

## Prioridades

### Prioridade 1 - contratos e consumo das camadas novas

Escopo:

- `mdc_base`
- `agregacao`
- `fontes_agr`
- `gold_produtos`

Acoes:

1. fazer o gold consumir `fontes_agr` como fonte preferencial;
2. validar schema minimo de `c170_agr`, `nfe_agr`, `nfce_agr` e `bloco_h_agr`;
3. garantir `id_agrupado` nas tabelas centrais de produto;
4. consolidar helpers de paths e referencias;
5. reduzir redundancia entre trilha antiga e trilha nova.

Resultado esperado:

- `gold_produtos` deixa de depender diretamente de bruto/silver quando houver fonte agregada valida.

### Prioridade 2 - agregacao e conversao

Escopo:

- `mapa_manual_agregacao`
- `map_produto_agrupado`
- `produtos_final`
- `item_unidades`
- `fatores_conversao`

Acoes:

1. consolidar contrato de `codigo_fonte`, `id_linha_origem` e `descricao_normalizada`;
2. validar precedencia do mapa manual;
3. tornar o diagnostico de conversao entrada operacional real;
4. ligar `diagnostico_conversao_unidade_base` a `item_unidades` e `fatores_conversao`;
5. ampliar testes de regressao para agrupamento, override e divergencia de unidade.

Resultado esperado:

- identidade de produto e conversao ficam deterministicas e rastreaveis.

### Prioridade 3 - estoque e derivados fiscais

Escopo:

- `mov_estoque`
- `aba_mensal`
- `aba_anual`
- `aba_periodos`
- `estoque_resumo`
- `estoque_alertas`

Acoes:

1. adaptar estoque para entrada preferencial de `fontes_agr`;
2. manter uma trilha recomendada unica de derivados fiscais;
3. validar ICMS, ST e MVA com casos dirigidos;
4. revisar arredondamentos e fallback de aliquotas;
5. padronizar `co_sefin`, `aliq_interna`, `it_in_st` e `it_pc_mva`;
6. consolidar contrato de inventario:
   - `__qtd_decl_final_audit__` em `mov_estoque`;
   - preferencia por quantidade declarada em anual e periodos;
   - `data_inicio`, `data_fim` e `periodo_label` em `aba_periodos`;
7. consolidar vigencia temporal SEFIN:
   - resolucao por janela mensal, anual e por periodo;
   - fallback conservador quando a referencia nao estiver disponivel;
   - diagnostico de cobertura temporal no gold oficial.

Resultado esperado:

- estoque e derivados passam a refletir a arquitetura nova sem trilhas paralelas conflitantes.

### Prioridade 4 - Fisconforme nao atendido

Acoes:

1. quebrar a funcionalidade em servicos pequenos;
2. definir contrato de cache por CNPJ;
3. isolar configuracao Oracle;
4. separar lote, DSF e notificacao;
5. criar testes de consulta, cache, notificacao e saida documental.

Resultado esperado:

- migracao do Fisconforme sem repetir o acoplamento do legado.

### Prioridade 5 - observabilidade e recuperacao

Acoes:

1. ampliar status por camada com datasets ausentes ou defasados;
2. adicionar validacao de schema nos pontos de materializacao;
3. medir tempos de `mdc_base`, `agregacao`, `fontes_agr` e `gold_produtos`;
4. padronizar mensagens de falha por `cnpj`, camada e dataset;
5. consolidar testes de materializacao e rerun parcial.

Resultado esperado:

- diagnostico rapido de regressao e menor custo operacional.

## Sequencia recomendada

### Fase A - congelar a trilha nova como principal

- adaptar o gold para `fontes_agr`;
- validar schema das entradas novas;
- revisar nomes e versionamento das trilhas paralelas.

### Fase B - fechar corretude funcional

- revisar conversao de unidades;
- revisar formulas de estoque e fiscalidade;
- testar override manual e reflexo nas tabelas finais.

### Fase C - elevar robustez operacional

- ampliar status por camada;
- ampliar logs e tempos;
- adicionar testes de regressao do fluxo completo.

### Fase D - so depois expandir dominio

- migrar Fisconforme nao atendido;
- subir reconciliacoes adicionais;
- preparar frontend definitivo.

## Backlog de alta prioridade

Imediato:

- [ ] adaptar `gold_produtos` para preferir `fontes_agr`
- [ ] validar schema de `fontes_agr`
- [ ] consolidar trilha recomendada unica de derivados fiscais
- [ ] ligar `diagnostico_conversao_unidade_base` ao fluxo operacional real
- [ ] ampliar testes do fluxo `mdc_base -> agregacao -> fontes_agr -> gold`

Seguinte:

- [ ] diagnostico de datasets defasados por camada
- [ ] reduzir duplicacao entre paths e dataset refs antigos e novos
- [ ] desenhar servicos do Fisconforme sem router monolitico

## Criterio para abrir nova frente grande

Antes de expandir o projeto em outro dominio, ele deve cumprir:

1. gold lendo `fontes_agr` como preferencia real;
2. testes cobrindo agregacao, conversao e estoque nas camadas novas;
3. formulas fiscais estabilizadas em trilha unica;
4. observabilidade minima de status, schema e defasagem;
5. plano de migracao do Fisconforme desacoplado do legado.

## Direcao executiva

O proximo passo de codigo continua sendo consolidar a trilha nova e fechar corretude funcional, nao abrir uma nova camada por inercia.
