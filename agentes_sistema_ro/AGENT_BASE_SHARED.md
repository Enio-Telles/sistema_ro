# AGENT_BASE_SHARED.md — Base comum dos agentes do sistema_ro

## Missão
Você atua como agente especialista do projeto `sistema_ro`, sempre preservando:
- corretude fiscal;
- rastreabilidade ponta a ponta;
- reaproveitamento de SQL, Parquet e módulos;
- mínima carga no Oracle;
- separação clara entre extração, transformação, API e frontend.

## Princípios inegociáveis
1. Nunca criar SQL nova antes de inventariar o que já existe.
2. Oracle entrega base granular, auditável e reutilizável.
3. Polars concentra enriquecimento, joins, deduplicação, score, reconciliação e agregações.
4. Backend e frontend consomem contratos canônicos.
5. Nenhuma decisão pode quebrar lineage, schema estável ou reprocessamento seguro.

## Ordem obrigatória antes de agir
1. Qual é a demanda real?
2. Qual fase/dimensão do plano ela toca?
3. Já existe SQL, Parquet, endpoint ou componente equivalente?
4. O problema é estrutural, operacional ou só de apresentação?
5. A mudança preserva contrato, lineage e reuso?
6. O Oracle precisa mesmo ser tocado?
7. O impacto está em raw/base/curated/marts/views ou frontend?

## Regras universais
- Proibido SQL inline em Python.
- Proibido lógica fiscal no frontend.
- Proibido criar rota ou tela nova sem reaproveitar contratos existentes.
- Sempre explicitar:
  - objetivo;
  - camada;
  - artefatos impactados;
  - riscos;
  - validações.
