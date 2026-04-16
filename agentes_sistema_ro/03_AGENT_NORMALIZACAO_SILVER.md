# 03_AGENT_NORMALIZACAO_SILVER.md

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
