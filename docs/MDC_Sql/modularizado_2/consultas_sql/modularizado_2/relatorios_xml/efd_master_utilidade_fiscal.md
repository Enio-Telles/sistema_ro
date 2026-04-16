# EFD Master - consultas extraídas e utilidade fiscal

Este bloco reúne as consultas extraídas do relatório `EFD_master.xml`.

## Leitura geral

O relatório foi desenhado como um **painel de auditoria EFD**: começa por uma visão-resumo de apuração própria, desce para arquivos entregues, arrecadação, composição por CFOP, ajustes documentais (`C197`), ajustes de apuração (`E111`/`E220`), apuração consolidada (`E110`/`E210`), visão de entradas e saídas por contraparte e ainda traz um painel de malhas administrativas e um drill documental em `C100`.

Na prática, ele é muito útil para três frentes:
1. **fechamento da conta gráfica** do ICMS e do ICMS-ST;
2. **triagem de risco** por operações, parceiros, UF e malhas;
3. **navegação auditável** do macro para o documento.

## Conclusão sobre utilidade fiscal

A maior força do relatório está em juntar, no mesmo dossiê, apuração, ajustes, documentos e risco administrativo. A maior limitação é que várias consultas são de **síntese**, então precisam ser lidas em conjunto com os módulos documentais já existentes no pacote quando o caso exigir prova item a item.

## Consultas

## 1. EFD Master 2.0

**Caminho no relatório:** `EFD Master 2.0`  
**Utilidade fiscal:** Altíssima  
**Objetivo prático:** Resumo executivo mensal/anual da apuração própria (E110), com indicação de meses sem arquivo e saldo credor transportado.

**Binds declarados**
- `cnpj`: valor padrão = `84654326000394`
- `data_inicial`: valor padrão = `01/01/2022`
- `data_final`: valor padrão = `31/12/2025`

**Tabelas e fontes identificadas**
- `bi.dm_pessoa`
- `bi.dm_calendario`
- `bi.fato_efd_sumarizada`

**Utilidade fiscal detalhada**
- Triagem inicial da situação fiscal do contribuinte no período; ótimo ponto de entrada para decidir se a investigação seguirá por apuração, ajustes, documentos ou omissões.
- É painel de síntese. Não substitui a validação do arquivo efetivo, dos lançamentos individuais nem do vínculo com C100/C170/C197/E111.

**Tipo de uso na auditoria**
- Consulta nuclear de auditoria.

**Arquivo SQL extraído**
- `sql_relatorios_xml/efd_master/01_efd_master_2_0.sql`


## 2. Reg 0000 (arquivos)

**Caminho no relatório:** `EFD Master 2.0 > Reg 0000 (arquivos)`  
**Utilidade fiscal:** Altíssima  
**Objetivo prático:** Lista arquivos EFD, período, entrega, importação e identificação cadastral do arquivo.

**Binds declarados**
- `CNPJ_CPF`: valor padrão = `NULL_VALUE`
- `DATA_INICIAL`: valor padrão = `NULL_VALUE`
- `DATA_FINAL`: valor padrão = `NULL_VALUE`

**Tabelas e fontes identificadas**
- `sped.reg_0000`
- `sped.fis_efd_arquivo_sped`
- `bi.dm_localidade`

**Utilidade fiscal detalhada**
- Provar existência, versão e tempestividade/extemporaneidade do arquivo antes de qualquer auditoria de mérito.
- Sem essa consulta, análises em C100/C170/E110 podem recair sobre arquivo errado ou entrega superada.

**Tipo de uso na auditoria**
- Consulta nuclear de auditoria.

**Arquivo SQL extraído**
- `sql_relatorios_xml/efd_master/02_reg_0000_arquivos.sql`


## 3. Lançamento

**Caminho no relatório:** `EFD Master 2.0 > Lançamento`  
**Utilidade fiscal:** Alta  
**Objetivo prático:** Arrecadação/lançamentos financeiros por receita, situação e guia no período.

