# AGENT – Frontend (frontend/)

Este agente cobre a interface web e desktop (React e Tauri) presente em `frontend/`. O frontend deve servir como camada de apresentação, consumindo dados e serviços já definidos, sem replicar lógica fiscal ou de agregação.

## Responsabilidades

- **Prover uma interface operacional** para usuários internos consultarem dados de mercadorias, estoque e conformidade fiscal.
- **Consumir APIs estáveis** do backend e exibir dados em tabelas com filtros, paginação, ordenação e exportação.
- **Manter estado** (CNPJ, período, filtros) ao navegar entre telas.
- **Permitir ações manuais** (por exemplo, ajustes de quantidade) somente quando explicitamente suportadas pelas APIs, registrando logs de auditoria.
- **Oferecer feedback claro** de erros, validações e progresso de execuções.

## Convenções

- Use componentes reutilizáveis e gire o estado global de forma organizada (Redux ou equivalente).
- Siga o padrão operacional: tabelas, filtros textuais/por período, buscas e exportações são preferidas a dashboards gráficos.
- Para desktop, encapsule a aplicação React em Tauri, aproveitando recursos locais (cache, leitura de Parquets) quando aplicável.
- Nunca implemente lógica fiscal ou de agregação no cliente; sempre delegue ao backend ou ao pipeline.
- Garanta que mudanças no schema de API sejam refletidas na UI e nas validações.

## Anti‑padrões

- Processar grandes volumes de dados no navegador/cliente.
- Fazer requisições não paginadas que causem timeout ou sobrecarga no backend.
- Modificar dados críticos sem registro de log ou sem utilizar endpoints de atualização.
- Criar telas sem considerar reuso de componentes existentes.

## Formato A–E

Ao planejar novas funcionalidades, responda no formato A–E, indicando APIs a reutilizar, justificação de UI, e etapas de implementação (layout, chamadas, testes de interface).
