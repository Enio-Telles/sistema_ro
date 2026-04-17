# sistema_ro

Projeto base para auditoria fiscal orientada a mercadorias, com ênfase em:

- identificação e rastreabilidade de mercadorias;
- agregação auditável de produtos;
- conversão de unidades com preservação de override manual;
- análise de estoque derivada de movimentação cronológica;
- fluxo de Fisconforme não atendido com consulta individual, lote, cache e notificações.

## Princípios

1. A mercadoria é o centro do domínio.
2. O fio de ouro deve preservar o caminho `linha original -> id_linha_origem -> codigo_fonte -> mercadoria_id/apresentacao_id -> id_agrupado -> tabelas analíticas`.
3. SQL entra como camada bronze; harmonização, agregação, conversão, classificação fiscal, estoque e Fisconforme analítico entram como silver/gold em Python/Polars.
4. Estoque, agregação e conversão seguem os contratos funcionais já consolidados no projeto.

## Estrutura inicial

- `docs/` — plano de 16 fases, manifesto de dados e frontend detalhado.
- `backend/` — API FastAPI para agregação, conversão, estoque e Fisconforme.
- `pipeline/` — extração, normalização, mercadorias, conversão, estoque e fisconforme.
- `sql/` — consultas core e auxiliares.
- `references/` — manifests das referências estáticas e dos Parquets obrigatórios.

## Status

O repositório já possui execução técnica relevante nas trilhas de silver, gold e superfícies operacionais.

Superfícies oficiais atuais:

- gold: `backend.app.runtime_gold_current_v2:app` com prefixo `/api/current-v2`
- fisconforme modular: `backend.app.runtime_gold_current_v5:app` com prefixo `/api/current-v5/fisconforme-v2`
- entrypoint principal de descoberta/orientação: `backend.app.runtime_main:app` com prefixo `/api/main`

Status resumido por CNPJ:

- `GET /api/current-v2/status/{cnpj}`
- `GET /api/current-v5/status/{cnpj}`

Esse endpoint informa:

- prontidão de referências, silver, gold e SEFIN;
- listas de datasets ou referências faltantes por etapa;
- próxima ação operacional recomendada;
- superfícies oficiais recomendadas para gold e Fisconforme.

Status de prontidão da execução gold oficial:

- `GET /api/current-v2/pipeline/{cnpj}/status`
- `GET /api/gold20/pipeline/{cnpj}/status`

Esse endpoint informa:

- validação dos inputs do gold;
- origem selecionada dos itens;
- contexto SEFIN e referências ausentes;
- resumo operacional da qualidade de conversão antes da execução.

Superfície principal de orientação:

- `GET /api/main/runtime-overview`
- `GET /api/main/surfaces`
- `GET /api/main/surfaces/catalog`
- `GET /api/main/decommission`

Essa superfície consolida o apontamento para `current-v2` e `current-v5` sem substituir os aliases operacionais.

As próximas evoluções seguem concentradas em:

- aderência funcional do estoque;
- integração mais consistente da vigência SEFIN;
- consolidação gradual das runtimes redundantes.
