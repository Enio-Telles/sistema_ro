WITH DADOS_BRUTOS AS (
    SELECT
        t.co_cnpj_cpf                                                                   AS "CNPJ",
        t.co_cad_icms                                                                   AS "IE",
        t.no_razao_social                                                               AS "Nome",
        t.DESC_ENDERECO || ' ' || t.BAIRRO                                              AS "Endere�o",
        localid.no_municipio                                                            AS "Munic�pio",
        localid.co_uf                                                                   AS "UF",
        t.co_regime_pagto || ' - ' || rp.no_regime_pagamento                            AS "Regime de Pagamento",
        CASE WHEN t.in_situacao = '001'
             THEN t.in_situacao || ' - ' || s.desc_situacao
             ELSE t.in_situacao || ' - ' || convert(s.desc_situacao,'AL32UTF8','WE8MSWIN1252')
        END                                                                             AS "Situa��o da IE",
        -- Datas convertidas para Texto para permitir o UNPIVOT
        TO_CHAR(t.da_inicio_atividade, 'DD/MM/YYYY')                                    AS "Data de In�cio da Atividade",
        TO_CHAR(to_date(us.data_ult_sit, 'YYYYMMDD'), 'DD/MM/YYYY')                     AS "Data da �ltima situa��o",
        to_char(trunc(months_between((CASE WHEN t.in_situacao = '001'
                                           THEN SYSDATE
                                           ELSE to_date(us.data_ult_sit, 'YYYYMMDD')
                                      END),
                                      t.da_inicio_atividade),2)) || ' meses'            AS "Per�odo em atividade",
        'https://portalcontribuinte.sefin.ro.gov.br/...NuDevedor=' || t.co_cad_icms     AS "Link Redesim"
    FROM
        bi.dm_pessoa t
        LEFT JOIN bi.dm_localidade localid ON t.co_municipio = localid.co_municipio
        LEFT JOIN bi.dm_regime_pagto_descricao rp ON t.co_regime_pagto = rp.co_regime_pagamento
        LEFT JOIN(
            SELECT CO_SITUACAO_CONTRIBUINTE CO_SITUACAO, NO_SITUACAO_CONTRIBUINTE DESC_SITUACAO
            FROM BI.DM_SITUACAO_CONTRIBUINTE
        ) s ON t.in_situacao = s.co_situacao
        LEFT JOIN(
            SELECT MAX(u.it_da_transacao) data_ult_sit, u.it_nu_inscricao_estadual
            FROM sitafe.sitafe_historico_gr_situacao t
            LEFT JOIN sitafe.sitafe_historico_situacao u ON t.tuk = u.tuk
            WHERE t.it_co_situacao_contribuinte NOT IN('030','150','005')
              AND u.it_co_usuario NOT IN('INTERNET','P30015AC   ')
            GROUP BY u.it_nu_inscricao_estadual
        ) us ON t.co_cad_icms = us.it_nu_inscricao_estadual
    WHERE
        t.co_cnpj_cpf = :CNPJ
)
-- Transforma as colunas em linhas
SELECT
    Campo,
    Valor
FROM DADOS_BRUTOS
UNPIVOT (
    Valor FOR Campo IN (
        "CNPJ",
        "IE",
        "Nome",
        "Endere�o",
        "Munic�pio",
        "UF",
        "Regime de Pagamento",
        "Situa��o da IE",
        "Data de In�cio da Atividade",
        "Data da �ltima situa��o",
        "Per�odo em atividade",
        "Link Redesim"
    )
);
