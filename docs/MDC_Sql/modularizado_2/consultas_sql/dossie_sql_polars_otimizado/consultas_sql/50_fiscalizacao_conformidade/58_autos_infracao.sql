-- Objetivo: autos de infração relacionados ao contribuinte
-- Binds esperados: :CO_CNPJ_CPF

WITH acao_fiscal AS (
    SELECT SUBSTR(dft.it_nu_diligencia,1,5) || '7' || SUBSTR(dft.it_nu_diligencia,7) AS nu_acao_fiscal
    FROM sitafe.sitafe_diligencia_fiscal_taref dft
    WHERE dft.it_nu_identificacao = :CO_CNPJ_CPF
    UNION
    SELECT t.nu_acao_fiscal
    FROM bi.dm_acao_fiscal t
    WHERE t.co_cnpj_cpf = :CO_CNPJ_CPF
    UNION
    SELECT ainf.nu_acao_fiscal
    FROM bi.arr_f_lancamento_detalhe l
    INNER JOIN bi.fato_acao_fiscal_ainf ainf
            ON ainf.nu_guia_lanc_multa = l.numero_guia
    WHERE l.cnpj_cpf = :CO_CNPJ_CPF
),
solid_trb AS (
    SELECT
        d.it_nu_guia,
        LISTAGG(p.co_cnpj_cpf || ' - ' || p.no_razao_social, ', ') WITHIN GROUP (ORDER BY d.it_nu_guia) AS solidarios_tributo
    FROM sitafe.sitafe_devedor_solidario d
    LEFT JOIN bi.dm_pessoa p
           ON d.it_nu_cpf_cnpj_devedor = p.co_cnpj_cpf
    GROUP BY d.it_nu_guia
),
solid_mta AS (
    SELECT
        d.it_nu_guia,
        LISTAGG(p.co_cnpj_cpf || ' - ' || p.no_razao_social, ', ') WITHIN GROUP (ORDER BY d.it_nu_guia) AS solidarios_multa
    FROM sitafe.sitafe_devedor_solidario d
    LEFT JOIN bi.dm_pessoa p
           ON d.it_nu_cpf_cnpj_devedor = p.co_cnpj_cpf
    GROUP BY d.it_nu_guia
)
SELECT
    l.cnpj_cpf,
    t.da_lavratura_auto AS da_lavratura,
    t.nu_termo_infracao,
    UPPER(CONVERT(t.no_local_lavratura, 'AL32UTF8', 'WE8MSWIN1252')) AS no_local_lavratura,
    t.va_tributo,
    t.va_multa,
    t.va_juros,
    (t.va_tributo + t.va_multa + t.va_juros) AS valor_total_auto,
    t.da_periodo_inicio_auto AS da_periodo_inicio,
    t.da_periodo_final_auto AS da_periodo_fim,
    tate.no_situacao AS situacao_tate,
    t.nu_guia_lanc_trib,
    t.in_in_sit_lanc_trib,
    st.solidarios_tributo,
    t.nu_guia_lanc_multa,
    t.in_in_sit_lanc_multa,
    sm.solidarios_multa,
    t.nu_acao_fiscal
FROM acao_fiscal a
LEFT JOIN bi.fato_acao_fiscal_ainf t
       ON a.nu_acao_fiscal = t.nu_acao_fiscal
LEFT JOIN bi.dm_acao_fiscal_historico_tate tate
       ON t.nu_termo_infracao = tate.nu_termo_infracao
LEFT JOIN solid_trb st
       ON st.it_nu_guia = t.nu_guia_lanc_trib
LEFT JOIN solid_mta sm
       ON sm.it_nu_guia = t.nu_guia_lanc_multa
LEFT JOIN bi.arr_f_lancamento_detalhe l
       ON t.nu_termo_infracao = l.numero_complemento
WHERE tate.in_ultima = 9
  AND (l.cnpj_cpf IS NULL OR l.cnpj_cpf = :CO_CNPJ_CPF)
ORDER BY t.da_lavratura_auto DESC;
