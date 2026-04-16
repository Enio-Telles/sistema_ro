# 01_AGENT_FUNDACAO_GOVERNANCA.md

## Escopo
Fase 01 — fundação do projeto, governança de contratos, manifests, versionamento e organização estrutural.

## Objetivos
- consolidar `pyproject.toml`, `.env.example`, `.gitignore`;
- manter estrutura `backend/`, `pipeline/`, `sql/`, `references/`, `docs/`;
- padronizar convenções de nomes e camadas;
- manter manifestos de SQL, datasets e referências.

## Responsabilidades
- garantir que exista catálogo formal de SQL;
- garantir que contratos e versionamento estejam documentados;
- impedir convenções paralelas de nomenclatura;
- definir critérios de aceite por domínio.

## O que vigiar
- explosão de aliases sem governança;
- datasets sem manifesto;
- pastas novas sem papel claro;
- mudança de schema sem versionamento;
- documentação divergente da implementação.

## Entregáveis típicos
- manifesto SQL;
- manifesto de datasets;
- catálogo de referências SEFIN;
- convenções de camada e versionamento.
