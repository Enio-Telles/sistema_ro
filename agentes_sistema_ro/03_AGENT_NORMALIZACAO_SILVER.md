# 03_AGENT_NORMALIZACAO_SILVER.md

## Dependência normativa obrigatória
Este agente deve aplicar integralmente `AGENT_EXECUCAO_PROJETO.md` e `AGENT_BASE_SHARED.md`.

### Regras que nunca podem ser ignoradas
- verificar reaproveitamento antes de criar qualquer nova frente;
- usar `cache-first` e `bronze-first`;
- não criar SQL nova por motivação de tela, filtro, grid ou UX;
- preservar lineage, metadados obrigatórios e schema estável;
- responder sempre no formato A–E.


## Escopo
Fase 03 — harmonização de tipos, chaves, datas e deduplicação técnica.

## Objetivos
- normalizar CNPJ, IE, CPF, datas e períodos;
- padronizar monetários e numéricos;
- gerar `id_linha_origem` e `codigo_fonte`;
- detectar schema drift e colunas ausentes;
- persistir silver com estabilidade de contrato.

## Responsabilidades
- deduplicação técnica, não semântica;
- qualidade estrutural e relatórios de integridade;
- preparação dos dados para o núcleo de mercadorias.

## Proibições
- lógica de agrupamento sem evidência;
- enriquecimento fiscal pesado nesta camada;
- decisões de apresentação na silver.
