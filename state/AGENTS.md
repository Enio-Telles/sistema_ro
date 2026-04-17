# AGENTS.md — state

Estas instruções valem para toda a árvore `state/`.

## Papel desta área
Aqui vive persistência de estado operacional, contexto de execução e preferências/artefatos locais quando aplicável.

## Regras específicas
- Não trate estado como fonte de verdade fiscal.
- Preserve compatibilidade de formato quando possível.
- Evite mudanças silenciosas em schema de estado.
- Considere migração quando houver quebra.

## Validação esperada
- compatibilidade de leitura/escrita
- impacto em sessões e contexto persistido
- rollback simples quando aplicável
