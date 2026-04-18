# AGENT – SQL (sql/)

Este agente se aplica ao diretório `sql/`, onde ficam centralizados os manifestos e templates de extração SQL utilizados pelas pipelines do `sistema_ro`.

## Responsabilidades

- **Centralizar consultas reutilizáveis** para extrair dados do Oracle ou outras fontes.
- **Documentar** cada script, indicando tabelas de origem, filtros, parâmetros (período, CNPJ), colunas retornadas e chaves para integração.
- **Padronizar nomenclatura** e estrutura das consultas para facilitar a manutenção e a reutilização.

## Convenções

- Organize scripts por camada (`raw/`, `base/`) ou por domínio (mercadorias, estoques, sefin).
- Nomeie arquivos de forma clara (por exemplo, `extracao_nfe_raw.sql`, `normalizacao_blocos_base.sql`).
- Não inclua atualizações (`INSERT`, `UPDATE`, `DELETE`) nesses scripts; eles devem ser apenas de leitura.
- Utilize parâmetros para período (`:ano_mes`) e CNPJ (`:cnpj`) em vez de valores fixos.
- Registre, no início do arquivo, a data de criação, a finalidade e as dependências.

## Anti‑padrões

- Embutir SQL diretamente em código Python, FastAPI ou UI.
- Criar scripts sem documentação, dificultando a compreensão e a reutilização.
- Duplicar consultas semelhantes em vários lugares sem consolidar num único manifesto.
