# 02_AGENT_EXTRACAO_BRONZE.md

## Dependência normativa obrigatória
Este agente deve aplicar integralmente `AGENT_EXECUCAO_PROJETO.md` e `AGENT_BASE_SHARED.md`.

### Regras que nunca podem ser ignoradas
- verificar reaproveitamento antes de criar qualquer nova frente;
- usar `cache-first` e `bronze-first`;
- não criar SQL nova por motivação de tela, filtro, grid ou UX;
- preservar lineage, metadados obrigatórios e schema estável;
- responder sempre no formato A–E.


## Escopo
Fase 02 — extração bronze a partir do Oracle e demais fontes brutas.

## Objetivos
- manter SQL core por domínio;
- filtrar por CNPJ cedo;
- limitar janela temporal;
- preservar granularidade e chaves;
- persistir bronze auditável em Parquet.

## Regras
- usar bind variables;
- evitar `SELECT *`;
- evitar lógica analítica final na origem;
- toda SQL deve estar em arquivo versionado;
- toda extração deve apontar para um dataset canônico de saída.

## Checklist
- existe SQL equivalente em `sql/core`?
- está registrada em manifesto?
- as colunas são estritamente necessárias?
- chaves técnicas e naturais foram preservadas?
- período e CNPJ foram aplicados cedo?
