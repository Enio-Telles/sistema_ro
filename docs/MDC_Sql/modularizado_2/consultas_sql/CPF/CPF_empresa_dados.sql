/*
    Analise da Consulta: CPF_empresa_dados.sql
    Objetivo: Exibir dados cadastrais completos de uma empresa/contribuinte.

    Tabelas Utilizadas:
    - bi.dm_pessoa (t): Cadastro principal de pessoas juridicas/fisicas.
      Colunas: co_cnpj_cpf, co_cad_icms (IE), no_razao_social, endereco, in_situacao, etc.
    - bi.dm_localidade (localid): Municipios e UFs.
    - bi.dm_regime_pagto_descricao (rp): Descricoes de regimes de pagamento.
    - BI.DM_SITUACAO_CONTRIBUINTE (s): Descricoes de situacoes cadastrais.
    - sitafe.sitafe_historico_gr_situacao / sitafe_historico_situacao: Historico de situacoes.

    Logica Principal:
    1. Busca dados basicos do contribuinte (CNPJ, IE, nome, endereco).
    2. Enriquece com descricoes de tabelas dimensao (localidade, regime, situacao).
    3. Calcula periodo em atividade (meses entre inicio e ultima situacao).
    4. Gera link para portal do contribuinte.
    5. Formata situacao com cores: Azul = Ativo (001), Vermelho = Demais.
*/

SELECT
                          t.co_cnpj_cpf                                                 "CNPJ",
                          t.co_cad_icms                                                 "IE",
                          t.no_razao_social                              "Nome",
                          t.DESC_ENDERECO||' '||t.BAIRRO                                "Endereco",
                          localid.no_municipio                                          "Municipio",
                          localid.co_uf                                                 "UF",
                          t.co_regime_pagto|| ' - '|| rp.no_regime_pagamento            "Regime de Pagamento",
                          -- Formatacao da situacao com cores HTML
                          CASE WHEN t.in_situacao = '001'
                                THEN t.in_situacao
                                      || ' - '|| s.desc_situacao
                                ELSE t.in_situacao
                                      || ' - '|| convert(s.desc_situacao,'AL32UTF8','WE8MSWIN1252')
                                END                                                     "Situacao da IE",
                          t.da_inicio_atividade                                         "Data de Inicio da Atividade",
                          to_date(us.data_ult_sit, 'YYYYMMDD')                          "Data da Ultima situacao",
                          -- Calculo do periodo em atividade (em meses)
                          to_char(trunc(months_between((CASE WHEN t.in_situacao = '001'
                                                              THEN SYSDATE
                                                          ELSE to_date(us.data_ult_sit, 'YYYYMMDD')
                                                      END),
                                                      t.da_inicio_atividade),2))||' meses'     "Periodo em atividade",
                          -- Link para portal do contribuinte
                          'https://portalcontribuinte.sefin.ro.gov.br/Publico/parametropublica.jsp?NuDevedor=' || t.co_cad_icms redesim
                      FROM
                          bi.dm_pessoa                 t
                            LEFT JOIN bi.dm_localidade localid ON t.co_municipio = localid.co_municipio
                            LEFT JOIN bi.dm_regime_pagto_descricao rp ON t.co_regime_pagto = rp.co_regime_pagamento
                            LEFT JOIN(
                                    SELECT
                                            CO_SITUACAO_CONTRIBUINTE    CO_SITUACAO,
                                            NO_SITUACAO_CONTRIBUINTE    DESC_SITUACAO
                                        FROM BI.DM_SITUACAO_CONTRIBUINTE
                              )    s ON t.in_situacao = s.co_situacao
                            -- Subquery para obter a data da ultima alteracao de situacao
                            LEFT JOIN(
                                    SELECT
                                            MAX(u.it_da_transacao) data_ult_sit,
                                            u.it_nu_inscricao_estadual
                                      FROM
                                            sitafe.sitafe_historico_gr_situacao t
                                            LEFT JOIN sitafe.sitafe_historico_situacao    u ON t.tuk = u.tuk
                                     WHERE
                                          t.it_co_situacao_contribuinte NOT IN('030','150','005')
                                            AND u.it_co_usuario NOT IN('INTERNET','P30015AC   ')
                                     GROUP BY
                                          u.it_nu_inscricao_estadual
                              )    us ON t.co_cad_icms = us.it_nu_inscricao_estadual
                     WHERE
                          t.co_cnpj_cpf = :CO_CNPJ_CPF
