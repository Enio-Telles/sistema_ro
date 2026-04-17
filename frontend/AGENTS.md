# AGENTS.md — frontend

Estas instruções valem para toda a árvore `frontend/`.

## Papel desta área
O frontend React é operacional, orientado a tabela, filtro, rastreabilidade e revisão assistida.
Ele não deve virar a fonte principal da regra fiscal ou analítica.

## Regras específicas
- Não duplique regra de negócio do backend/pipeline no cliente.
- Consuma contratos estáveis da API.
- Priorize tabela operacional em vez de dashboard decorativo.
- Preserve contexto por aba, filtros, paginação e exportação quando aplicável.
- Reutilize componentes, hooks e stores antes de criar novos.

## UX esperada
- foco em operação real
- destaque de anomalias reais
- filtros textuais e por período
- performance aceitável com datasets grandes
- abertura de contexto em nova aba quando fizer sentido

## Performance
- Evite renderização excessiva.
- Considere virtualização, paginação ou carregamento incremental.
- Não mascare inconsistência de dados no cliente; corrija na fonte certa.

## Validação esperada
- revisão visual funcional
- compatibilidade de tipos/contratos
- cobertura de cenários críticos de tabela, filtro e navegação
