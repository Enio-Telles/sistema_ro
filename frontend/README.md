# Frontend do sistema_ro

Este diretório passa a conter a shell operacional React + TypeScript com casca Tauri para o `sistema_ro`.

## Objetivo desta etapa

- separar `Área do Usuário` e `Área Técnica`;
- organizar a navegação do usuário em `EFD`, `Documentos Fiscais` e `Análise Fiscal`;
- entregar o primeiro módulo funcional em `Análise Fiscal > Estoque`;
- consumir somente superfícies oficiais do backend.

## Comandos

- `npm install`
- `npm run dev`
- `npm run test`
- `npm run build`

## Tauri

A estrutura `src-tauri/` está presente para preservar a abordagem desktop baseada em Tauri.
Neste ambiente, a validação principal desta entrega ocorre pelo frontend web porque `cargo` e `rustc` não estão instalados.
