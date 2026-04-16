# Pacote de agentes — sistema_ro

Este pacote organiza agentes especializados por dimensão do plano do projeto `sistema_ro`, com um orquestrador central e uma base compartilhada.

## Estrutura
- `00_AGENT_ORQUESTRADOR_SISTEMA_RO.md`
- `AGENT_BASE_SHARED.md`
- `01_AGENT_FUNDACAO_GOVERNANCA.md`
- `02_AGENT_EXTRACAO_BRONZE.md`
- `03_AGENT_NORMALIZACAO_SILVER.md`
- `04_AGENT_NUCLEO_MERCADORIAS_AGREGACAO.md`
- `05_AGENT_CONVERSAO_UNIDADES.md`
- `06_AGENT_ENRIQUECIMENTO_FISCAL_SEFIN.md`
- `07_AGENT_MOVIMENTACAO_ESTOQUE.md`
- `08_AGENT_DERIVACOES_ANALITICAS_ESTOQUE.md`
- `09_AGENT_BACKEND_API.md`
- `10_AGENT_FISCONFORME.md`
- `11_AGENT_FRONTEND_OPERACIONAL.md`
- `12_AGENT_TESTES_RECONCILIACAO.md`
- `INTEGRACAO_ENTRE_AGENTES.md`

## Uso recomendado
1. Comece pelo orquestrador.
2. Ele delega para o agente especialista por dimensão.
3. Todos os agentes obedecem às regras compartilhadas do `AGENT_BASE_SHARED.md`.

## Base normativa principal
O arquivo `AGENT_EXECUCAO_PROJETO.md` é a base canônica deste pacote.

Todos os agentes especialistas e o orquestrador devem obedecer integralmente:
- as regras Oracle x Polars;
- as políticas `cache-first` e `bronze-first`;
- o checklist obrigatório antes de criar nova SQL;
- os metadados e requisitos de lineage;
- o formato de resposta A–E.

Em caso de conflito entre um agente especialista e a base normativa, prevalece `AGENT_EXECUCAO_PROJETO.md`.
