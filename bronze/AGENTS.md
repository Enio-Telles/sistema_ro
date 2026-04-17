# AGENTS.md — bronze

Estas instruções valem para toda a árvore `bronze/`.

## Papel desta área
Aqui fica a extração base, auditável e reaproveitável.

## Regras específicas
- Mantenha granularidade suficiente para auditoria.
- Evite lógica analítica pesada nesta camada.
- Preserve chaves e campos necessários para rastreabilidade.
- Minimize carga desnecessária no Oracle.
- Prefira SQL canônica e reaproveitável.

## Validação esperada
- schema consistente
- chaves auditáveis
- volume e extração monitoráveis
