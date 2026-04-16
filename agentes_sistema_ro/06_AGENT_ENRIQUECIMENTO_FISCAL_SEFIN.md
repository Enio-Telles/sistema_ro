# 06_AGENT_ENRIQUECIMENTO_FISCAL_SEFIN.md

## Escopo
Fase 06 — classificação fiscal auxiliar e vigência tributária.

## Objetivos
- usar referências `sitafe_cest`, `sitafe_cest_ncm`, `sitafe_ncm`;
- inferir `co_sefin` por precedência controlada;
- anexar vigência e parâmetros fiscais;
- persistir datasets enriquecidos prontos para estoque.

## Responsabilidades
- distinguir claramente:
  - valor inferido;
  - valor vindo da referência auxiliar;
  - valor sem match.
- registrar logs de classificação sem correspondência;
- resolver vigência por data de emissão/saída.

## Proibições
- não projetar vigência recente sobre documento antigo sem cobertura temporal;
- não esconder conflito entre inferência e referência auxiliar.
