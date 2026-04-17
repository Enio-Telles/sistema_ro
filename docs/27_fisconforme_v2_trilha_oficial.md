# Fisconforme V2 — Trilha Oficial Recomendada

## Objetivo

Declarar a trilha modular `fisconforme-v2` como caminho recomendado para operacao e evolucao do Fisconforme no `sistema_ro`.

## Runtime recomendada

Para operacao corrente, usar preferencialmente:

- `backend/app/runtime_gold_current_v5.py`
- prefixo `/api/current-v5`

Para diagnostico por versao:

- `backend/app/runtime_gold_v25.py`
- prefixo `/api/gold25`

## Rotas legadas e recomendadas

### Legado

- `/api/current-v5/fisconforme`
- `/api/gold25/fisconforme`

Essas rotas permanecem por compatibilidade e comparacao, mas nao devem ser a referencia principal para novas evolucoes.

### Recomendadas

- `/api/current-v5/fisconforme-v2/{cnpj}`
- `/api/current-v5/fisconforme-v2/lote`
- `/api/current-v5/fisconforme-v2/cache/stats`
- `/api/current-v5/fisconforme-v2/{cnpj}/refresh`
- `/api/current-v5/fisconforme-v2/refresh-lote`
- `/api/current-v5/fisconforme-v2/dsfs`
- `/api/current-v5/fisconforme-v2/notificacao-v3`
- `/api/current-v5/fisconforme-v2/notificacoes-lote-v3/download`
- `/api/current-v5/fisconforme-v2/notificacao-docx-v2`
- `/api/current-v5/fisconforme-v2/notificacao-docx-v2/download`
- `/api/current-v5/fisconforme-v2/recommendation/`

## Blocos cobertos na trilha v2

- cache e overview;
- consulta individual e lote;
- refresh Oracle/SQL runner;
- acervo DSF;
- notificacao TXT com template externo;
- ZIP em lote;
- DOCX modular.

## Motivo da recomendacao

A trilha `fisconforme-v2` foi escolhida como principal porque:

- separa cache, extracao, acervo, notificacao e saida documental em modulos menores;
- evita repetir o router monolitico do `audit_react`;
- permite evolucao incremental com menor risco de regressao.

## Observacao

A equivalencia funcional com o legado ficou muito proxima, mas o layout final dos artefatos ainda pode diferir do `audit_react` conforme o ambiente, especialmente na conversao de PDF para imagem e na renderizacao do DOCX.
