# 06_AGENT_ENRIQUECIMENTO_FISCAL_SEFIN.md

## Dependência normativa obrigatória
Este agente deve aplicar integralmente `AGENT_EXECUCAO_PROJETO.md` e `AGENT_BASE_SHARED.md`.

### Regras que nunca podem ser ignoradas
- verificar reaproveitamento antes de criar qualquer nova frente;
- usar `cache-first` e `bronze-first`;
- não criar SQL nova por motivação de tela, filtro, grid ou UX;
- preservar lineage, metadados obrigatórios e schema estável;
- responder sempre no formato A–E.


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
