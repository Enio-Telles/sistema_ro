# Consultas contidas nos XMLs

Este material reúne as consultas SQL extraídas dos arquivos XML de painéis/dossiês enviados pelo usuário. As consultas foram separadas por dossiê, preservando a hierarquia original dos painéis, os binds e o conteúdo SQL sem alteração funcional.

## Estrutura incluída

- **Dossie Contribuinte**: 48 consultas extraídas. Índice em `sql_xml/dossie_contribuinte/INDEX.md`.
- **Dossie Pessoa Fisica**: 13 consultas extraídas. Índice em `sql_xml/dossie_pessoa_fisica/INDEX.md`.

## Observações de uso

- As consultas em estilo `Script` foram mantidas como `.sql`, mesmo quando incluem comandos de ambiente como `SET PAGESIZE`.
- Binds e valores padrão do XML foram documentados no cabeçalho de cada arquivo.
- O conteúdo foi preservado como veio do XML, inclusive HTML usado na camada de apresentação dos painéis.
- Os XMLs originais foram copiados para `xml_origem/` para manter a rastreabilidade.

## Índice consolidado

| Fonte | Nº | Caminho no XML | Estilo | Binds | Arquivo |
|---|---:|---|---|---|---|
| dossie_contribuinte | 1 | Dossiê Contribuinte NIF - 4.3.7 | Table | CNPJ, IE, NOME | `sql_xml/dossie_contribuinte/001_consulta_raiz_dossie_contribuinte_nif_4_3_7.sql` |
| dossie_contribuinte | 2 | Dossiê Contribuinte NIF - 4.3.7 > Dados cadastrais | Table | CO_CNPJ_CPF | `sql_xml/dossie_contribuinte/002_dados_cadastrais.sql` |
| dossie_contribuinte | 3 | Dossiê Contribuinte NIF - 4.3.7 > Endereços | Table | CO_CNPJ_CPF | `sql_xml/dossie_contribuinte/003_enderecos.sql` |
| dossie_contribuinte | 4 | Dossiê Contribuinte NIF - 4.3.7 > Historico Situação | Table | CO_CAD_ICMS | `sql_xml/dossie_contribuinte/004_historico_situacao.sql` |
| dossie_contribuinte | 5 | Dossiê Contribuinte NIF - 4.3.7 > Historico Situação > Observação | Script | TUK | `sql_xml/dossie_contribuinte/005_observacao.sql` |
| dossie_contribuinte | 6 | Dossiê Contribuinte NIF - 4.3.7 > Histórico Regime de Pagamento | Table | CO_CNPJ_CPF | `sql_xml/dossie_contribuinte/006_historico_regime_de_pagamento.sql` |
| dossie_contribuinte | 7 | Dossiê Contribuinte NIF - 4.3.7 > Atividades | Table | CO_CNPJ_CPF | `sql_xml/dossie_contribuinte/007_atividades.sql` |
| dossie_contribuinte | 8 | Dossiê Contribuinte NIF - 4.3.7 > Contador | Table | CO_CAD_ICMS | `sql_xml/dossie_contribuinte/008_contador.sql` |
| dossie_contribuinte | 9 | Dossiê Contribuinte NIF - 4.3.7 > Contador > Empresas do Contador | Table | CO_CNPJ_CPF_CONTADOR | `sql_xml/dossie_contribuinte/009_empresas_do_contador.sql` |
| dossie_contribuinte | 10 | Dossiê Contribuinte NIF - 4.3.7 > Histórico FAC | Table | CO_CAD_ICMS | `sql_xml/dossie_contribuinte/010_historico_fac.sql` |
| dossie_contribuinte | 11 | Dossiê Contribuinte NIF - 4.3.7 > Vistoria(s) | Table | CO_CNPJ_CPF | `sql_xml/dossie_contribuinte/011_vistoria_s.sql` |
| dossie_contribuinte | 12 | Dossiê Contribuinte NIF - 4.3.7 > Histórico de Sócios | Table | CO_CNPJ_CPF | `sql_xml/dossie_contribuinte/012_historico_de_socios.sql` |
| dossie_contribuinte | 13 | Dossiê Contribuinte NIF - 4.3.7 > Histórico de Sócios > DIMP Sócios | Table | CO_CNPJ_CPF | `sql_xml/dossie_contribuinte/013_dimp_socios.sql` |
| dossie_contribuinte | 14 | Dossiê Contribuinte NIF - 4.3.7 > Empresas dos Sócios | Table | CO_CAD_ICMS | `sql_xml/dossie_contribuinte/014_empresas_dos_socios.sql` |
| dossie_contribuinte | 15 | Dossiê Contribuinte NIF - 4.3.7 > Empresas dos Sócios > Conta Corrente | Table | INFO | `sql_xml/dossie_contribuinte/015_conta_corrente.sql` |
| dossie_contribuinte | 16 | Dossiê Contribuinte NIF - 4.3.7 > NFs - Entr X Saida (VAF) | Table | CO_CNPJ_CPF | `sql_xml/dossie_contribuinte/016_nfs_entr_x_saida_vaf.sql` |
| dossie_contribuinte | 17 | Dossiê Contribuinte NIF - 4.3.7 > NFs - Entr X Saida (VAF) > NFs - Entrada e Saída Detalhe | Table | CO_CNPJ_CPF, ANO | `sql_xml/dossie_contribuinte/017_nfs_entrada_e_saida_detalhe.sql` |
| dossie_contribuinte | 18 | Dossiê Contribuinte NIF - 4.3.7 > Notas_Entrada | Table | CO_CNPJ_CPF | `sql_xml/dossie_contribuinte/018_notas_entrada.sql` |
| dossie_contribuinte | 19 | Dossiê Contribuinte NIF - 4.3.7 > NFs Entrada - Quantidades | Table | CO_CNPJ_CPF | `sql_xml/dossie_contribuinte/019_nfs_entrada_quantidades.sql` |
| dossie_contribuinte | 20 | Dossiê Contribuinte NIF - 4.3.7 > NFs Entrada - Quantidades > Emitente(s) | Table | CO_CNPJ_CPF, ANO | `sql_xml/dossie_contribuinte/020_emitente_s.sql` |
| dossie_contribuinte | 21 | Dossiê Contribuinte NIF - 4.3.7 > Notas_Saida | Table | CO_CNPJ_CPF | `sql_xml/dossie_contribuinte/021_notas_saida.sql` |
| dossie_contribuinte | 22 | Dossiê Contribuinte NIF - 4.3.7 > Manifesto(s) | Table | CO_CNPJ_CPF | `sql_xml/dossie_contribuinte/022_manifesto_s.sql` |
| dossie_contribuinte | 23 | Dossiê Contribuinte NIF - 4.3.7 > Manifesto(s) > CTE(s) | Table | CO_CNPJ_CPF, IT_NU_CHAVE_MDFE | `sql_xml/dossie_contribuinte/023_cte_s.sql` |
| dossie_contribuinte | 24 | Dossiê Contribuinte NIF - 4.3.7 > Manifesto(s) > Fornecedor(es) | Table | IT_NU_CHAVE_MDFE, CO_CNPJ_CPF | `sql_xml/dossie_contribuinte/024_fornecedor_es.sql` |
| dossie_contribuinte | 25 | Dossiê Contribuinte NIF - 4.3.7 > Manifesto(s) > Nota(s) Fiscal(is) | Table | IT_NU_CHAVE_MDFE, CO_CNPJ_CPF | `sql_xml/dossie_contribuinte/025_nota_s_fiscal_is.sql` |
| dossie_contribuinte | 26 | Dossiê Contribuinte NIF - 4.3.7 > Manifesto(s) > Mercadoria | Table | IT_NU_CHAVE_MDFE, CO_CNPJ_CPF | `sql_xml/dossie_contribuinte/026_mercadoria.sql` |
| dossie_contribuinte | 27 | Dossiê Contribuinte NIF - 4.3.7 > Manifesto(s) > Evento(s) | Table | IT_NU_CHAVE_MDFE | `sql_xml/dossie_contribuinte/027_evento_s.sql` |
| dossie_contribuinte | 28 | Dossiê Contribuinte NIF - 4.3.7 > Conta Corrente | Table | CO_CNPJ_CPF | `sql_xml/dossie_contribuinte/028_conta_corrente.sql` |
| dossie_contribuinte | 29 | Dossiê Contribuinte NIF - 4.3.7 > Conta Corrente > Detalhe | Table | CO_CNPJ_CPF, SITUACAO | `sql_xml/dossie_contribuinte/029_detalhe.sql` |
| dossie_contribuinte | 30 | Dossiê Contribuinte NIF - 4.3.7 > Regime Especial | Table | CO_CNPJ_CPF | `sql_xml/dossie_contribuinte/030_regime_especial.sql` |
| dossie_contribuinte | 31 | Dossiê Contribuinte NIF - 4.3.7 > DIMP | Table | CO_CNPJ_CPF | `sql_xml/dossie_contribuinte/031_dimp.sql` |
| dossie_contribuinte | 32 | Dossiê Contribuinte NIF - 4.3.7 > Parcelamentos | Table | CO_CNPJ_CPF | `sql_xml/dossie_contribuinte/032_parcelamentos.sql` |
| dossie_contribuinte | 33 | Dossiê Contribuinte NIF - 4.3.7 > Parcelamentos > Parcelas | Table | IT_NU_GUIA_PARCELAMENTO | `sql_xml/dossie_contribuinte/033_parcelas.sql` |
| dossie_contribuinte | 34 | Dossiê Contribuinte NIF - 4.3.7 > Parcelamentos > Origem | Table | IT_NU_GUIA_PARCELAMENTO | `sql_xml/dossie_contribuinte/034_origem.sql` |
| dossie_contribuinte | 35 | Dossiê Contribuinte NIF - 4.3.7 > Ações Fiscais | Table | CO_CNPJ_CPF | `sql_xml/dossie_contribuinte/035_acoes_fiscais.sql` |
| dossie_contribuinte | 36 | Dossiê Contribuinte NIF - 4.3.7 > Ações Fiscais > Auditores | Table | ACAO_FISCAL | `sql_xml/dossie_contribuinte/036_auditores.sql` |
| dossie_contribuinte | 37 | Dossiê Contribuinte NIF - 4.3.7 > Ações Fiscais > Autos de Infração | Table | ACAO_FISCAL | `sql_xml/dossie_contribuinte/037_autos_de_infracao.sql` |
| dossie_contribuinte | 38 | Dossiê Contribuinte NIF - 4.3.7 > Ações Fiscais > Autos de Infração > Descrição do AI | Script | NU_TERMO_INFRACAO | `sql_xml/dossie_contribuinte/038_descricao_do_ai.sql` |
| dossie_contribuinte | 39 | Dossiê Contribuinte NIF - 4.3.7 > Autos de Infração | Table | CO_CNPJ_CPF | `sql_xml/dossie_contribuinte/039_autos_de_infracao.sql` |
| dossie_contribuinte | 40 | Dossiê Contribuinte NIF - 4.3.7 > Autos de Infração > Descrição do AI | Script | NU_TERMO_INFRACAO | `sql_xml/dossie_contribuinte/040_descricao_do_ai.sql` |
| dossie_contribuinte | 41 | Dossiê Contribuinte NIF - 4.3.7 > FisConforme | Table | CO_CNPJ_CPF | `sql_xml/dossie_contribuinte/041_fisconforme.sql` |
| dossie_contribuinte | 42 | Dossiê Contribuinte NIF - 4.3.7 > DET | Table | CO_CNPJ_CPF | `sql_xml/dossie_contribuinte/042_det.sql` |
| dossie_contribuinte | 43 | Dossiê Contribuinte NIF - 4.3.7 > DET > Arquivo da Notificação | Table | ID_NOTIFICACAO | `sql_xml/dossie_contribuinte/043_arquivo_da_notificacao.sql` |
| dossie_contribuinte | 44 | Dossiê Contribuinte NIF - 4.3.7 > Processos Administrativos | Table | CO_CNPJ_CPF | `sql_xml/dossie_contribuinte/044_processos_administrativos.sql` |
| dossie_contribuinte | 45 | Dossiê Contribuinte NIF - 4.3.7 > Veículos | Table | CO_CNPJ_CPF | `sql_xml/dossie_contribuinte/045_veiculos.sql` |
| dossie_contribuinte | 46 | Dossiê Contribuinte NIF - 4.3.7 > IP(s) das NFs | Table | CO_CNPJ_CPF | `sql_xml/dossie_contribuinte/046_ip_s_das_nfs.sql` |
| dossie_contribuinte | 47 | Dossiê Contribuinte NIF - 4.3.7 > IP(s) das NFs > Contribuintes | Table | IP | `sql_xml/dossie_contribuinte/047_contribuintes.sql` |
| dossie_contribuinte | 48 | Dossiê Contribuinte NIF - 4.3.7 > IP(s) das NFs > Contribuintes Detalhe | Table | CNPJ, IP | `sql_xml/dossie_contribuinte/048_contribuintes_detalhe.sql` |
| dossie_pessoa_fisica | 1 | Dossiê Pessoa Física 1.3 | Table | CPF_, NOME | `sql_xml/dossie_pessoa_fisica/001_consulta_raiz_dossie_pessoa_fisica_1_3.sql` |
| dossie_pessoa_fisica | 2 | Dossiê Pessoa Física 1.3 > Empresas em que é/foi sócio(a) | Table | CPF | `sql_xml/dossie_pessoa_fisica/002_empresas_em_que_e_foi_socio_a.sql` |
| dossie_pessoa_fisica | 3 | Dossiê Pessoa Física 1.3 > Veículos | Table | CPF | `sql_xml/dossie_pessoa_fisica/003_veiculos.sql` |
| dossie_pessoa_fisica | 4 | Dossiê Pessoa Física 1.3 > Endereços NFe | Table | CPF | `sql_xml/dossie_pessoa_fisica/004_enderecos_nfe.sql` |
| dossie_pessoa_fisica | 5 | Dossiê Pessoa Física 1.3 > Conta Corrente | Table | CPF | `sql_xml/dossie_pessoa_fisica/005_conta_corrente.sql` |
| dossie_pessoa_fisica | 6 | Dossiê Pessoa Física 1.3 > Conta Corrente > Detalhe | Table | CPF, SITUACAO | `sql_xml/dossie_pessoa_fisica/006_detalhe.sql` |
| dossie_pessoa_fisica | 7 | Dossiê Pessoa Física 1.3 > NFe - Consumo | Table | CPF | `sql_xml/dossie_pessoa_fisica/007_nfe_consumo.sql` |
| dossie_pessoa_fisica | 8 | Dossiê Pessoa Física 1.3 > Eleições - TSE | Table | CPF | `sql_xml/dossie_pessoa_fisica/008_eleicoes_tse.sql` |
| dossie_pessoa_fisica | 9 | Dossiê Pessoa Física 1.3 > DIMP | Table | CPF | `sql_xml/dossie_pessoa_fisica/009_dimp.sql` |
| dossie_pessoa_fisica | 10 | Dossiê Pessoa Física 1.3 > Outros endereços | Table | CPF | `sql_xml/dossie_pessoa_fisica/010_outros_enderecos.sql` |
| dossie_pessoa_fisica | 11 | Dossiê Pessoa Física 1.3 > Autos de Infração | Table | CPF | `sql_xml/dossie_pessoa_fisica/011_autos_de_infracao.sql` |
| dossie_pessoa_fisica | 12 | Dossiê Pessoa Física 1.3 > Autos de Infração > Descrição do AI | Script | NU_TERMO_INFRACAO | `sql_xml/dossie_pessoa_fisica/012_descricao_do_ai.sql` |
| dossie_pessoa_fisica | 13 | Dossiê Pessoa Física 1.3 > Processo(s) Administrativo(s) | Table | CPF | `sql_xml/dossie_pessoa_fisica/013_processo_s_administrativo_s.sql` |
