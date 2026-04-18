# AGENT - Frontend (frontend/)

Este agente cobre a interface web e desktop (React e Tauri) presente em `frontend/`.
O frontend existe para servir a experiencia operacional do usuario sem replicar logica fiscal, sem criar contratos paralelos e sem misturar manutencao com navegacao analitica principal.

## Responsabilidades

- prover uma interface operacional baseada em tabelas, filtros, ordenacao, exportacao e rastreabilidade;
- manter separacao explicita entre `Area do Usuario` e `Area Tecnica`;
- organizar a navegacao principal do usuario em:
  - `EFD`
  - `Documentos Fiscais`
  - `Analise Fiscal`
- consumir somente APIs oficiais e contratos estaveis do backend;
- preservar estado de CNPJ, aba, filtros, colunas e contexto de exploracao.

## Estado atual confirmado

- a shell React + TypeScript ja existe neste diretorio;
- a estrutura `src-tauri/` deve ser mantida como casca desktop oficial;
- o primeiro modulo funcional entregue e `Analise Fiscal > Estoque`;
- `EFD` e `Documentos Fiscais` ja existem na navegacao, mas continuam como placeholders honestos;
- a `Area Tecnica` existe para status, pipeline, consistencia e qualidade, sem poluir a experiencia principal do usuario.

## Regras obrigatorias

- nao abrir nova frente de UI antes de estabilizar o modulo funcional atual;
- nao implementar logica fiscal, agregacao ou reconciliacao no cliente;
- nao criar SQL nova por necessidade de tela;
- nao consumir rotas legadas quando houver superficie oficial equivalente;
- manter a abordagem Tauri, mesmo quando a validacao local ocorrer pelo frontend web;
- refletir qualquer mudanca de contrato de API no frontend e nos testes no mesmo trabalho.

## Contrato de UX

Toda tabela relevante deve suportar, quando aplicavel:

- filtro textual;
- filtros por coluna;
- ordenacao;
- selecao de colunas;
- paginacao ou virtualizacao;
- exportacao;
- persistencia local de contexto;
- destaque em nova aba interna com contexto preservado.

## Separacao de dominio

- `EFD` deve conter apenas dados e relacoes de escrituracao;
- `Documentos Fiscais` deve conter notas fiscais, CT-e, Fisconforme, Fronteira e modulos documentais equivalentes;
- cruzamentos entre escrituracao e documentos pertencem a `Analise Fiscal`;
- detalhes tecnicos de operacao pertencem a `Area Tecnica`, nunca a navegacao principal do usuario.

## Anti-padroes

- processar grandes volumes no navegador;
- requisicoes sem paginacao para datasets densos;
- esconder estado vazio ou parquet ausente com sucesso ficticio;
- criar UI que misture manutencao com experiencia analitica;
- introduzir componente novo quando um componente compartilhado resolver o caso.
