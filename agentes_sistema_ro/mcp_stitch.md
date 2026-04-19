# MCP Integration — Stitch (stitch.withgoogle.com)

Objetivo
-------
Integrar o serviço Stitch (https://stitch.withgoogle.com/) como um provedor MCP (Model Context Protocol) para permitir chamadas de preview e discovered endpoints via contexto `context-matic`.

Contexto no sistema_ro
-----------------------
- Domínio: integração externa / enriquecimento de dados via serviço externo.
- Local recomendado: artefato de integração e manifesto em `agentes_sistema_ro/`.
- Backend: cliente stub em `backend/app/integrations/`.

Reaproveitamento possível
-------------------------
- Reaproveitar o padrão de manifestos MCP já existentes (se houver).
- Reutilizar a infraestrutura de leitura de parquets e preview local do `runtime`.

Arquitetura proposta
--------------------
- Manifesto MCP descrevendo `base_url`, auth (variáveis de ambiente), e endpoints expostos.
- Cliente backend leve (`StitchClient`) para encapsular autenticação e chamadas HTTP.
- Registro/manifesto consumível pelo servidor `context-matic` (manual ou via ferramenta).

Divisão por stack
-----------------
- Docs / manifesto: `agentes_sistema_ro/mcp_stitch.manifest.json` e `agentes_sistema_ro/mcp_stitch.md`
- Backend client: `backend/app/integrations/stitch_mcp.py`
- Config: variáveis de ambiente (ex.: `STITCH_CLIENT_ID`, `STITCH_CLIENT_SECRET`, `STITCH_API_KEY`)

Engenharia de software
----------------------
- Evitar hardcode de segredos: usar `.env` ou secrets manager.
- Testes: unitário para `StitchClient` (mocks) e integração de preview (com sandbox ou mocks).
- Observabilidade: logs contendo `CNPJ`, `período` e `request_id` quando aplicável.

GitHub
------
- Branch sugerida: `feat/integracao-stitch-mcp`.
- PR deve incluir: manifesto, client stub, instruções de configuração e checklist de testes.

Contratos e dados
-----------------
- Manifesto descreve endpoints suportados e esquema de entrada/saída (ex.: preview payload).
- Não armazenar credenciais em repo.

Estrutura de implementação (arquivos criados)
-------------------------------------------
- [agentes_sistema_ro/mcp_stitch.md](agentes_sistema_ro/mcp_stitch.md)
- [agentes_sistema_ro/mcp_stitch.manifest.json](agentes_sistema_ro/mcp_stitch.manifest.json)
- [backend/app/integrations/stitch_mcp.py](backend/app/integrations/stitch_mcp.py)

Plano de execução (curto prazo)
-------------------------------
1. Preencher `mcp_stitch.manifest.json` com URLs e fluxo de auth reais.
2. Adicionar credenciais seguras em `.env` / secrets manager.
3. Implementar e testar `StitchClient.preview()` com mocks ou sandbox.
4. Registrar o manifesto no servidor `context-matic` (ou fornecer instruções para registro manual).
5. Criar PR pequena e revisável.

Riscos e decisões críticas
-------------------------
- Autenticação desconhecida: confirmar se Stitch usa OAuth2, API key, ou outro fluxo.
- Limites de uso / rate limits: garantir retry/backoff e circuit-breaker nas chamadas.

MVP recomendado
---------------
- Manifesto com campos mínimos e `StitchClient.preview()` que faz uma chamada POST ao endpoint de preview com payload configurável e retorna JSON.

--
Preencha o manifesto com os detalhes de autenticação e endpoint; posso continuar e registrar no `context-matic` se quiser.
