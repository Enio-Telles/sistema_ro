# Mapeamento de Implementação — docs

Resumo rápido do estado atual (fases 01–04)

- **Fase 01 — Fundação do projeto**: Implementada (existem `pyproject.toml`, `.env.example`, `.gitignore` e estrutura de pastas).
- **Fase 02 — Extração (bronze)**: Largamente implementada (SQLs core presentes em `sql/core` e `manifest_sqls.csv`).
- **Fase 03 — Normalização (silver)**: Implementada (módulos em `pipeline/normalization/`, `keys.py`, `unified_items.py` já existem).
- **Fase 04 — Núcleo de mercadorias**: Implementada (módulos em `pipeline/mercadorias/`, testes de builders presentes).

Observações:
- Muitos itens das fases 01–04 já estão no repositório; falta revisar cobertura, qualidade e documentação de aceitação para alguns fluxos.

Próximos passos (proposta)

1. Confirmar priorização: quais fases/docs quer priorizar agora (ex.: 05–08, runtime, conversão).
2. Gerar checklist detalhada por arquivo/entrada (comparar `docs/` ↔ `sql/` ↔ `pipeline/` ↔ `tests/`).
3. Criar branch para o trabalho prioritário (ex.: `feature/phase-05`) e scaffolding mínimo.
4. Implementar itens pendentes, adicionar testes e atualizar `docs/` com critérios de aceite.
5. Abrir PR e rodar CI/tests.

Sugestão imediata: se concordar, eu gero a checklist detalhada para as próximas 4 fases (05–08) e crio a branch de trabalho.
