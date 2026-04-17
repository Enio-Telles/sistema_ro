---
applyTo: "**/*.py,**/api/**/*.py,**/services/**/*.py,**/routers/**/*.py"
---

# Backend Instructions — sistema_ro

## Papel do backend
- O backend é a fonte principal da regra de negócio.
- Não empurre regra fiscal ou analítica para React.
- Prefira contratos explícitos com Pydantic.

## Organização
- Separe por domínio e camada.
- Evite arquivos “faz tudo”.
- Prefira módulos pequenos, coesos e testáveis.
- Nomeie funções e classes de forma precisa.

## API
- Rotas devem expor contratos estáveis.
- Evite respostas ad hoc ou sem schema.
- Indique claramente entradas, saídas, filtros e paginação.

## Dados
- Consuma datasets prontos e estáveis sempre que possível.
- Evite lógica SQL espalhada em handlers.
- Não acople endpoint diretamente a query improvisada se houver pipeline apropriado.

## Testes
- Inclua testes unitários para regra crítica.
- Inclua testes de integração para contratos e rotas.
- Valide casos de borda e regressão.

## Observabilidade
- Use logs úteis com contexto:
  - CNPJ
  - período
  - dataset
  - etapa de execução
- Trate falhas esperadas explicitamente.
