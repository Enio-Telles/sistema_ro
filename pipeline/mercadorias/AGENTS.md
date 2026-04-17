# AGENT – Mercadorias (pipeline/mercadorias)

Este agente cobre a camada **curated** de mercadorias em `pipeline/mercadorias/`.

## Responsabilidades

- **Agregar mercadorias** por `id_agrupado` (por exemplo, estabelecimento) e `id_agregado` (documento + produto + operação) calculando quantidades, valores e bases de impostos.  
- **Calcular tributos** (ICMS, IPI, PIS, COFINS, etc.) de acordo com as regras vigentes, mantendo base de cálculo e alíquotas armazenadas.  
- **Garantir integridade**: reconcilie os totais do `curated` com os dados raw/base.  
- **Gerar Parquet** com schema estável e versionado, pronto para ser consumido por etapas seguintes e pela API.

## Convenções

- Mantenha colunas de referência (`id_agrupado`, `id_agregado`, `id_documento_original`, `qtd`, `vl`, `vl_imposto`).  
- Evite descartar informações brutas; adicione colunas derivadas separadamente.  
- Use `cache-first`: procure se já existe um Parquet de mercadorias para o período/CNPJ antes de recalcular.  
- Documente as fórmulas de cálculo de cada tributo e mantenha tabela de alíquotas em `references/`.

## Anti‑padrões

- Misturar dados de mercadorias com dados de estoque ou fiscal em um mesmo script.  
- Alterar a forma de agregação sem notificar consumidores e atualizar contratos.  
- Deixar de reconciliar os totais de quantidades e valores com as bases de origem.