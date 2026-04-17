# sistema_ro

Projeto de auditoria fiscal orientado a mercadorias, com foco em:

- rastreabilidade de itens e agregacao de produtos;
- conversao de unidades com override manual;
- estoque derivado de movimentacao cronologica;
- enriquecimento SEFIN e derivados fiscais;
- trilha operacional de Fisconforme.

## Principios

1. A mercadoria e o centro do dominio.
2. O fio de ouro deve preservar a trilha `linha original -> id_linha_origem -> codigo_fonte -> mercadoria/apresentacao -> id_agrupado -> tabelas analiticas`.
3. SQL fica como bronze; harmonizacao, agregacao, conversao, estoque e Fisconforme analitico ficam em Python/Polars.
4. Contratos de estoque, agregacao e conversao devem priorizar corretude, rastreabilidade e estabilidade.

## Estrutura

- `docs/`: planejamento, status, contratos e documentacao operacional.
- `backend/`: APIs FastAPI de silver, gold, status e Fisconforme.
- `pipeline/`: extracao, normalizacao, agregacao, conversao, estoque e Fisconforme.
- `sql/`: consultas base e auxiliares.
- `references/`: manifestos e instrucoes das referencias obrigatorias.

## Superficies oficiais

- silver com preparo SEFIN: `backend.app.runtime_silver_v2:app` em `/api/v5b/silver`
- gold oficial: `backend.app.runtime_gold_current_v2:app` em `/api/current-v2`
- fisconforme modular: `backend.app.runtime_gold_current_v5:app` em `/api/current-v5/fisconforme-v2`
- descoberta e orientacao principal: `backend.app.runtime_main:app` em `/api/main`

## Endpoints principais

Status resumido por CNPJ:

- `GET /api/current-v2/status/{cnpj}`
- `GET /api/current-v5/status/{cnpj}`

Esse status informa:

- prontidao de referencias, silver, gold e SEFIN;
- faltas por etapa;
- `next_action` operacional;
- alerta quando o gold existe, mas a cobertura temporal SEFIN nas abas fiscais e parcial;
- superficies recomendadas para silver, gold e Fisconforme.

Status da execucao gold oficial:

- `GET /api/current-v2/pipeline/{cnpj}/status`
- `GET /api/gold20/pipeline/{cnpj}/status`
- `GET /api/current-v5/pipeline/{cnpj}/status`
- `GET /api/gold25/pipeline/{cnpj}/status`

Esse status informa:

- validacao de inputs;
- origem selecionada dos itens;
- contexto SEFIN, referencias faltantes e vigencia temporal utilizavel em runtime;
- resumo de qualidade da conversao antes da execucao.

Execucao gold oficial:

- o `run` passa a expor cobertura temporal efetiva de `aba_mensal`, `aba_anual` e `aba_periodos`;
- a nao cobertura e detalhada por motivo, como `sem_co_sefin` e `sem_intersecao_temporal`.

Superficie principal de orientacao:

- `GET /api/main/runtime-overview`
- `GET /api/main/surfaces`
- `GET /api/main/surfaces/catalog`
- `GET /api/main/decommission`

Preparo silver com diagnostico SEFIN:

- `POST /api/v5b/silver/{cnpj}/prepare-sefin`

## Foco atual

As proximas entregas devem continuar em:

- aderencia funcional do estoque;
- refinamento das regras temporais de ST e vigencia SEFIN;
- reducao de redundancia entre runtimes e contratos operacionais.
