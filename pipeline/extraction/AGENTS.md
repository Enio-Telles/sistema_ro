# AGENT – Extração (pipeline/extraction)

Este agente abrange os scripts de extração de dados da camada **raw** em `pipeline/extraction/`.

## Responsabilidades

- **Extrair dados brutos** do Oracle ou outras fontes de forma idempotente, respeitando filtros de período e CNPJ.
- **Documentar** a origem das extrações (tabelas, filtros) e a finalidade de uso.
- **Gerar Parquet** ou arquivos temporários correspondentes, com registro de schema e chaves.
- **Controlar custos** e carga no Oracle, extraindo apenas as colunas e linhas necessárias.

## Convenções

- Utilize manifestos SQL em `sql/` e evite consultas em hard-coded dentro de scripts.
- Antes de extrair, verifique se o dataset raw já existe no cache/local para o mesmo período e CNPJ (`cache-first`).
- Registre logs: tabela(s) consultadas, intervalo de datas, filtros, tempo gasto e número de linhas.
- Separe as extrações por domínio (por exemplo, NFe, CTe, Documentos fiscais).
- Mantenha scripts idempotentes e teste-os com dados reduzidos antes de rodar em produção.

## Anti‑padrões

- Executar `SELECT *` em grandes tabelas sem filtros.
- Misturar transformação ou agregação no processo de extração.
- Reexecutar extrações desnecessariamente em períodos já processados.
