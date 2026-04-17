# AGENT – Normalização (pipeline/normalization)

Este agente trata da camada **base** em `pipeline/normalization/`. O objetivo é preparar os dados brutos para agregação, garantindo consistência e qualidade.

## Responsabilidades

- **Tipar corretamente** todos os campos (strings, inteiros, decimais, datas).
- **Normalizar nomes e estruturas** de colunas, removendo sufixos e harmonizando nomenclaturas divergentes entre tabelas de origem.
- **Deduplicar registros** e aplicar filtros de qualidade (por exemplo, eliminar NFs canceladas se aplicável).
- **Gerar chaves consistentes** (`id_agrupado`, `id_agregado`) a partir das colunas raw.
- **Registrar schema** das tabelas base e mantê-lo estável ao longo do tempo.

## Convenções

- Crie funções reutilizáveis de normalização (por exemplo, para formatar campos de NCM, CFOP).
- Documente todas as transformações aplicadas, indicando colunas de origem e destino.
- Teste a normalização com dados de diferentes períodos para garantir compatibilidade.
- Quando necessário renomear ou remover uma coluna, certifique-se de atualizar todos os consumidores e de registrar a alteração em documentação e manifestos.

## Anti‑padrões

- Alterar tipos de colunas sem revisar todos os pontos de consumo.
- Misturar deduplicação e agregação em um único passo, quebrando a separação de camadas.
- Introduzir coluna-chave manualmente sem seguir a lógica de composição definida.
