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
- [ ] definir app principal recomendado
- [ ] documentar fluxo oficial `silver -> gold -> preview -> quality`
- [ ] padronizar contratos de resposta
- [ ] adicionar endpoint resumido de status do CNPJ

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
