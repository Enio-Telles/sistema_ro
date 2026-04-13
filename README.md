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

Repositório inicializado com scaffolding, plano e contratos de dados.
A próxima evolução é implementar os serviços reais por fase, seguindo os documentos em `docs/`.
