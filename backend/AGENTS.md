# AGENTS.md — backend

Estas instruções valem para toda a árvore `backend/`.

## Papel desta área
O backend em Python/FastAPI expõe contratos estáveis, orquestra serviços internos e consome datasets e regras já estabilizados no pipeline.

## Regras específicas
- Não esconda regra fiscal crítica em handlers sem testes.
- Prefira separar routers, serviços e contratos.
- Use Pydantic para contratos explícitos quando aplicável.
- Evite respostas ad hoc se houver schema claro.
- Não acople endpoint a SQL improvisada se houver pipeline ou dataset canônico.
- Preserve paginação, filtros e rastreabilidade quando expor dados operacionais.

## Mudanças sensíveis nesta área
Dê atenção extra para:
- contratos de API
- breaking changes de payload
- paginação, filtros e ordenação
- compatibilidade com frontend/Tauri
- versionamento de schema ou resposta

## Validação esperada
Quando aplicável:
- testes unitários para regra crítica
- testes de integração para rotas e contratos
- validação de compatibilidade de payload
- atualização de documentação de API
