# Dossie Contribuinte

Origem: `dossie_contribuinte.xml`

Quantidade de consultas extraídas: **48**

| Nº | Caminho no XML | Estilo | Binds | Arquivo |
|---:|---|---|---|---|
| 1 | Dossiê Contribuinte NIF - 4.3.7 | Table | CNPJ, IE, NOME | `001_consulta_raiz_dossie_contribuinte_nif_4_3_7.sql` |
| 2 | Dossiê Contribuinte NIF - 4.3.7 > Dados cadastrais | Table | CO_CNPJ_CPF | `002_dados_cadastrais.sql` |
| 3 | Dossiê Contribuinte NIF - 4.3.7 > Endereços | Table | CO_CNPJ_CPF | `003_enderecos.sql` |
| 4 | Dossiê Contribuinte NIF - 4.3.7 > Historico Situação | Table | CO_CAD_ICMS | `004_historico_situacao.sql` |
| 5 | Dossiê Contribuinte NIF - 4.3.7 > Historico Situação > Observação | Script | TUK | `005_observacao.sql` |
| 6 | Dossiê Contribuinte NIF - 4.3.7 > Histórico Regime de Pagamento | Table | CO_CNPJ_CPF | `006_historico_regime_de_pagamento.sql` |
| 7 | Dossiê Contribuinte NIF - 4.3.7 > Atividades | Table | CO_CNPJ_CPF | `007_atividades.sql` |
| 8 | Dossiê Contribuinte NIF - 4.3.7 > Contador | Table | CO_CAD_ICMS | `008_contador.sql` |
| 9 | Dossiê Contribuinte NIF - 4.3.7 > Contador > Empresas do Contador | Table | CO_CNPJ_CPF_CONTADOR | `009_empresas_do_contador.sql` |
| 10 | Dossiê Contribuinte NIF - 4.3.7 > Histórico FAC | Table | CO_CAD_ICMS | `010_historico_fac.sql` |
| 11 | Dossiê Contribuinte NIF - 4.3.7 > Vistoria(s) | Table | CO_CNPJ_CPF | `011_vistoria_s.sql` |
| 12 | Dossiê Contribuinte NIF - 4.3.7 > Histórico de Sócios | Table | CO_CNPJ_CPF | `012_historico_de_socios.sql` |
| 13 | Dossiê Contribuinte NIF - 4.3.7 > Histórico de Sócios > DIMP Sócios | Table | CO_CNPJ_CPF | `013_dimp_socios.sql` |
| 14 | Dossiê Contribuinte NIF - 4.3.7 > Empresas dos Sócios | Table | CO_CAD_ICMS | `014_empresas_dos_socios.sql` |
| 15 | Dossiê Contribuinte NIF - 4.3.7 > Empresas dos Sócios > Conta Corrente | Table | INFO | `015_conta_corrente.sql` |
| 16 | Dossiê Contribuinte NIF - 4.3.7 > NFs - Entr X Saida (VAF) | Table | CO_CNPJ_CPF | `016_nfs_entr_x_saida_vaf.sql` |
| 17 | Dossiê Contribuinte NIF - 4.3.7 > NFs - Entr X Saida (VAF) > NFs - Entrada e Saída Detalhe | Table | CO_CNPJ_CPF, ANO | `017_nfs_entrada_e_saida_detalhe.sql` |
| 18 | Dossiê Contribuinte NIF - 4.3.7 > Notas_Entrada | Table | CO_CNPJ_CPF | `018_notas_entrada.sql` |
| 19 | Dossiê Contribuinte NIF - 4.3.7 > NFs Entrada - Quantidades | Table | CO_CNPJ_CPF | `019_nfs_entrada_quantidades.sql` |
| 20 | Dossiê Contribuinte NIF - 4.3.7 > NFs Entrada - Quantidades > Emitente(s) | Table | CO_CNPJ_CPF, ANO | `020_emitente_s.sql` |
| 21 | Dossiê Contribuinte NIF - 4.3.7 > Notas_Saida | Table | CO_CNPJ_CPF | `021_notas_saida.sql` |
| 22 | Dossiê Contribuinte NIF - 4.3.7 > Manifesto(s) | Table | CO_CNPJ_CPF | `022_manifesto_s.sql` |
| 23 | Dossiê Contribuinte NIF - 4.3.7 > Manifesto(s) > CTE(s) | Table | CO_CNPJ_CPF, IT_NU_CHAVE_MDFE | `023_cte_s.sql` |
| 24 | Dossiê Contribuinte NIF - 4.3.7 > Manifesto(s) > Fornecedor(es) | Table | IT_NU_CHAVE_MDFE, CO_CNPJ_CPF | `024_fornecedor_es.sql` |
| 25 | Dossiê Contribuinte NIF - 4.3.7 > Manifesto(s) > Nota(s) Fiscal(is) | Table | IT_NU_CHAVE_MDFE, CO_CNPJ_CPF | `025_nota_s_fiscal_is.sql` |
| 26 | Dossiê Contribuinte NIF - 4.3.7 > Manifesto(s) > Mercadoria | Table | IT_NU_CHAVE_MDFE, CO_CNPJ_CPF | `026_mercadoria.sql` |
| 27 | Dossiê Contribuinte NIF - 4.3.7 > Manifesto(s) > Evento(s) | Table | IT_NU_CHAVE_MDFE | `027_evento_s.sql` |
| 28 | Dossiê Contribuinte NIF - 4.3.7 > Conta Corrente | Table | CO_CNPJ_CPF | `028_conta_corrente.sql` |
| 29 | Dossiê Contribuinte NIF - 4.3.7 > Conta Corrente > Detalhe | Table | CO_CNPJ_CPF, SITUACAO | `029_detalhe.sql` |
| 30 | Dossiê Contribuinte NIF - 4.3.7 > Regime Especial | Table | CO_CNPJ_CPF | `030_regime_especial.sql` |
| 31 | Dossiê Contribuinte NIF - 4.3.7 > DIMP | Table | CO_CNPJ_CPF | `031_dimp.sql` |
| 32 | Dossiê Contribuinte NIF - 4.3.7 > Parcelamentos | Table | CO_CNPJ_CPF | `032_parcelamentos.sql` |
| 33 | Dossiê Contribuinte NIF - 4.3.7 > Parcelamentos > Parcelas | Table | IT_NU_GUIA_PARCELAMENTO | `033_parcelas.sql` |
| 34 | Dossiê Contribuinte NIF - 4.3.7 > Parcelamentos > Origem | Table | IT_NU_GUIA_PARCELAMENTO | `034_origem.sql` |
| 35 | Dossiê Contribuinte NIF - 4.3.7 > Ações Fiscais | Table | CO_CNPJ_CPF | `035_acoes_fiscais.sql` |
| 36 | Dossiê Contribuinte NIF - 4.3.7 > Ações Fiscais > Auditores | Table | ACAO_FISCAL | `036_auditores.sql` |
| 37 | Dossiê Contribuinte NIF - 4.3.7 > Ações Fiscais > Autos de Infração | Table | ACAO_FISCAL | `037_autos_de_infracao.sql` |
| 38 | Dossiê Contribuinte NIF - 4.3.7 > Ações Fiscais > Autos de Infração > Descrição do AI | Script | NU_TERMO_INFRACAO | `038_descricao_do_ai.sql` |
| 39 | Dossiê Contribuinte NIF - 4.3.7 > Autos de Infração | Table | CO_CNPJ_CPF | `039_autos_de_infracao.sql` |
| 40 | Dossiê Contribuinte NIF - 4.3.7 > Autos de Infração > Descrição do AI | Script | NU_TERMO_INFRACAO | `040_descricao_do_ai.sql` |
| 41 | Dossiê Contribuinte NIF - 4.3.7 > FisConforme | Table | CO_CNPJ_CPF | `041_fisconforme.sql` |
| 42 | Dossiê Contribuinte NIF - 4.3.7 > DET | Table | CO_CNPJ_CPF | `042_det.sql` |
| 43 | Dossiê Contribuinte NIF - 4.3.7 > DET > Arquivo da Notificação | Table | ID_NOTIFICACAO | `043_arquivo_da_notificacao.sql` |
| 44 | Dossiê Contribuinte NIF - 4.3.7 > Processos Administrativos | Table | CO_CNPJ_CPF | `044_processos_administrativos.sql` |
| 45 | Dossiê Contribuinte NIF - 4.3.7 > Veículos | Table | CO_CNPJ_CPF | `045_veiculos.sql` |
| 46 | Dossiê Contribuinte NIF - 4.3.7 > IP(s) das NFs | Table | CO_CNPJ_CPF | `046_ip_s_das_nfs.sql` |
| 47 | Dossiê Contribuinte NIF - 4.3.7 > IP(s) das NFs > Contribuintes | Table | IP | `047_contribuintes.sql` |
| 48 | Dossiê Contribuinte NIF - 4.3.7 > IP(s) das NFs > Contribuintes Detalhe | Table | CNPJ, IP | `048_contribuintes_detalhe.sql` |
