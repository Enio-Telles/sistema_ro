# Dossiê Fronteira - consultas extraídas e utilidade fiscal

Este bloco reúne as consultas extraídas do relatório `relatorio_fronteira.xml`.

## Leitura geral

O relatório foi desenhado como um **dossiê operacional-fiscal de Fronteira**. Ele localiza o comando por várias chaves, identifica destinatários, lista notas fiscais, mostra o lançamento vinculado e resume mercadorias e destinos. Isso o torna especialmente útil para provas de entrada interestadual, rastreamento de lançamento em SITAFE/Fronteira e composição econômica do comando.

## Conclusão sobre utilidade fiscal

A maior força do relatório está em ligar **comando -> nota -> lançamento -> mercadoria -> destino**. A maior limitação é que ele não resolve sozinho discussões jurídicas de elegibilidade de crédito ou ressarcimento; ele entrega sobretudo a prova operacional e financeira do evento de fronteira.

## Consultas

## 1. Dossiê Fronteira 2.0

**Caminho no relatório:** `Dossiê Fronteira 2.0`  
**Utilidade fiscal:** Altíssima  
**Objetivo prático:** Porta de entrada do dossiê, localizando comando de Fronteira por comando, motorista, placa, emitente, destinatário ou chave.

**Binds declarados**
- `NU_COMANDO`: valor padrão = `null`
- `CPF_MOTORISTA`: valor padrão = `NULL_VALUE`
- `PLACA_TRATOR`: valor padrão = `NULL_VALUE`
- `CNPJ_DESTINATARIO`: valor padrão = `04565289001623`
- `CNPJ_EMITENTE`: valor padrão = `vazio`
- `CHAVE_ACESSO`: valor padrão = `04420916001204`

**Tabelas e fontes identificadas**
- `sitafe.sitafe_comando`
- `sitafe.sitafe_nota_fiscal`

**Utilidade fiscal detalhada**
- Excelente para começar investigação logística-fiscal de entrada interestadual, principalmente quando ainda não se conhece o número do comando.
- O desenho usa unions por múltiplas chaves; em casos com muito reaproveitamento de placa/CPF pode trazer universo mais amplo que o desejado.

**Tipo de uso na auditoria**
- Consulta nuclear de auditoria.

**Arquivo SQL extraído**
- `sql_relatorios_xml/fronteira/01_dossie_fronteira_2_0.sql`


## 2. Destinatário(s)

**Caminho no relatório:** `Dossiê Fronteira 2.0 > Destinatário(s)`  
**Utilidade fiscal:** Alta  
**Objetivo prático:** Concentra destinatários por comando, com valor total de mercadorias.

**Binds declarados**
- `COMANDO`: valor padrão = `NULL_VALUE`

**Tabelas e fontes identificadas**
- `sitafe.sitafe_nota_fiscal`
- `sitafe.sitafe_nfe_item`
- `bi.dm_pessoa`
- `bi.dm_localidade`

**Utilidade fiscal detalhada**
- Mostra quem efetivamente recebe as mercadorias vinculadas ao comando e o peso econômico por destinatário.
- Usa valor itemizado de sitafe_nfe_item; diferenças de qualidade do cadastro do destinatário afetam município/UF.

**Tipo de uso na auditoria**
- Consulta forte de apoio/triagem.

**Arquivo SQL extraído**
- `sql_relatorios_xml/fronteira/02_destinatario_s.sql`


## 3. Nota(s) Fiscal(is)

**Caminho no relatório:** `Dossiê Fronteira 2.0 > Destinatário(s) > Nota(s) Fiscal(is)`  
**Utilidade fiscal:** Altíssima  
**Objetivo prático:** Lista as notas fiscais do comando, com chave, datas, emitente, destinatário, UF, bases e valores de ICMS/ST.

**Binds declarados**
- `COMANDO`: valor padrão = `NULL_VALUE`
- `CO_CNPJ_CPF`: valor padrão = `NULL_VALUE`

**Tabelas e fontes identificadas**
- `sitafe.sitafe_nota_fiscal`

**Utilidade fiscal detalhada**
- É a consulta documental mais forte do relatório para provar a materialidade fiscal do comando e servir de ponte com lançamentos e cálculos.
- Não entra no item; para ressarcimento, classificação de mercadoria ou confronto de cálculo, precisa descer ao item.

**Tipo de uso na auditoria**
- Consulta nuclear de auditoria.

**Arquivo SQL extraído**
- `sql_relatorios_xml/fronteira/03_nota_s_fiscal_is.sql`


## 4. Lançamento

**Caminho no relatório:** `Dossiê Fronteira 2.0 > Destinatário(s) > Nota(s) Fiscal(is) > Lançamento`  
**Utilidade fiscal:** Altíssima  
**Objetivo prático:** Traz o lançamento da nota no SITAFE/Fronteira: guia, situação, valores, frete crédito, processo de suspensão e pendência.

**Binds declarados**
- `IDENT_NF`: valor padrão = `NULL_VALUE`

**Tabelas e fontes identificadas**
- `sitafe.sitafe_nf_lancamento`

**Utilidade fiscal detalhada**
- Fundamental para provar se a nota efetivamente gerou lançamento, qual o valor, a situação e se há suspensão/pendência.
- É nível nota-lançamento; ainda precisa ser combinado com item e mercadoria quando o debate for ST por produto.

**Tipo de uso na auditoria**
- Consulta nuclear de auditoria.

**Arquivo SQL extraído**
- `sql_relatorios_xml/fronteira/04_lancamento.sql`


## 5. Mercadoria

**Caminho no relatório:** `Dossiê Fronteira 2.0 > Mercadoria`  
**Utilidade fiscal:** Alta  
**Objetivo prático:** Agrupa mercadorias do comando por descrição, NCM e unidade, com quantidade e valor.

**Binds declarados**
- `COMANDO`: valor padrão = `NULL_VALUE`

**Tabelas e fontes identificadas**
- `sitafe.sitafe_nfe_item`
- `sitafe.sitafe_nota_fiscal`

**Utilidade fiscal detalhada**
- Ótimo resumo da cesta de produtos do comando e excelente apoio para triagem de NCM/ST e risco de classificação.
- Descrição/NCM agregados não substituem prova item a item quando houver mercadoria heterogênea com mesma descrição.

**Tipo de uso na auditoria**
- Consulta forte de apoio/triagem.

**Arquivo SQL extraído**
- `sql_relatorios_xml/fronteira/05_mercadoria.sql`


## 6. Destino(s)

**Caminho no relatório:** `Dossiê Fronteira 2.0 > Destino(s)`  
**Utilidade fiscal:** Média/Alta  
**Objetivo prático:** Agrupa o comando por município/UF de destino, somando valor de mercadorias.

**Binds declarados**
- `COMANDO`: valor padrão = `NULL_VALUE`

**Tabelas e fontes identificadas**
- `sitafe.sitafe_nota_fiscal`
- `sitafe.sitafe_nfe_item`
- `bi.dm_pessoa`
- `bi.dm_localidade`

**Utilidade fiscal detalhada**
- Boa camada geográfica para detectar redistribuição, concentração regional e coerência logística.
- É consulta analítica de apoio; raramente decide sozinha uma conclusão tributária.

**Tipo de uso na auditoria**
- Consulta complementar.

**Arquivo SQL extraído**
- `sql_relatorios_xml/fronteira/06_destino_s.sql`

