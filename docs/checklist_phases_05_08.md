# Checklist: Fases 05–08 (implementação)

Resumo rápido

- Branch de trabalho sugerida: `feature/phase-05-08`
- Objetivo: transformar os planos das docs 05–08 em entregáveis técnicos e testes automáticos.

---

## Fase 05 — Frontend operacional (docs/05_frontend_operacional.md)
Tarefas:
- Scaffold: criar rotas e páginas em `frontend/src/pages/operational/` (Agregação, Conversão, Produtos, Estoque, Fisconforme).
- Componente de tabela reutilizável com: filtros (texto/período), paginação, seleção/ordem/colunas, persistência de estado por aba, exportação CSV/ZIP, e destaque de anomalias.
- Implementar ações: merge manual, reversão por snapshot, editar fator manual, aplicar referência em lote.
- Integração: mapear chamadas para os endpoints existentes de runtime (`/api/v2` e `/api/v3`/`/api/v4`).
- Testes: adicionar testes unitários (Vitest) e um teste E2E minimal (Playwright) cobrindo fluxo de revisão de agrupamento.
- Critério de aceite: páginas carregam com dados de preview (parquets locais), ações chamam endpoints e UI persiste filtros/colunas.

## Fase 06 — Runtime API v2 (docs/06_runtime_api.md)
Tarefas:
- Revisar `backend/app/runtime.py` e garantir os endpoints listados implementam leitura de parquet e retorno consistente (schemas esperados).
- Implementar/curar: `GET /api/v2/agregacao/{cnpj}/grupos`, `GET /api/v2/conversao/{cnpj}/fatores`, `GET /api/v2/estoque/{cnpj}/overview`, `GET /api/v2/fisconforme/{cnpj}`.
- Endpoint `POST /api/v2/pipeline/{cnpj}/run`: adicionar placeholder que valida permissões e retorna `accepted`/`queued` (ou 501 se preferir adiar execução).
- Adicionar testes de integração que usam parquets de exemplo em `workspace/` ou `parquets/`.
- Critério de aceite: cada endpoint retorna JSON com campos documentados e testes automatizados passados.

## Fase 07 — Runtime Exec API v3 (docs/07_runtime_exec_api.md)
Tarefas:
- Validar `backend/app/runtime_exec.py` e garantir `POST /api/v3/pipeline/{cnpj}/run` executa runner que consome os `silver/*.parquet` requeridos e persiste outputs em `gold/`.
- Runner: orquestra chamadas aos módulos em `pipeline/` (`mercadorias`, `normalization`, `persist_*`) e grava os parquets listados em docs.
- Implementar idempotência básica: se `produtos_final_<cnpj>.parquet` existir e `force=false`, retornar `already_exists`.
- Adicionar logs e salvar snapshot temporário por execução para permitir reversão manual.
- Testes: pipeline de integração com dataset reduzido que confirma os arquivos de saída e esquemas.
- Critério de aceite: execução POST cria os artefatos gold mínimos e responde com resumo (`saved`, `datasets`, `rows`).

## Fase 08 — Runtime Exec API v4 (docs/08_runtime_exec_v2_api.md)
Tarefas:
- Revisar `backend/app/runtime_exec_v2.py`: implementar validação detalhada (missing/empty/stats) antes de executar.
- Implementar reconstrução automática de insumos: tentar reconstruir `itens_unificados` e `base_info_mercadorias` quando estiverem ausentes.
- Resposta estruturada: suportar `status = ok` e `status = validation_failed` com payload de `missing`/`empty`/`stats`.
- Testes: casos de sucesso e falha de validação com assert nas respostas.
- Critério de aceite: validação detecta faltantes, reconstrói quando possível, e responde com estrutura de validação clara.

---

## Tarefas transversais e infra
- Atualizar `parquets/manifest_parquets.csv` com os novos artefatos gold gerados.
- Atualizar `docs/implementation_todo.md` com progresso por CNPJ de teste.
- Criar pequenos datasets de teste em `tests/fixtures/parquets_sample/` para validação de endpoints e pipelines.
- Definir CI: adicionar etapa que executa testes de integração (pytest) usando os fixtures.

## Ordem recomendada de execução
1. Criar branch `feature/phase-05-08` (scaffold separado por área).
2. Implementar endpoints read-only do runtime v2 (fase 06) e adicionar testes de integração.
3. Implementar runner v3 com persistência gold (fase 07) e testes de integração.
4. Implementar validações e reconstruções v4 (fase 08).
5. Desenvolver UI operacional minimal (fase 05) consumindo os endpoints validados.

## Critério de PR
- Todos os endpoints documentados e cobertos por testes de integração mínimos.
- Fixtures e manifest atualizados.
- Checklist desta página revisada e marcada como concluída para a branch.


---

Arquivo criado automaticamente por agente: revisar e ajustar prioridades conforme desejar.