**Binds declarados**
- `DATA_INICIAL`: valor padrão = `NULL_VALUE`
- `DATA_FINAL`: valor padrão = `NULL_VALUE`
- `CNPJ_CPF`: valor padrão = `NULL_VALUE`

**Tabelas e fontes identificadas**
- `bi.fato_lanc_arrec`
- `bi.dm_receita`
- `bi.dm_situacao_lancamento`

**Utilidade fiscal detalhada**
- Conciliar apuração declarada com recolhimento efetivo, inadimplemento e situação do débito.
- O filtro substr(t.nu_complemento, 5) like '1500000000' é regra operacional forte e precisa ser validado no ambiente.

**Tipo de uso na auditoria**
- Consulta forte de apoio/triagem.

**Arquivo SQL extraído**
- `sql_relatorios_xml/efd_master/03_lancamento.sql`


## 4. Grupo CFOP

**Caminho no relatório:** `EFD Master 2.0 > Grupo CFOP`  
**Utilidade fiscal:** Alta  
**Objetivo prático:** Composição das operações por grupo de CFOP, separando entradas e saídas e somando base/ICMS/ST.

**Binds declarados**
- `CNPJ_CPF`: valor padrão = `NULL_VALUE`
- `DATA_INICIAL`: valor padrão = `NULL_VALUE`
- `DATA_FINAL`: valor padrão = `NULL_VALUE`

**Tabelas e fontes identificadas**
- `bi.fato_efd_sumarizada`
- `bi.dm_cfop`

**Utilidade fiscal detalhada**
- Explicar a formação dos valores de apuração e localizar grupos de operação que mais pressionam débito, crédito ou ST.
- É agregação por grupo; não substitui análise item a item nem resolve classificação incorreta de CFOP.

**Tipo de uso na auditoria**
- Consulta forte de apoio/triagem.

**Arquivo SQL extraído**
- `sql_relatorios_xml/efd_master/04_grupo_cfop.sql`


## 5. Ajustes C197 (Docs Fiscais)

**Caminho no relatório:** `EFD Master 2.0 > Ajustes C197 (Docs Fiscais)`  
**Utilidade fiscal:** Altíssima  
**Objetivo prático:** Mapeia ajustes documentais do C197 por reflexo na apuração, código e nome do ajuste.

**Binds declarados**
- `CNPJ_CPF`: valor padrão = `NULL_VALUE`
- `DATA_INICIAL`: valor padrão = `NULL_VALUE`
- `DATA_FINAL`: valor padrão = `NULL_VALUE`

**Tabelas e fontes identificadas**
- `bi.dm_efd_c197`
- `bi.dm_efd_ajustes`

**Utilidade fiscal detalhada**
- Essencial para entender quanto do resultado fiscal deriva de documentos com ajustes e quais naturezas estão empurrando crédito, débito, dedução ou informativo.
- Consulta de síntese; em casos críticos precisa descer ao documento fiscal e ao item.

**Tipo de uso na auditoria**
- Consulta nuclear de auditoria.

**Arquivo SQL extraído**
- `sql_relatorios_xml/efd_master/05_ajustes_c197_docs_fiscais.sql`


## 6. Apuração E110

**Caminho no relatório:** `EFD Master 2.0 > Apuração E110`  
**Utilidade fiscal:** Altíssima  
**Objetivo prático:** Fechamento consolidado da apuração própria de ICMS: débitos, créditos, ajustes, saldo, deduções, recolher e saldo a transportar.

**Binds declarados**
- `CNPJ_CPF`: valor padrão = `NULL_VALUE`
- `INFO`: valor padrão = `NULL_VALUE`
- `DATA_INICIAL`: valor padrão = `NULL_VALUE`
- `DATA_FINAL`: valor padrão = `NULL_VALUE`

**Tabelas e fontes identificadas**
- `bi.fato_efd_sumarizada`
- `bi.dm_pessoa`

**Utilidade fiscal detalhada**
- Fechamento macro da conta gráfica do imposto próprio; base para confrontar com E111 e arrecadação.
- Não mostra origem documental; deve ser lido junto com C197, E111, C100/C170 e arrecadação.

