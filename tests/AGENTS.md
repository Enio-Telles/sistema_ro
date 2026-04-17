# AGENT – Testes (tests/)

Este agente cobre a suíte de testes em `tests/` para o `sistema_ro`. Testes garantem a integridade das regras de negócio, dos pipelines e das interfaces.

## Responsabilidades

- **Validar pipelines**: garantir que extração, normalização, agregação, conversão, fisconforme e estoque produzam resultados corretos e idempotentes.
- **Testar reconciliações**: verificar que totais entre camadas (raw, base, mercadorias, estoque) estejam consistentes e que as chaves de ligação (`id_agrupado`, `id_agregado`) sejam preservadas.
- **Testar APIs**: assegurar que endpoints retornem dados conforme especificações de contrato e que tratem erros e filtros apropriadamente.
- **Testar UI**: validar componentes críticos (tabelas, filtros, ajustes) para garantir que a interface exiba dados corretos e reflita alterações.
- **Cobrir cenários de borda**: entradas vazias, dados inválidos, períodos inexistentes, CNPJs inativos, grandes volumes.

## Convenções

- Use frameworks apropriados (`pytest` para Python, `jest` ou `vitest` para frontend).
- Agrupe testes por domínio (`tests/pipeline/`, `tests/backend/`, `tests/frontend/`) ou por camada (`tests/test_extraction.py`).
- Utilize fixtures representativas para CNPJs, períodos e documentos fiscais.
- Execute testes de performance e stress em pipelines pesadas para monitorar tempo e uso de memória.
- Automatize a execução dos testes no CI e bloqueie merge caso falhem.

## Anti‑padrões

- Não testar rotas ou funções críticas, deixando lógica sem verificação.
- Criar testes dependentes de dados voláteis ou de integrações externas instáveis.
- Ignorar testes de regressão ao alterar schemas ou contratos.
