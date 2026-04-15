# Relatórios XML extraídos - inclusão no pacote

Este bloco consolida consultas extraídas de dois relatórios XML:

- `EFD_master.xml`
- `relatorio_fronteira.xml`

## Quantidade de consultas extraídas

- `EFD_master.xml`: 13 consultas
- `relatorio_fronteira.xml`: 6 consultas

## Como esse bloco deve ser usado

- `EFD Master`: use como dossiê de apuração, ajustes, documentos e risco EFD.
- `Fronteira`: use como dossiê de comando, nota, lançamento e mercadoria no SITAFE/Fronteira.
- Quando a investigação sair do nível-resumo e entrar em prova fiscal, combine estas consultas com os módulos já existentes no pacote (`sql_basicas/`, trilhas de ressarcimento, Fronteira e auditoria EFD x documentos).

## Estrutura adicionada

- `relatorios_xml/README.md`
- `relatorios_xml/efd_master_utilidade_fiscal.md`
- `relatorios_xml/fronteira_relatorio_utilidade_fiscal.md`
- `sql_relatorios_xml/efd_master/`
- `sql_relatorios_xml/fronteira/`
- `xml_relatorios_origem/`

## Observação metodológica

As consultas foram incluídas como **consultas de relatório** e analisadas por utilidade fiscal. Isso significa que:
- algumas são consultas nucleares de auditoria;
- outras são consultas de triagem/apoio;
- nenhuma deve ser tratada, por si só, como conclusão jurídica final sem confronto com documento fiscal, SPED, lançamentos e regra tributária aplicável.
