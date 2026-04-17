# AGENTS.md — gold

Estas instruções valem para toda a árvore `gold/`.

## Papel desta área
Aqui vivem composição analítica, agregações, indicadores, estoque, conversão e marts de consumo.

## Regras específicas
- Prefira Polars e Parquet de forma explícita e auditável.
- Preserve ligação com silver e origem quando necessário para auditoria.
- Não altere agregações ou cálculos sem avaliar impacto fiscal e operacional.
- Avalie particionamento, materialização e custo de reprocessamento.

## Mudanças sensíveis nesta área
Dê atenção extra para:
- agregações
- conversão de unidades
- estoque
- apurações mensais/anuais/períodos
- indicadores fiscais
- compatibilidade com consumo da API/UI

## Validação esperada
- testes de cálculo
- validação de schema
- validação de lineage
- validação de reprocessamento quando aplicável
