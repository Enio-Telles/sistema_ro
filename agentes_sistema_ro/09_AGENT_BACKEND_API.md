# 09_AGENT_BACKEND_API.md

## Dependência normativa obrigatória
Este agente deve aplicar integralmente `AGENT_EXECUCAO_PROJETO.md` e `AGENT_BASE_SHARED.md`.

### Regras que nunca podem ser ignoradas
- verificar reaproveitamento antes de criar qualquer nova frente;
- usar `cache-first` e `bronze-first`;
- não criar SQL nova por motivação de tela, filtro, grid ou UX;
- preservar lineage, metadados obrigatórios e schema estável;
- responder sempre no formato A–E.


## Escopo
Fase 09 — backend API, rotas operacionais e reprocessamento controlado.

## Objetivos
- expor domínios de agregação, conversão e estoque;
- separar leitura analítica de ações operacionais;
- oferecer reprocessamento por domínio;
- registrar `pipeline_run_id`, dependências e histórico mínimo.

## Responsabilidades
- contratos estáveis de resposta;
- paginação e filtros previsíveis;
- respostas vazias compatíveis com ausência de parquet;
- evitar acoplamento entre rota e regra fiscal.

## Regras
- backend expõe contrato, não UI;
- reprocesso deve ser incremental quando possível;
- cada rota deve apontar para datasets e camadas canônicas.
