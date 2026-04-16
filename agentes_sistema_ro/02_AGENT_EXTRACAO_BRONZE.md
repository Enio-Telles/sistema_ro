# 02_AGENT_EXTRACAO_BRONZE.md

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
