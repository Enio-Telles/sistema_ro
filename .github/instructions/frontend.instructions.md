---
applyTo: "**/*.tsx,**/*.ts,**/components/**/*,**/pages/**/*,**/app/**/*"
---

# Frontend Instructions — sistema_ro

## Papel do frontend
- O frontend é operacional, orientado a tabela, revisão e rastreabilidade.
- Não duplique regra fiscal ou analítica no cliente.
- Consuma contratos estáveis do backend.

## UX obrigatória
Ao sugerir telas:
- foco em tabela operacional
- filtro textual e por período
- paginação
- seleção, ordem e largura de colunas quando fizer sentido
- persistência de contexto por aba
- exportação
- destaque visual apenas para anomalias reais

## Boas práticas
- Componentize sem exagero.
- Evite estado global desnecessário.
- Prefira componentes legíveis e fáceis de revisar.
- Não crie dashboards decorativos como solução padrão.

## Performance
- Considere datasets grandes.
- Evite renderização excessiva.
- Planeje paginação, virtualização ou carregamento incremental quando necessário.

## Contratos
- Não inferir campos sem contrato.
- Não mascarar inconsistência de dados no frontend.
- Em caso de dado instável, sinalize problema no contrato ou pipeline.
