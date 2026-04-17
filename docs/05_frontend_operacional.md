# Frontend operacional do sistema_ro

## Estado atual confirmado

O frontend real passou a existir em `frontend/` como shell React + TypeScript, com estrutura `src-tauri/` preservando a abordagem Tauri.

Nesta etapa, o escopo funcional entregue foi:

- separação explícita entre `Área do Usuário` e `Área Técnica`;
- navegação principal canônica em:
  - `EFD`
  - `Documentos Fiscais`
  - `Análise Fiscal`
- módulo funcional inicial em `Análise Fiscal > Estoque`;
- consumo exclusivo das superfícies oficiais `main` e `current-v2`.

`EFD` e `Documentos Fiscais` já aparecem na navegação, mas seguem como placeholders honestos até que o escopo atual esteja integralmente estabilizado.

## Organização obrigatória da navegação

### Área do Usuário

#### 1. EFD
- conter somente visualizações e navegação estritamente ligadas à escrituração;
- não misturar documentos fiscais externos;
- não misturar cruzamentos analíticos.

#### 2. Documentos Fiscais
- concentrar notas fiscais, CT-e, Fisconforme, Fronteira e consultas equivalentes;
- focar consulta, comparação, filtro e inspeção documental;
- não confundir documento fiscal com escrituração.

#### 3. Análise Fiscal
- concentrar cruzamentos, verificações, inconsistências, conciliações e análises complexas;
- cruzamentos entre EFD e documentos fiscais pertencem aqui;
- o primeiro módulo funcional desta etapa é `Estoque`.

### Área Técnica

- concentrar operação, qualidade, consistência, status de pipeline e apoio à manutenção;
- não poluir a navegação principal do usuário com metadados operacionais.

## Módulo funcional atual: Análise Fiscal > Estoque

### Subabas entregues

- `Movimentação`
- `Mensal`
- `Anual`
- `Períodos`
- `Resumo`
- `Alertas`

### Contrato funcional

Cada subaba consome:

- overview oficial: `GET /api/current-v2/estoque/{cnpj}/overview`
- tabela operacional: `GET /api/current-v2/estoque/{cnpj}/tabelas/{dataset}`
- exportação CSV: `GET /api/current-v2/estoque/{cnpj}/tabelas/{dataset}/export`

Datasets aceitos nesta etapa:

- `mov_estoque`
- `aba_mensal`
- `aba_anual`
- `aba_periodos`
- `estoque_resumo`
- `estoque_alertas`

## Área Técnica atual

O frontend lê as seguintes superfícies de apoio operacional:

- `GET /api/current-v2/status/{cnpj}`
- `GET /api/current-v2/pipeline/{cnpj}/status`
- `GET /api/current-v2/gold/{cnpj}`
- `GET /api/current-v2/estoque/{cnpj}/quality`

Essas leituras servem para operação, qualidade e consistência e não substituem a experiência analítica principal do usuário.

## Contrato de UX transversal

Toda tabela relevante deve suportar, quando aplicável:

- filtro textual;
- filtros por coluna;
- paginação;
- seleção de colunas;
- ordenação;
- persistência local do contexto;
- exportação CSV;
- destaque em nova aba interna;
- reabertura com contexto preservado pela rota e pelo armazenamento local.

## Regra para destaque em nova aba

`Destacar em nova aba` significa:

- abrir uma nova aba interna da aplicação;
- manter filtros, ordenação, colunas e paginação;
- serializar o estado ativo na rota;
- persistir o mesmo estado localmente para reabertura sem perda funcional.

Nesta etapa, isso não significa abrir nova janela nativa do sistema operacional.

## Regras de implementação contínua

- não implementar lógica fiscal no cliente;
- não criar SQL nova por demanda de UX;
- não consumir rotas legadas simples quando houver superfície oficial;
- não expandir `EFD` ou `Documentos Fiscais` antes de estabilizar o módulo atual de estoque;
- manter Tauri como casca desktop oficial, mesmo quando a validação corrente ocorrer pelo frontend web.
