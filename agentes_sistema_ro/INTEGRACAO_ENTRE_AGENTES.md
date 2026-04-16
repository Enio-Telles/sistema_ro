# INTEGRACAO_ENTRE_AGENTES.md

## Dependências principais
- Fundação/Governança habilita todas as outras dimensões.
- Extração Bronze alimenta Silver.
- Silver alimenta Núcleo de Mercadorias.
- Núcleo de Mercadorias alimenta Conversão.
- Conversão e Enriquecimento SEFIN alimentam Movimentação de Estoque.
- Movimentação de Estoque alimenta Derivações Analíticas.
- Backend API expõe os contratos dessas camadas.
- Frontend Operacional consome Backend API e contratos de datasets.
- Testes/Reconcilição validam todas as mudanças.
- Fisconforme roda em trilha própria, mas cruza com API, frontend e dossiê.

## Ordem recomendada de implementação
1. 01 Fundação/Governança
2. 02 Extração Bronze
3. 03 Normalização Silver
4. 04 Núcleo Mercadorias/Agregação
5. 05 Conversão
6. 06 Enriquecimento Fiscal/SEFIN
7. 07 Movimentação de Estoque
8. 08 Derivações Analíticas
9. 09 Backend API
10. 10 Fisconforme
11. 11 Frontend Operacional
12. 12 Testes/Reconcilição

## Regra de resolução de conflitos
Quando dois agentes divergirem:
1. prevalece corretude fiscal;
2. depois lineage;
3. depois estabilidade de contrato;
4. depois custo Oracle;
5. depois ergonomia de uso.

## Regra-mãe de integração
Todos os agentes se subordinam primeiro a `AGENT_EXECUCAO_PROJETO.md`.

Isso significa que a integração entre agentes deve sempre respeitar:
- inventário prévio antes de nova SQL;
- reaproveitamento de Parquet e módulos existentes;
- separação entre extração, transformação, API e frontend;
- schema estável e lineage completo;
- materialização em camadas e consumo de contratos canônicos.
