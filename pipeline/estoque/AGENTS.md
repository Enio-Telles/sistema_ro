# AGENT – Movimentação de Estoque (pipeline/estoque)

Este agente trata da camada de **estoque** em `pipeline/estoque/`.

## Responsabilidades

- **Construir o dataset `mov_estoque`**, calculando saldo inicial, entradas, saídas, ajustes e saldo final por CNPJ, estabelecimento e produto.  
- **Integrar movimentos** de mercadorias, conversões e ajustes fiscais.  
- **Reconciliar** movimentos com dados base (quantidades e valores) e com a camada fiscconforme.  
- **Gerar visões analíticas de estoque**, como giro, cobertura e pontos de reposição.

## Convenções

- Utilize chaves `id_agrupado` e `id_agregado` para ligar registros de estoque a mercadorias.  
- Inclua coluna de tipo de movimento (ex.: `entrada`, `saida`, `ajuste`, `inventario`).  
- Mantenha dataset idempotente: sempre recompute `mov_estoque` a partir de dados upstream ao invés de atualizar incrementalmente sem rastreio.  
- Documente as regras de reconciliacão e fórmulas de giro e cobertura.  
- Se a conversão de unidades impactar o saldo, reexecute a pipeline após atualização.

## Anti‑padrões

- Misturar derivação analítica avançada (KPIs complexos) no mesmo script de geração do movimento bruto; mantenha as derivativas separadas.  
- Manipular saldos manualmente sem registrar logs.  
- Esquecer de recalcular estoque ao mudar fatores de conversão ou ajustes de mercadorias.