# Como usar este setup com Codex

## O que o Codex lê
O Codex lê arquivos `AGENTS.md` antes de começar a trabalhar.
A regra é por escopo de diretório:
- um `AGENTS.md` na raiz vale para o repositório inteiro
- um `AGENTS.md` dentro de uma subpasta vale para aquela árvore específica
- arquivos mais específicos complementam os mais gerais

## Estrutura deste setup
- `AGENTS.md` → instruções globais do repositório
- `backend/AGENTS.md` → regras da API/FastAPI
- `frontend/AGENTS.md` → regras da UI React
- `bronze/AGENTS.md` → extração base
- `silver/AGENTS.md` → normalização e deduplicação
- `gold/AGENTS.md` → agregação e cálculo analítico
- `fisconforme/AGENTS.md` → regras do módulo Fisconforme
- `state/AGENTS.md` → persistência de estado
- `tests/AGENTS.md` → regras para testes
- `docs/AGENTS.md` → regras para documentação

## Como aplicar
1. copie esses arquivos para a raiz do repositório
2. commit e push
3. abra o projeto no Codex CLI, app ou ambiente integrado
4. rode uma tarefa como:
   - Planeje uma alteração em `gold/` preservando rastreabilidade e reprocessamento.
   - Revise uma mudança em `frontend/` considerando contratos estáveis, tabela operacional e performance.
   - Sugira um plano de 3 PRs para uma mudança sensível em `backend/` e `gold/`.

## Dica prática
Ajuste depois os comandos reais de teste/lint do repositório dentro do `AGENTS.md` se quiser deixar o agente ainda mais obediente.