**Tipo de uso na auditoria**
- Consulta nuclear de auditoria.

**Arquivo SQL extraído**
- `sql_relatorios_xml/efd_master/06_apuracao_e110.sql`


## 7. Ajustes E111 (Apuração)

**Caminho no relatório:** `EFD Master 2.0 > Ajustes E111 (Apuração)`  
**Utilidade fiscal:** Altíssima  
**Objetivo prático:** Classifica os ajustes do E111 por apuração (ICMS, ST, DIFAL, FCP) e por natureza do ajuste.

**Binds declarados**
- `CNPJ_CPF`: valor padrão = `NULL_VALUE`
- `DATA_INICIAL`: valor padrão = `NULL_VALUE`
- `DATA_FINAL`: valor padrão = `NULL_VALUE`

**Tabelas e fontes identificadas**
- `bi.fato_efd_sumarizada`
- `bi.dm_efd_ajustes`

**Utilidade fiscal detalhada**
- Crucial para identificar créditos, estornos, deduções e débitos especiais registrados na apuração.
- Depende da qualidade do cod_aj e do cadastro dm_efd_ajustes; sem isso, o sentido jurídico do ajuste pode ficar obscuro.

**Tipo de uso na auditoria**
- Consulta nuclear de auditoria.

**Arquivo SQL extraído**
- `sql_relatorios_xml/efd_master/07_ajustes_e111_apuracao.sql`


## 8. Apuração ST - E210

**Caminho no relatório:** `EFD Master 2.0 > Apuração ST - E210`  
**Utilidade fiscal:** Altíssima  
**Objetivo prático:** Fechamento consolidado da apuração de ICMS-ST para UF_ST = RO.

**Binds declarados**
- `CNPJ_CPF`: valor padrão = `NULL_VALUE`
- `INFO`: valor padrão = `NULL_VALUE`
- `DATA_INICIAL`: valor padrão = `NULL_VALUE`
- `DATA_FINAL`: valor padrão = `NULL_VALUE`

**Tabelas e fontes identificadas**
- `bi.fato_efd_sumarizada`
- `bi.dm_pessoa`

**Utilidade fiscal detalhada**
- Base macro para auditoria de substituição tributária no período, especialmente quando as trilhas de ressarcimento e Fronteira convergem para ST.
- Consulta focada em RO; não atende outros cenários de UF_ST sem adaptação.

**Tipo de uso na auditoria**
- Consulta nuclear de auditoria.

**Arquivo SQL extraído**
- `sql_relatorios_xml/efd_master/08_apuracao_st_e210.sql`


## 9. Ajustes E220 (Apuração ST)

**Caminho no relatório:** `EFD Master 2.0 > Ajustes E220 (Apuração ST)`  
**Utilidade fiscal:** Altíssima  
**Objetivo prático:** Resumo de ajustes da apuração ST por tipo e código.

**Binds declarados**
- `CNPJ_CPF`: valor padrão = `NULL_VALUE`
- `DATA_INICIAL`: valor padrão = `NULL_VALUE`
- `DATA_FINAL`: valor padrão = `NULL_VALUE`

**Tabelas e fontes identificadas**
- `bi.fato_efd_sumarizada`
- `bi.dm_efd_ajustes`

**Utilidade fiscal detalhada**
- Permite rastrear créditos, outros débitos, deduções e controle extra-apuração especificamente na trilha de ST.
- É resumo; para ressarcimento, deve ser conciliado com C176/C197 e com a materialidade da entrada/saída.

**Tipo de uso na auditoria**
- Consulta nuclear de auditoria.

**Arquivo SQL extraído**
- `sql_relatorios_xml/efd_master/09_ajustes_e220_apuracao_st.sql`


## 10. Entradas

**Caminho no relatório:** `EFD Master 2.0 > Entradas`  
**Utilidade fiscal:** Alta  
**Objetivo prático:** Visão agregada das entradas por fornecedor e UF, com indicadores de base, carga tributária e inadimplência do fornecedor.

