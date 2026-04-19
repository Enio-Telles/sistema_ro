# Google Stitch MCP — Integração com GitHub Copilot

## Objetivo

- Documentar a configuração do Model Context Protocol (MCP) do Google Stitch para uso com o GitHub Copilot, usando o proxy stdio (`@_davideast/stitch-mcp`) para evitar problemas de autenticação.

## Pré‑requisitos

- VS Code com extensão GitHub Copilot ativa.
- Node.js + npm (verifique com `node -v` e `npm -v`).
- Acesso ao Stitch (`https://stitch.withgoogle.com`).
- `npx` disponível no PATH.

## 1) Obter a Chave de API do Stitch

- Acesse `https://stitch.withgoogle.com`.
- Clique no ícone do perfil → `Stitch settings` → seção `API key`.
- Clique em `Create key` e copie a chave. Guarde em local seguro (não commitá-la).

## 2) Configurar o Servidor MCP no VS Code

- Abra a Command Palette (`Ctrl+Shift+P`) → `GitHub Copilot: Configure MCP Servers`.
- No arquivo de configuração do Copilot (perfil do usuário), adicione a entrada abaixo no objeto `servers` e a entrada correspondente em `inputs`:

```json
{
  "servers": {
    "google-stitch": {
      "type": "stdio",
      "command": "npx",
      "args": [
        "-y",
        "@_davideast/stitch-mcp",
        "proxy"
      ],
      "env": {
        "STITCH_API_KEY": "${input:STITCH_API_KEY}"
      }
    }
  },
  "inputs": [
    {
      "id": "STITCH_API_KEY",
      "type": "promptString",
      "description": "Insira sua API Key do Google Stitch",
      "password": true
    }
  ]
}
```

### Por que usar stdio / proxy?

- O proxy gerencia cabeçalhos de autenticação e persistência da conexão, evitando 401 e problemas ao chamar diretamente o endpoint HTTP.

## 3) Ativação e Verificação

- Salve o JSON; o VS Code pode solicitar o valor `STITCH_API_KEY`.
- Abra o chat do Copilot e, no topo, preencha a chave quando solicitado.
- Para validar: no chat do Copilot execute:

```
@copilot use mcp list my Stitch projects
```

Se listar seus projetos, a integração está correta.

## Casos de uso recomendados

- Implementação de componentes React a partir do design no Stitch.
- Sincronização e inspeção de design tokens (cores, espaços).
- Verificação de conformidade visual de trechos de código com o protótipo.

## Solução de problemas

- `command not found` para `npx`: verifique `npx -v` e PATH.
- Permissões WSL/Ubuntu: ajuste permissões do diretório `.npm` ou instale Node.js para o usuário.
- Chave inválida: gere nova chave em Stitch e reinicie VS Code.
- Se o Copilot não conseguir listar projetos, reinicie o chat do Copilot e confirme o input.

## Segurança e boas práticas

- Nunca commit: `STITCH_API_KEY`, `STITCH_ACCESS_TOKEN` ou `GITHUB_TOKEN`.
- Adicione um `.env.example` com placeholders (ex.: `STITCH_API_KEY=`).
- Use GitHub Secrets para CI. Se um segredo foi acidentalmente commitado, rotacione a chave imediatamente e remova o item do histórico (ferramentas: `git filter-repo`).
- Checklist de PR: validar que nenhum segredo está no diff.

## Comandos sugeridos (manualmente)

```bash
git checkout -b feature/stitch-mcp
# crie/cole os arquivos: docs/34_google_stitch_mcp.md e .env.example
git add docs/34_google_stitch_mcp.md .env.example
git commit -m "docs: add Google Stitch MCP setup guide and .env.example"
# git push --set-upstream origin feature/stitch-mcp
```

## Notas finais

- Identifiquei chaves em `.env` no workspace; recomenda-se não commitar e rotacionar se necessário.
