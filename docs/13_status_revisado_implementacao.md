# Revisão do plano e do estado de implementação

## Resumo executivo

Depois da revisão do plano e do código atual, a conclusão é:

- a base do projeto já saiu do estágio de scaffold e entrou em execução técnica real;
- a silver-base já pode ser preparada por API dedicada;
- a execução gold validada já existe e já usa a versão mais forte da conversão (`gold_v2`);
- o `log_conversao_anomalias` já é persistido e já existe API específica para qualidade da conversão;
- a todo list anterior ficou parcialmente desatualizada e precisava ser corrigida.

## Evidências principais

### Preparação e execução
- `runtime_silver.py` prepara a silver-base mínima;
- `runtime_exec_v2.py` e `runtime_exec_v3.py` já expõem execução validada;
- `pipeline_exec_v3_service.py` já chama `run_and_persist_gold_pipeline_v2` e marca `pipeline_version = gold_v2`.

### Conversão
- a conversão v2 já existe com prioridade entre estrutural, preço e manual;
- `conversao_quality_service.py` já expõe resumo e preview de anomalias;
- o `log_conversao_anomalias` já está previsto na persistência gold v2.

## Status revisado por bloco

### Bloco A — alinhar execução validada ao melhor pipeline atual
**Status revisado:** quase concluído
- [x] fazer a execução validada usar `run_gold_pipeline_v2`
- [x] persistir `log_conversao_anomalias`
- [x] expor preview do log de anomalias por API
- [ ] integrar melhor a vigência SEFIN na execução validada
- [ ] criar resposta de execução com metadados de qualidade da conversão mais completos

### Bloco B — melhorar qualidade analítica do estoque
**Status revisado:** parcialmente pendente
- [ ] reforçar `0 - ESTOQUE INICIAL`
- [ ] tratar melhor `3 - ESTOQUE FINAL`
- [ ] melhorar cálculo de `periodo_inventario`
- [ ] aproximar regras de saídas desacobertadas dos documentos funcionais
- [ ] adicionar testes específicos de inventário e transição de períodos

### Bloco C — consolidar runtimes da API
**Status revisado:** pendente
- [ ] reduzir redundância entre v2, v3, v4, v5, v6 e v7
- [x] definir app principal recomendado
- [ ] documentar fluxo oficial `silver -> gold -> preview -> quality`
- [ ] padronizar contratos de resposta
- [x] adicionar endpoint resumido de status do CNPJ

### Atualização incremental

O endpoint resumido de status do CNPJ agora consolida também:

- referências faltantes;
- pendências mínimas de silver e gold;
- diagnóstico bruto de referências e contexto estruturado de SEFIN;
- `next_action` operacional, incluindo preparo silver com SEFIN quando necessário;
- superfícies oficiais recomendadas para gold e Fisconforme.

Também foi adicionada a superfície oficial de status da execução `gold_v20/current-v2`, com:

- validação de inputs;
- contexto SEFIN;
- diagnóstico bruto de referências SEFIN e status operacional do enriquecimento/fallback;
- origem de itens usada pela execução;
- resumo operacional de qualidade da conversão.

`runtime_main` também passou a funcionar como entrypoint principal de descoberta operacional, expondo overview, catálogo de superfícies, depreciações e plano de descomissionamento.

Agora esse overview/catálogo também referencia explicitamente `runtime_silver_v2` como superfície oficial complementar para `prepare-sefin`, alinhando a descoberta principal com o `next_action` do status por CNPJ.

Também foi fechada uma parte da lacuna documental de estoque das fases 07 e 08:

- `mov_estoque` passa a materializar `__qtd_decl_final_audit__`;
- `aba_anual` e `aba_periodos` passam a preferir essa quantidade auditável quando presente;
- `aba_periodos` agora expõe `data_inicio`, `data_fim` e `periodo_label`.
- a trilha oficial do gold passou a injetar `sitafe_produto_sefin_aux` em `aba_mensal`, `aba_anual` e `aba_periodos`, permitindo resolver ST/alíquota/MVA por interseção temporal da janela mensal, anual e do período quando a referência estiver disponível em runtime.

O mesmo contrato de `pipeline/{cnpj}/status` também foi padronizado em `gold_v25/current-v5`, evitando diferença desnecessária entre superfícies oficiais ativas.

Também foi extraído um helper compartilhado de composição do `pipeline_router` das runtimes oficiais, reduzindo duplicação estrutural sem alterar os contratos expostos.

Em seguida, a montagem das rotas comuns dessas superfícies também foi centralizada em helper compartilhado, reduzindo risco de divergência entre `main`, `gold_v20`, `current-v2`, `gold_v25` e `current-v5`.

O mesmo padrão foi aplicado às runtimes de transição `gold21` a `gold24` e aos aliases `current-v3/current-v4`, preservando headers e comportamento de transição, mas reduzindo duplicação de composição.

### Bloco D — Fisconforme não atendido
**Status revisado:** pendente parcial
- [ ] implementar consulta individual real
- [ ] implementar consulta em lote
- [ ] integrar cache com reuso por CNPJ e atualização controlada
- [ ] implementar geração de notificações
- [ ] integrar com dossiê e pasta de saída

### Bloco E — frontend
**Status revisado:** pendente
- [ ] iniciar frontend real a partir da especificação existente
- [ ] criar módulos de Mercadorias, Estoque e Fisconforme
- [ ] implementar tabelas operacionais com persistência de contexto
- [ ] implementar navegação por subabas
- [ ] ligar frontend às APIs runtime

## Conclusão técnica

O repositório já está pronto para sair de “preparação de pipeline” e entrar em “qualidade de domínio e consolidação de produto”.
O próximo passo mais consistente não é abrir mais uma runtime ou mais um scaffold. O próximo passo certo é melhorar a aderência do estoque e integrar melhor a vigência SEFIN na execução principal.

## Próxima entrega recomendada

1. integrar vigência SEFIN à execução validada principal;
2. reforçar a `mov_estoque` com inventário inicial/final e `periodo_inventario` mais fiel;
3. só depois consolidar as APIs runtime redundantes.
