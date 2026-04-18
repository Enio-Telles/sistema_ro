-- CPF_dados_cadastrais.sql
-- Extraído de dossie_contribuinte.xml - Dados cadastrais
-- Parâmetro: :CO_CNPJ_CPF

SELECT
    t.co_cnpj_cpf                                                           CNPJ,
    t.co_cad_icms                                                           IE,
    t.no_razao_social                                                       NOME,
    t.DESC_ENDERECO||' '||t.BAIRRO                                          ENDERECO,
    localid.no_municipio                                                    MUNICIPIO,
    localid.co_uf                                                           UF,
    t.co_regime_pagto|| ' - '|| rp.no_regime_pagamento                      REGIME_PAGAMENTO,
    t.in_situacao || ' - ' || s.desc_situacao                               SITUACAO_IE,
    t.da_inicio_atividade                                                   DATA_INICIO_ATIVIDADE,
    to_date(us.data_ult_sit, 'YYYYMMDD')                                    DATA_ULTIMA_SITUACAO,
    to_char(trunc(months_between(
        CASE WHEN t.in_situacao = '001' THEN SYSDATE
             ELSE to_date(us.data_ult_sit, 'YYYYMMDD')
        END,
        t.da_inicio_atividade),2))||' meses'                                PERIODO_ATIVIDADE
FROM
    bi.dm_pessoa t
    LEFT JOIN bi.dm_localidade localid ON t.co_municipio = localid.co_municipio
    LEFT JOIN bi.dm_regime_pagto_descricao rp ON t.co_regime_pagto = rp.co_regime_pagamento
    LEFT JOIN (
        SELECT
            CO_SITUACAO_CONTRIBUINTE CO_SITUACAO,
            NO_SITUACAO_CONTRIBUINTE DESC_SITUACAO
        FROM BI.DM_SITUACAO_CONTRIBUINTE
    ) s ON t.in_situacao = s.co_situacao
    LEFT JOIN (
        SELECT
            MAX(u.it_da_transacao) data_ult_sit,
            u.it_nu_inscricao_estadual
        FROM
            sitafe.sitafe_historico_gr_situacao t
            LEFT JOIN sitafe.sitafe_historico_situacao u ON t.tuk = u.tuk
        WHERE
            t.it_co_situacao_contribuinte NOT IN('030','150','005')
            AND u.it_co_usuario NOT IN('INTERNET','P30015AC   ')
        GROUP BY u.it_nu_inscricao_estadual
    ) us ON t.co_cad_icms = us.it_nu_inscricao_estadual
WHERE
    t.co_cnpj_cpf = :CO_CNPJ_CPF
