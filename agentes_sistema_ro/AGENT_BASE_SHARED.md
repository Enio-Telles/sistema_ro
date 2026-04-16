# AGENT_BASE_SHARED.md — Base comum dos agentes do sistema_ro

## Regra-mãe
O arquivo `AGENT_EXECUCAO_PROJETO.md` é a base normativa principal deste pacote.

Todos os agentes deste diretório devem obedecer integralmente esse arquivo, em especial:
- missão e princípios inegociáveis;
- regra Oracle x Polars;
- ordem obrigatória antes de codar;
- checklist antes de criar nova SQL;
- regras de extração Oracle;
- políticas `cache-first`, `bronze-first` e de não repetição;
- camadas oficiais `raw`, `base`, `curated`, `marts`, `views`;
- metadados e rastreabilidade obrigatórios;
- incrementalidade, reprocessamento e idempotência;
- preferência por `LazyFrame` e `scan_parquet()`;
- formato de resposta A–E.

## Precedência
Em caso de dúvida ou conflito:
1. prevalece `AGENT_EXECUCAO_PROJETO.md`;
2. depois as regras do orquestrador;
3. depois as especializações por dimensão.

## Obrigação mínima de todos os agentes
Antes de propor SQL, pipeline, dataset, endpoint, tela ou refatoração, o agente deve responder:
1. a demanda já é atendida por SQL, Parquet, módulo ou componente existente?
2. a necessidade é realmente nova ou só uma nova visualização?
3. a mudança preserva lineage, schema estável e reprocessamento?
4. a solução pode reaproveitar bronze/base e recompor em Polars?
5. o Oracle precisa mesmo ser tocado?

## Resposta obrigatória
Todo agente deve responder no formato:
### A. Diagnóstico
### B. Reaproveitamento encontrado
### C. Decisão arquitetural
### D. Justificativa
### E. Plano de execução

## Regras universais
- proibido SQL inline em Python;
- proibido lógica fiscal no frontend;
- proibido pular inventário prévio;
- proibido duplicar lógica fiscal em múltiplos lugares;
- proibido quebrar contrato de Parquet sem versionamento;
- proibido criar solução “para tela” que force nova SQL sem justificativa formal.
