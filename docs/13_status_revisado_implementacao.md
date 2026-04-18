# Status Revisado de Implementacao

## Leitura rapida

O repositorio ja saiu da fase de scaffold. A trilha silver, o gold oficial e as superficies principais de runtime estao operacionais. O backlog mais relevante deixou de ser "abrir nova versao" e voltou para corretude de dominio, principalmente estoque, vigencia SEFIN e consolidacao de contratos.

## Estado atual

- silver com preparo SEFIN existe e ja devolve diagnostico operacional;
- gold oficial esta consolidado em `gold_v20/current-v2`, com aliases ativos em `gold_v25/current-v5`;
- `runtime_main` virou entrypoint principal de descoberta, catalogo e descomissionamento;
- status por CNPJ ja orienta referencias faltantes, silver, gold e proxima acao;
- status por CNPJ agora tambem sinaliza cobertura temporal parcial do gold quando as abas fiscais ainda nao estao totalmente cobertas por vigencia SEFIN;
- a trilha oficial de estoque ja usa `__qtd_decl_final_audit__`, janela temporal em `aba_periodos` e resolucao temporal SEFIN em `aba_mensal`, `aba_anual` e `aba_periodos`.

## Status por bloco

### Bloco A - execucao principal

Status: avancado

- [x] gold validado ligado a uma trilha operacional forte
- [x] persistencia de `log_conversao_anomalias`
- [x] status oficial de `pipeline/{cnpj}`
- [x] contexto SEFIN e qualidade de conversao no status
- [ ] ampliar ainda mais metadados de execucao quando houver necessidade operacional real

### Bloco B - estoque e derivados fiscais

Status: em consolidacao

- [x] materializacao de `__qtd_decl_final_audit__`
- [x] preferencia por inventario final auditavel em anual e periodos
- [x] `data_inicio`, `data_fim` e `periodo_label` em `aba_periodos`
- [x] resolucao temporal SEFIN em mensal, anual e periodos
- [x] diagnostico de cobertura temporal no `run` oficial
- [ ] reforcar bordas de `0 - ESTOQUE INICIAL` e `3 - ESTOQUE FINAL`
- [ ] aproximar `saidas_desacob` e `estoque_final_desacob` dos contratos mais completos do legado

### Bloco C - runtimes da API

Status: consolidado no essencial

- [x] definir superfices oficiais
- [x] reduzir duplicacao estrutural nas runtimes oficiais e de transicao
- [x] padronizar status resumido por CNPJ
- [x] padronizar status de pipeline nas superficies oficiais
- [ ] continuar eliminando diferencas de contrato que nao gerem valor real

### Bloco D - Fisconforme nao atendido

Status: pendente estruturado

- [ ] consulta individual real
- [ ] consulta em lote
- [ ] cache operacional por CNPJ
- [ ] notificacoes
- [ ] integracao com dossie e saida documental

### Bloco E - frontend

Status: iniciado com primeiro modulo funcional

- [x] iniciar frontend real a partir da especificacao existente
- [x] separar `Area do Usuario` e `Area Tecnica`
- [x] organizar navegacao em `EFD`, `Documentos Fiscais` e `Analise Fiscal`
- [x] ligar `Analise Fiscal > Estoque` as APIs operacionais oficiais
- [x] criar contrato de tabela operacional read-only para estoque em `current-v2`
- [ ] estabilizar o modulo de estoque antes de expandir `EFD` ou `Documentos Fiscais`
- [ ] validar build desktop Tauri quando o ambiente local tiver `cargo` e `rustc`

## Incrementos relevantes ja absorvidos

- `runtime_silver_v2` foi incorporada como superficie oficial complementar para `prepare-sefin`;
- `runtime_main` centraliza overview, catalogo, deprecacoes e descomissionamento;
- o gold oficial agora informa vigencia temporal disponivel em runtime, cobertura aplicada por aba e motivos de nao cobertura;
- a trilha de estoque ficou mais aderente ao contrato documental sem alterar o schema persistido das abas finais.
- `backend.app.main` foi alinhado ao entrypoint oficial;
- a superficie `current-v2` agora expoe tabelas operacionais de estoque com filtros, ordenacao, selecao de colunas, paginacao e exportacao CSV;
- o frontend passou a existir em `frontend/` com shell React + TypeScript e estrutura `src-tauri/`;
- a primeira experiencia funcional do usuario ficou em `Analise Fiscal > Estoque`, preservando `EFD` e `Documentos Fiscais` como placeholders canonicos.

## Proxima prioridade tecnica

1. reforcar corretude de `mov_estoque` nas bordas de inventario;
2. revisar regras de estoque desacobertado com casos dirigidos;
3. so depois retomar expansoes maiores de dominio ou novas superficies.
