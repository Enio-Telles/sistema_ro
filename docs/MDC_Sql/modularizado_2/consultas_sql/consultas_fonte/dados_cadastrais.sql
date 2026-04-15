SELECT
    t.co_cnpj_cpf "CNPJ",
    t.co_cad_icms "IE",
    t.no_razao_social "RAZAO_SOCIAL",
    t.desc_endereco || ' ' || t.bairro "ENDERECO",
    localid.no_municipio "MUNICIPIO",
    localid.co_uf "UF",
    t.co_regime_pagto || ' - ' || rp.no_regime_pagamento "Regime_de_Pagamento",
    CASE
        WHEN t.in_situacao = '001' THEN t.in_situacao || ' - ' || s.desc_situacao
        ELSE t.in_situacao || ' - ' || CONVERT(
            s.desc_situacao,
            'AL32UTF8',
            'WE8MSWIN1252'
        )
    END "Situacao_da_IE",
    t.da_inicio_atividade "Data_de_Inicio_da_Atividade",
    TO_DATE(us.data_ult_sit, 'YYYYMMDD') "Data_da_ultima_situacao",
    TO_CHAR(
        TRUNC(
            MONTHS_BETWEEN (
                CASE
                    WHEN t.in_situacao = '001' THEN SYSDATE
                    ELSE TO_DATE(us.data_ult_sit, 'YYYYMMDD')
                END,
                t.da_inicio_atividade
            ),
            2
        )
    ) || ' meses' "Periodo_em_atividade",
    'https://portalcontribuinte.sefin.ro.gov.br/Publico/parametropublica.jsp?NuDevedor=' || t.co_cad_icms "REDESIM",
    t.co_cnae || ' - ' || cnae.no_cnae "Atividade_Principal",

-- Coluna de Regime Especial (agora traz apenas o mais recente)
NVL (reg.regime_especial, '-') "Regime_Especial"
FROM
    bi.dm_pessoa t
    LEFT JOIN bi.dm_localidade localid ON t.co_municipio = localid.co_municipio
    LEFT JOIN bi.dm_regime_pagto_descricao rp ON t.co_regime_pagto = rp.co_regime_pagamento
    LEFT JOIN (
        SELECT
            co_situacao_contribuinte AS co_situacao,
            no_situacao_contribuinte AS desc_situacao
        FROM bi.dm_situacao_contribuinte
    ) s ON t.in_situacao = s.co_situacao
    LEFT JOIN (
        SELECT MAX(u.it_da_transacao) AS data_ult_sit, u.it_nu_inscricao_estadual
        FROM sitafe.sitafe_historico_gr_situacao t_hist
            LEFT JOIN sitafe.sitafe_historico_situacao u ON t_hist.tuk = u.tuk
        WHERE
            t_hist.it_co_situacao_contribuinte NOT IN ('030', '150', '005')
            AND u.it_co_usuario NOT IN ('INTERNET', 'P30015AC   ')
        GROUP BY
            u.it_nu_inscricao_estadual
    ) us ON t.co_cad_icms = us.it_nu_inscricao_estadual
    LEFT JOIN bi.dm_cnae cnae ON t.co_cnae = cnae.co_cnae

-- JOIN DO REGIME ESPECIAL (Trazendo apenas o de maior da_cadastro):
LEFT JOIN (
    SELECT
        cnpj_cpf,
        it_co_regime || ' - ' || it_no_regime || ' - ' || it_nu_ato || ' - ' || it_nu_processo || ' - ' || datas_formatadas || ' - ' || it_tx_observacao AS regime_especial
    FROM (
            SELECT
                SUBSTR(tr.gr_identificacao, 2, 14) AS cnpj_cpf, tr.it_co_regime, CONVERT(
                    rr.it_no_regime, 'AL32UTF8', 'WE8MSWIN1252'
                ) AS it_no_regime, tr.it_nu_ato, tr.it_nu_processo, TRIM(
                    CASE
                        WHEN tr.it_da_cadastro > '1' THEN TO_CHAR(
                            TO_DATE(tr.it_da_cadastro, 'YYYYMMDD'), 'DD/MM/YYYY'
                        )
                        ELSE ''
                    END || CASE
                        WHEN tr.it_da_baixa > '1' THEN ' até ' || TO_CHAR(
                            TO_DATE(tr.it_da_baixa, 'YYYYMMDD'), 'DD/MM/YYYY'
                        )
                        ELSE ''
                    END
                ) AS datas_formatadas, CONVERT(
                    tr.it_tx_observacao, 'AL32UTF8', 'WE8MSWIN1252'
                ) AS it_tx_observacao,
                -- Função de janela para criar um ranking ordenando pela maior data de cadastro
                ROW_NUMBER() OVER (
                    PARTITION BY
                        SUBSTR(tr.gr_identificacao, 2, 14)
                    ORDER BY tr.it_da_cadastro DESC
                ) AS rn
            FROM sitafe.sitafe_regime_contribuinte tr
                LEFT JOIN (
                    SELECT it_co_regime, MAX(it_no_regime) AS it_no_regime
                    FROM sitafe.sitafe_regime_especial_padrao
                    GROUP BY
                        it_co_regime
                ) rr ON tr.it_co_regime = rr.it_co_regime
            WHERE
                SUBSTR(tr.gr_identificacao, 2, 14) =:CNPJ
                AND tr.it_in_ultima = '9'
        )
    WHERE
        rn = 1 -- Pega apenas a linha que ficou em 1º lugar no ranking (a mais recente)
) reg ON t.co_cnpj_cpf = reg.cnpj_cpf
WHERE
    t.co_cnpj_cpf =:CNPJ