# AGENT – Backend (backend/)

Este agente abrange o código Python/FastAPI localizado em `backend/`. O backend serve como interface entre as pipelines e os consumidores de dados.

## Responsabilidades

- **Expor APIs estáveis** que forneçam acesso a dados auditáveis e métricas analíticas.
- **Orquestrar execuções de pipelines** quando requisitado (por exemplo, iniciar reprocessamento para um CNPJ e período).
- **Validar entradas** (período, CNPJ, filtros) e garantir que as respostas estejam de acordo com contratos definidos.
- **Preservar rastreabilidade**: incluir, nas respostas, informações que permitam reverter ou auditar os dados (datas de corte, versão de pipeline, chaves).
- **Documentar endpoints** com Swagger/OpenAPI, indicando parâmetros, exemplos e campos retornados.

## Convenções

- Defina **schemas** de entrada e saída usando Pydantic.
- Versão as rotas (ex.: `/api/v1/mercadorias`). Mantenha contratos retrocompatíveis quando possível; para breaking changes, implemente versão nova e documente a transição.
- Implemente logs estruturados contendo CNPJ, período, rota e status.
- Não execute cálculos ou transformações pesadas no endpoint; delegue ao pipeline ou leia resultados prontos dos Parquets.
- Respeite as políticas de segurança e autenticação quando necessário.

## Anti‑padrões

- Colocar lógica de agregação ou transformação dentro da rota.
- Expor campos sem documentação, tornando contratos ambíguos.
- Criar novas rotas sem considerar reaproveitamento de endpoints existentes.

## Formato A–E

Ao planejar novos endpoints ou alterações, utilize a estrutura A–E, listando dados reutilizáveis, justificando escolhas e definindo plano de execução com testes e compatibilidade.
