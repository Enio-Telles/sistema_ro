-- Objetivo: resultado consolidado das empresas dos sócios com inadimplência
-- Binds esperados: :CO_CAD_ICMS

WITH socios_alvo AS (
    SELECT DISTINCT socio.gr_identificacao
    FROM sitafe.sitafe_historico_contribuinte t
    LEFT JOIN sitafe.sitafe_historico_socio socio
           ON t.it_nu_fac = socio.it_nu_fac
    WHERE t.it_nu_inscricao_estadual = :CO_CAD_ICMS
),
base AS (
    SELECT
        SUBSTR(h.gr_identificacao, 2) AS cpf_cnpj_socio,
        pe.no_razao_social AS no_socio,
        t.it_nu_inscricao_estadual AS ie_empresa,
        p.co_cnpj_cpf AS co_cnpj_cpf_empresa,
        p.no_razao_social AS no_empresa,
        l.no_municipio,
        p.in_situacao,
        s.no_situacao_contribuinte,
        p.in_conder,
        p.da_inicio_atividade,
        MIN(t.it_da_referencia) OVER (PARTITION BY t.it_nu_inscricao_estadual || h.gr_identificacao) AS referencia_entrada_raw,
        MAX(t.it_da_referencia) OVER (PARTITION BY t.it_nu_inscricao_estadual || h.gr_identificacao) AS referencia_saida_raw,
        MAX(t.it_in_ultima_fac) OVER (PARTITION BY t.it_nu_inscricao_estadual || h.gr_identificacao) AS ult_fac
    FROM sitafe.sitafe_historico_contribuinte t
    LEFT JOIN sitafe.sitafe_historico_socio h
           ON t.it_nu_fac = h.it_nu_fac
    LEFT JOIN bi.dm_pessoa p
           ON t.it_nu_inscricao_estadual = p.co_cad_icms
    LEFT JOIN bi.dm_localidade l
           ON p.co_municipio = l.co_municipio
    LEFT JOIN bi.dm_situacao_contribuinte s
           ON p.in_situacao = s.co_situacao_contribuinte
    LEFT JOIN bi.dm_pessoa pe
           ON SUBSTR(h.gr_identificacao, 2) = pe.co_cnpj_cpf
    WHERE h.gr_identificacao IN (SELECT gr_identificacao FROM socios_alvo)
),
inad AS (
    SELECT
        t.co_cnpj_cpf,
        SUM(t.va_principal + t.va_multa + t.va_juros + t.va_acrescimo) AS inadimplencia_total
    FROM bi.fato_lanc_arrec_sum t
    WHERE t.da_arrecadacao IS NULL
      AND t.id_situacao = '01'
      AND t.vencido = '3'
    GROUP BY t.co_cnpj_cpf
)
SELECT DISTINCT
    b.cpf_cnpj_socio,
    b.no_socio,
    b.ie_empresa,
    b.co_cnpj_cpf_empresa,
    b.no_empresa,
    b.no_municipio,
    b.in_situacao,
    b.no_situacao_contribuinte,
    b.in_conder,
    b.da_inicio_atividade,
    CASE WHEN b.referencia_entrada_raw != '        ' THEN TO_DATE(b.referencia_entrada_raw, 'YYYYMMDD') END AS dt_entrada,
    CASE WHEN b.ult_fac = '9' THEN NULL
         WHEN b.referencia_saida_raw != '        ' THEN TO_DATE(b.referencia_saida_raw, 'YYYYMMDD')
    END AS dt_saida,
    i.inadimplencia_total
FROM base b
LEFT JOIN inad i
       ON b.co_cnpj_cpf_empresa = i.co_cnpj_cpf;
