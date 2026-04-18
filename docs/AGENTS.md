# AGENT – Documentação (docs/)

Este agente se aplica ao diretório `docs/`, responsável por armazenar a documentação técnica, decisões de projeto, catálogos de datasets e guias de uso.

## Responsabilidades

- **Registrar decisões de arquitetura** e rationale de design (por exemplo, por que usar Polars, por que dividir em camadas específicas).
- **Manter catálogos** de pipelines, SQLs, Parquets e APIs, incluindo schemas, origem, destino e periodicidade.
- **Documentar fluxos** de execução: como rodar pipelines, como ajustar fatores manuais, como consultar APIs.
- **Atualizar** a documentação sempre que houver mudança de schema, contrato ou processo, no mesmo PR da alteração.

## Convenções

- Utilize Markdown com seções claras e tabelas curtas para referências.
- Inclua links internos e externos (leis, portarias) para contextualizar regras fiscais.
- Mantenha um índice (`README.md`) que aponte para cada documento relevante.
- Separe documentos por domínio ou camada (`docs/mercadorias.md`, `docs/estoque.md`, `docs/api.md`).

## Anti‑padrões

- Deixar a documentação desatualizada, causando divergência entre código e guia.
- Criar documentos vagos sem exemplos de uso ou sem contexto.
- Não justificar escolhas ou ignorar decisões anteriores.
