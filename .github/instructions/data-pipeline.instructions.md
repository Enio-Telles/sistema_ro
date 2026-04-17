---
applyTo: "**/bronze/**/*,**/silver/**/*,**/gold/**/*,**/fisconforme/**/*,**/*.sql"
---

# Data Pipeline Instructions — sistema_ro

## Arquitetura de dados
Respeite as camadas:
- bronze/raw: extração base
- silver/base: normalização, tipagem, deduplicação
- gold/curated/marts/views: composição analítica

## Oracle vs Polars
- Oracle entrega base auditável, granular e reaproveitável.
- Polars concentra joins, harmonização, agregações, reconciliação e derivação analítica.
- Minimize carga desnecessária no Oracle.

## Polars e Parquet
- Prefira LazyFrame e scan_parquet quando adequado.
- Planeje materializações eficientes.
- Preserve schemas estáveis.
- Avalie particionamento por CNPJ, período ou domínio quando fizer sentido.

## Rastreabilidade
- Preserve lineage entre origem, transformação e saída.
- Não esconda regras críticas em helpers obscuros.
- Registre chaves, joins, agregações e suposições do pipeline.

## Validação
Sempre avaliar:
- compatibilidade de schema
- impacto em consumidores
- risco de duplicação
- risco de travamento com volume alto
- necessidade de reprocessamento
