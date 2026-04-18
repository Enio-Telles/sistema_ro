# AGENT – Referências (references/)

Este agente abrange o diretório `references/`, que armazena tabelas auxiliares, mapeamentos e dicionários usados por várias etapas do pipeline.

## Responsabilidades

- **Manter tabelas auxiliares** como códigos de CFOP, NCM, CST, alíquotas de impostos, fatores de conversão e dicionários de produto.
- **Versionar** cada conjunto de dados de referência, registrando data de validade e fonte oficial.
- **Garantir integridade**: assegurar que as referências estejam completas e consistentes, especialmente ao cruzar com dados internos.
- **Disponibilizar essas tabelas** para as pipelines por meio de funções utilitárias ou leitura direta.

## Convenções

- Armazene as referências em formatos fáceis de consumir (CSV ou Parquet) dentro de `references/`, com nomes descritivos (`cfop_codes.csv`, `fatores_conversion.parquet`).
- Mantenha um histórico de versões quando houver alteração; não sobrescreva arquivos antigos sem registrar.
- Documente a origem da tabela (portaria, legislação, API) e a data de vigência.
- Sempre valide se a referência está atualizada antes de usá-la no pipeline.

## Anti‑padrões

- Utilizar planilhas locais ou links externos sem garantia de persistência.
- Não versionar atualizações, tornando impossível reproduzir resultados antigos.
- Misturar dados referenciais com dados transacionais (por exemplo, incluir taxas de conversão em tabelas de mercadorias).
