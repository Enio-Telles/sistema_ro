# Índice de consultas extraídas de EFD_master.xml

| # | Consulta | Arquivo | Utilidade fiscal | Foco |
|---|---|---|---|---|
| 1 | EFD Master 2.0 | `01_efd_master_2_0.sql` | Altíssima | Resumo executivo mensal/anual da apuração própria (E110), com indicação de meses sem arquivo e saldo credor transportado. |
| 2 | Reg 0000 (arquivos) | `02_reg_0000_arquivos.sql` | Altíssima | Lista arquivos EFD, período, entrega, importação e identificação cadastral do arquivo. |
| 3 | Lançamento | `03_lancamento.sql` | Alta | Arrecadação/lançamentos financeiros por receita, situação e guia no período. |
| 4 | Grupo CFOP | `04_grupo_cfop.sql` | Alta | Composição das operações por grupo de CFOP, separando entradas e saídas e somando base/ICMS/ST. |
| 5 | Ajustes C197 (Docs Fiscais) | `05_ajustes_c197_docs_fiscais.sql` | Altíssima | Mapeia ajustes documentais do C197 por reflexo na apuração, código e nome do ajuste. |
| 6 | Apuração E110 | `06_apuracao_e110.sql` | Altíssima | Fechamento consolidado da apuração própria de ICMS: débitos, créditos, ajustes, saldo, deduções, recolher e saldo a transportar. |
| 7 | Ajustes E111 (Apuração) | `07_ajustes_e111_apuracao.sql` | Altíssima | Classifica os ajustes do E111 por apuração (ICMS, ST, DIFAL, FCP) e por natureza do ajuste. |
| 8 | Apuração ST - E210 | `08_apuracao_st_e210.sql` | Altíssima | Fechamento consolidado da apuração de ICMS-ST para UF_ST = RO. |
| 9 | Ajustes E220 (Apuração ST) | `09_ajustes_e220_apuracao_st.sql` | Altíssima | Resumo de ajustes da apuração ST por tipo e código. |
| 10 | Entradas | `10_entradas.sql` | Alta | Visão agregada das entradas por fornecedor e UF, com indicadores de base, carga tributária e inadimplência do fornecedor. |
| 11 | Saídas | `11_saidas.sql` | Alta | Visão agregada das saídas por destinatário e UF, com base e ICMS/ST. |
| 12 | Fisconforme (malhas s / EFD) | `12_fisconforme_malhas_s_efd.sql` | Alta | Situação de pendências/malhas por período e status, vinculadas a conjuntos específicos de malhas. |
| 13 | C100 | `13_c100.sql` | Altíssima | Extrai documentos C100 dos arquivos mais recentes por período para o contribuinte. |