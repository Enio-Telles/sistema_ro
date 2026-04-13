# Plano de implementação — fases 13 a 16

## Fase 13 — Observabilidade e operação

### Etapa 13.1 — Logs e rastreabilidade
- registrar `match_rule`, `match_confidence` e `tipo_fator`
- registrar logs de agrupamento manual e reversão
- registrar logs de fatores sem preço utilizável
- registrar logs de reprocessamento por CNPJ
- registrar alertas de estoque e inconsistências de inventário

### Etapa 13.2 — Telemetria operacional
- medir tempo de extração por query core
- medir tempo de transformação por domínio
- medir volume de linhas por dataset
- medir taxa de reaproveitamento de cache no Fisconforme
- expor endpoint simples de health e readiness

## Fase 14 — Segurança e robustez

### Etapa 14.1 — Hardening técnico
- proteger caminhos de saída e gravação local
- validar CNPJ/CPF e parâmetros de período
- impedir path traversal em notificações e exportações
- exigir schemas mínimos nas cargas de entrada
- normalizar comportamento de falha parcial em lote

### Etapa 14.2 — Robustez de dados
- bloquear propagação de match ambíguo para o estoque
- bloquear fator inválido fora de faixa esperada
- impedir merge destrutivo sem snapshot de reversão
- impedir perda de `id_linha_origem` e `codigo_fonte`
- impedir mudanças silenciosas de contrato entre versões

## Fase 15 — Homologação funcional

### Etapa 15.1 — Homologação por domínio
- homologar agregação com amostras reais de mercadorias
- homologar conversão com casos de embalagem e fracionamento
- homologar estoque com Bloco H e saídas documentais
- homologar Fisconforme individual e em lote
- homologar subabas do frontend com usuários operacionais

### Etapa 15.2 — Piloto controlado
- selecionar conjunto inicial de CNPJs piloto
- executar extração, transformação e API ponta a ponta
- registrar divergências e ajustes necessários
- fechar checklist de aceite do piloto
- congelar versão candidata de implantação

## Fase 16 — Produção e evolução

### Etapa 16.1 — Rollout do sistema_ro
- publicar primeira versão operacional do repositório
- documentar rotina de atualização das referências SEFIN
- documentar rotina de recarga de SQL e Parquet
- definir rotina de suporte e triagem de bugs
- definir política de versionamento dos datasets gold

### Etapa 16.2 — Backlog pós-go-live
- ampliar malhas e notificações do Fisconforme
- incorporar mais domínios de DIMP, CTe e ressarcimento
- evoluir score de agregação com revisão humana assistida
- melhorar deduplicação e reconciliações automáticas
- ampliar exportações, dashboards e dossiês derivados
