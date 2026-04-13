# Plano de implementação — fases 09 a 12

## Fase 09 — Backend API

### Etapa 9.1 — API de mercadorias e estoque
- criar `GET /api/v1/agregacao/{cnpj}/grupos`
- criar `GET /api/v1/conversao/{cnpj}/fatores`
- criar `GET /api/v1/estoque/{cnpj}/movimentos`
- criar `GET /api/v1/estoque/{cnpj}/apuracao/mensal`
- criar `GET /api/v1/estoque/{cnpj}/apuracao/anual` e `/periodos`

### Etapa 9.2 — Reprocessamento controlado
- criar rotas de reprocessamento por domínio
- separar reprocesso de agregação, conversão e estoque
- registrar `pipeline_run_id` e dependências da execução
- permitir reprocesso incremental por CNPJ e período
- persistir histórico mínimo de runs e logs

## Fase 10 — Fisconforme não atendido

### Etapa 10.1 — Consulta e cache
- criar endpoint de configuração Oracle do Fisconforme
- criar `consulta-cadastral` com cache por CNPJ
- criar `consulta-lote` com retorno por CNPJ
- separar cache de cadastral e cache de malhas
- persistir resultados em `dados/CNPJ/<cnpj>/fisconforme/`

### Etapa 10.2 — Resultados e notificações
- criar geração de notificação individual
- criar geração de notificações em lote
- suportar DSF, auditor, órgão e pasta de saída
- permitir reuso do PDF da DSF salvo no acervo
- manter integração com o dossiê por link direto ao CNPJ

## Fase 11 — Frontend operacional

### Etapa 11.1 — Módulo Mercadorias e Estoque
- implementar página de Mercadorias com subabas de Agregação e Conversão
- implementar página de Estoque com subabas reais
- padronizar filtro, paginação, colunas, persistência de estado e exportação
- permitir abertura em nova aba mantendo contexto
- destacar anomalias de fator, ST, saldo e entradas desacobertadas

### Etapa 11.2 — Módulo Fisconforme
- implementar fluxo `Consulta -> Resultados -> Para Notificações`
- suportar modo individual e lote de CNPJs
- exibir resumo executivo da consulta
- exibir detalhes cadastrais e pendências
- acoplar botões de geração TXT/Word/ZIP e atalho para Dossiê

## Fase 12 — Testes e reconciliação

### Etapa 12.1 — Testes unitários e integração
- testar normalização de chaves e datas
- testar agrupamento automático e manual
- testar preservação de override na conversão
- testar cálculo da `mov_estoque`
- testar rotas principais do backend

### Etapa 12.2 — Regressão e reconciliações fiscais
- reconciliar totais entre bronze, silver e gold
- comparar estoque antigo vs estoque recalculado
- comparar fatores antigos vs fatores recalculados
- validar coerência entre EFD, NFe/NFCe, DIMP e estoque
- validar Fisconforme com amostras reais por CNPJ