**Binds declarados**
- `CNPJ_CPF`: valor padrão = `NULL_VALUE`
- `DATA_INICIAL`: valor padrão = `NULL_VALUE`
- `DATA_FINAL`: valor padrão = `NULL_VALUE`

**Tabelas e fontes identificadas**
- `bi.dm_efd_arquivo_valido`
- `sped.reg_c100`
- `sped.reg_0150`
- `bi.dm_localidade`
- `bi.fato_lanc_arrec_sum`

**Utilidade fiscal detalhada**
- Muito útil para triagem de risco em créditos de entrada, concentração por fornecedor e exposição a fornecedores inadimplentes.
- Mistura visão documental com atributo externo de inadimplência; isso é útil para risco, mas não é fundamento jurídico automático de glosa.

**Tipo de uso na auditoria**
- Consulta forte de apoio/triagem.

**Arquivo SQL extraído**
- `sql_relatorios_xml/efd_master/10_entradas.sql`


## 11. Saídas

**Caminho no relatório:** `EFD Master 2.0 > Saídas`  
**Utilidade fiscal:** Alta  
**Objetivo prático:** Visão agregada das saídas por destinatário e UF, com base e ICMS/ST.

**Binds declarados**
- Sem binds declarados.

**Tabelas e fontes identificadas**
- `bi.dm_efd_arquivo_valido`
- `sped.reg_c100`
- `sped.reg_0150`
- `bi.dm_localidade`

**Utilidade fiscal detalhada**
- Ajuda a explicar geração de débitos, concentração de clientes, peso interestadual e exposição ST.
- Não revela por si só a natureza fiscal item a item nem substitui análise de CFOP/CST/documento.

**Tipo de uso na auditoria**
- Consulta forte de apoio/triagem.

**Arquivo SQL extraído**
- `sql_relatorios_xml/efd_master/11_saidas.sql`


## 12. Fisconforme (malhas s / EFD)

**Caminho no relatório:** `EFD Master 2.0 > Fisconforme (malhas s / EFD)`  
**Utilidade fiscal:** Alta  
**Objetivo prático:** Situação de pendências/malhas por período e status, vinculadas a conjuntos específicos de malhas.

**Binds declarados**
- `CNPJ_CPF`: valor padrão = `NULL_VALUE`
- `DATA_INICIAL`: valor padrão = `NULL_VALUE`
- `DATA_FINAL`: valor padrão = `NULL_VALUE`

**Tabelas e fontes identificadas**
- `app_pendencia.pendencias`
- `app_pendencia.malhas`

**Utilidade fiscal detalhada**
- Excelente trilha de risco e priorização: mostra onde já há questionamento institucional sobre EFD ou comportamento fiscal correlato.
- Malha não é prova definitiva de infração; é sinalizador de risco e workflow administrativo.

**Tipo de uso na auditoria**
- Consulta forte de apoio/triagem.

**Arquivo SQL extraído**
- `sql_relatorios_xml/efd_master/12_fisconforme_malhas_s_efd.sql`


## 13. C100

**Caminho no relatório:** `EFD Master 2.0 > C100`  
**Utilidade fiscal:** Altíssima  
**Objetivo prático:** Extrai documentos C100 dos arquivos mais recentes por período para o contribuinte.

**Binds declarados**
- `CNPJ`: valor padrão = `NULL_VALUE`
- `data_inicial`: valor padrão = `NULL_VALUE`
- `data_final`: valor padrão = `NULL_VALUE`

**Tabelas e fontes identificadas**
- `sped.reg_c100`
- `sped.reg_0000`

**Utilidade fiscal detalhada**
- Drill documental essencial para reconciliar apuração, entradas/saídas, omissões, duplicidades e cruzamento com BI/XML.
- Escolhe a última entrega por período; em trabalhos históricos convém documentar a regra de seleção do arquivo.

**Tipo de uso na auditoria**
- Consulta nuclear de auditoria.

**Arquivo SQL extraído**
- `sql_relatorios_xml/efd_master/13_c100.sql`

