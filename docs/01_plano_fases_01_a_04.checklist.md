# Checklist de implementação — fases 01 a 04

Data: 2026-04-16

Resumo: mapeamento item → status (Implementado / Pendente) com evidências (caminhos no repositório).

| Item | Status | Evidência |
| --- | ---: | --- |
| Etapa 1.1 — consolidar `pyproject.toml`, `.env.example` e `.gitignore` | Implementado | [pyproject.toml](pyproject.toml), [.env.example](.env.example), [.gitignore](.gitignore) |
| Etapa 1.1 — criar estrutura `backend/`, `pipeline/`, `sql/`, `references/` e `docs/` | Implementado | [backend/app](backend/app), [pipeline/README.md](pipeline/README.md), [sql/manifest_sqls.csv](sql/manifest_sqls.csv), [references/README.md](references/README.md) |
| Etapa 1.1 — definir convenção de nomes para bronze, silver e gold | Implementado | [docs/00_manifesto_dados.md](docs/00_manifesto_dados.md) |
| Etapa 1.1 — padronizar raiz de dados por `CNPJ_ROOT` | Implementado | [.env.example](.env.example), [backend/app/config.py](backend/app/config.py) |
| Etapa 1.1 — documentar política de versionamento dos contratos | Implementado | [parquets/manifest_parquets.csv](parquets/manifest_parquets.csv), [parquets/contratos](parquets/contratos) |

| Etapa 1.2 — criar manifesto de fontes SQL e Parquets obrigatórios | Implementado | [sql/manifest_sqls.csv](sql/manifest_sqls.csv), [parquets/manifest_parquets.csv](parquets/manifest_parquets.csv) |
| Etapa 1.2 — classificar consultas em `core`, `auxiliares`, `diagnostico` e `legado` | Implementado | [sql/manifest_sqls.csv](sql/manifest_sqls.csv) |
| Etapa 1.2 — registrar referências estáticas SEFIN e suas vigências | Implementado | [pipeline/references/loaders.py](pipeline/references/loaders.py), [pipeline/references/sefin_vigencia.py](pipeline/references/sefin_vigencia.py) |
| Etapa 1.2 — definir critérios de aceite por domínio | Implementado | [docs/24_plano_estabilidade_funcional.md](docs/24_plano_estabilidade_funcional.md) |
| Etapa 1.2 — definir backlog inicial de implementação do repositório | Implementado | [docs/11_todo_atualizado.md](docs/11_todo_atualizado.md) |

Observação: marquei como "Implementado" itens que têm implementação de código, documentação ou contratos no repositório. Posso ajustar para "Parcial" quando preferir distinções mais finas.
