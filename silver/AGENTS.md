# AGENTS.md — silver

Estas instruções valem para toda a árvore `silver/`.

## Papel desta área
Aqui vive a normalização, tipagem, deduplicação técnica e preparação de bases estáveis.

## Regras específicas
- Preserve lineage entre bronze e silver.
- Torne schemas explícitos e estáveis.
- Registre deduplicações e harmonizações relevantes.
- Evite lógica de entrega final desta camada.

## Validação esperada
- validação de schema
- deduplicação verificável
- joins e chaves consistentes
