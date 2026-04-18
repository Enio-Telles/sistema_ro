# Agent – sistema_ro

Este arquivo define as instruções persistentes para o assistente de IA no repositório **sistema_ro**. Ele sintetiza as normas de governança, arquitetura e execução que devem ser seguidas em todas as camadas do projeto.

## Missão

- **Correção fiscal**: garantir que as regras e cálculos fiscais aplicados às mercadorias sejam corretos e auditáveis.
- **Rastreabilidade ponta a ponta**: cada dado transformado deve manter uma cadeia clara de origem, desde a linha bruta de documento fiscal até as visões agregadas e expostas via API ou UI.
- **Reaproveitamento máximo**: evite criar novos scripts ou datasets quando artefatos existentes podem atender ao objetivo; prefira adaptar e evoluir.

## Camadas e Estrutura

O `sistema_ro` organiza sua lógica em camadas sucessivas e domínios claros:

1. **raw** (`pipeline/extraction/`): extração de dados brutos a partir do Oracle ou outras fontes.
2. **base** (`pipeline/normalization/`): tipagem, normalização de nomes e deduplicação.
3. **curated / mercadorias** (`pipeline/mercadorias/`): agregação de mercadorias por `id_agrupado` e `id_agregado`, cálculo de tributos, quantidades e valores.
4. **conversao** (`pipeline/conversao/`): aplicação de fatores de conversão de unidades e pesos, considerando `fator_manual` quando aplicável.
5. **fisconforme** (`pipeline/fisconforme/`): enriquecimento com dados da SEFIN e outras bases fiscais para validar conformidade.
6. **estoque** (`pipeline/estoque/`): construção de `mov_estoque` e visões de saldo, giro e cobertura de estoque.
7. **derivacoes analiticas** (dentro de `pipeline/estoque` ou `pipeline/gold` quando existir): criação de marts e visões analíticas para consumo.
8. **backend** (`backend/`): exposição de APIs REST (FastAPI) para consulta e orquestração de pipelines.
9. **frontend** (`frontend/`): interface React/Tauri para uso operacional, sempre consumindo contratos estáveis do backend.
10. **tests** (`tests/`): testes unitários, de integração e de reconciliação.
11. **sql** (`sql/`): manifestos e templates de extração SQL.
12. **references** (`references/`): tabelas auxiliares, dicionários e fatores de conversão.
13. **docs** (`docs/`): documentação técnica, catálogos e decisões de arquitetura.

## Princípios gerais

### Cache‑first e Bronze‑first

Sempre que possível, consulte materializações Parquet ou caches locais em vez de reexecutar extrações pesadas no Oracle. Extrações devem produzir datasets na camada raw e todas as transformações subsequentes devem partir desses arquivos.

### Reaproveitamento

Verifique se já existe script ou dataset que cumpra o requisito antes de criar algo novo. Use `AGENT_EXECUCAO_PROJETO.md` e catálogos em `docs/` para localizar artefatos reutilizáveis.

### Oracle vs Polars

Utilize Oracle apenas para extração inicial; toda harmonização, join, agregação e derivação deve ser feita em **Polars**. Evite SQL dentro de código Python; mantenha consultas em `sql/` e reutilize-as.

### Chaves invariantes

Preserve as colunas `id_agrupado`, `id_agregado`, `__qtd_decl_final_audit__` e outras chaves usadas para reconciliação. Não renomeie nem substitua esses campos sem um plano de migração e comunicação para todos os consumidores.

### Lineage e metadata

Registre, para cada dataset materializado: tabela(s) de origem, filtros aplicados, período processado (ano-mês), CNPJ(s) e chaves fiscais. Atualize manifestos e documentação.

### Resposta A–E

Ao planejar, revisar ou descrever uma tarefa, siga a estrutura **A–E**:

1. **Diagnóstico (A)** – descreva o problema ou requisito de forma clara e concisa.
2. **Reaproveitamento (B)** – liste artefatos existentes (SQL, Parquet, módulos, contratos) que podem ser reutilizados.
3. **Decisão (C)** – proponha a solução: criar novo, modificar, reutilizar.
4. **Justificativa (D)** – explique a escolha considerando performance, integridade fiscal, rastreabilidade e custos.
5. **Plano (E)** – defina os passos concretos (ordem de PRs, scripts, testes, migrações) para implementação ou correção.

### Governança de Pull Requests

- **Branches curtas e temáticas**: use prefixos `feat/`, `fix/`, `refactor/` seguidos de domínio e objetivo.
- **PR pequena e focada**: cada PR deve ter um escopo claro e ser revisável rapidamente. Evite misturar refatoração estrutural com mudanças de regra de negócio.
- **Descrição completa**: informe objetivo, camadas/dominios afetados, datasets e contratos impactados, riscos (schema, fiscal, performance), plano de rollback e reprocessamento.
- **CI verde**: exija lint, testes unitários, testes de integração e validação de schema.
- **Migração e convivência**: para mudanças de schema ou contratos, explique a estratégia de transição e a compatibilidade com consumidores existentes.

### Anti‑padrões

- Embutir SQL diretamente em serviços ou UI.
- Pular camadas (por exemplo, gerar dados em `curated` sem passar por `base`).
- Duplicar lógica fiscal em mais de um lugar.
- Alterar chaves invariantes sem planejamento.
- Esquecer de registrar lineage e metadados.
- Quebrar contratos de API sem aviso e plano de migração.

Siga estas diretrizes em todos os módulos para que o assistente de IA gere respostas úteis e alinhadas com a governança do projeto.
