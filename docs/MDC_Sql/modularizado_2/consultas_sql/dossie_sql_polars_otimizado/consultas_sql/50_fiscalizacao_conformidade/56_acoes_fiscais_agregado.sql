-- Objetivo: consolidar ações fiscais BI e DSF em um conjunto uniforme
-- Binds esperados: :CO_CNPJ_CPF

WITH origem_acao AS (
    SELECT
        dta.tuk,
        LISTAGG(dta.it_tx_atividade) WITHIN GROUP (ORDER BY dta.m_occurs) AS tx_origem_acao
    FROM sitafe.sitafe_diligencia_tx_atividade dta
    GROUP BY dta.tuk
),
dsf_direta AS (
    SELECT
        :CO_CNPJ_CPF AS co_cnpj_cpf,
        'DSF' AS tipo_acao,
        TO_CHAR(df.it_co_situacao_diligencia) AS situacao_acao,
        TO_CHAR(df.it_nu_diligencia) AS nu_acao_fiscal,
        dft.it_nu_diligencia AS nu_dsf,
        NULL AS da_periodo_inicio_fisc,
        NULL AS da_periodo_fim_fisc,
        df.it_prazo_max AS nu_prazo_acao,
        NULL AS nu_prazo_prorrog,
        NULL AS da_distri_acao_fiscal,
        TO_DATE(df.it_da_lancamento DEFAULT NULL ON CONVERSION ERROR, 'YYYYMMDD') AS da_abertu_acao_fiscal,
        TO_DATE(df.it_da_retorno DEFAULT NULL ON CONVERSION ERROR, 'YYYYMMDD') AS da_conclu_acao_fiscal,
        oa.tx_origem_acao,
        dft.it_nu_documento_origem AS tx_documento,
        NULL AS tx_observacao
    FROM sitafe.sitafe_diligencia_fiscal_taref dft
    LEFT JOIN sitafe.sitafe_diligencia_fiscal df
           ON df.it_nu_diligencia = SUBSTR(dft.it_nu_diligencia,1,5) || '7' || SUBSTR(dft.it_nu_diligencia,7)
    LEFT JOIN origem_acao oa
           ON oa.tuk = dft.tuk
    WHERE dft.it_nu_identificacao = :CO_CNPJ_CPF
),
acoes_relacionadas AS (
    SELECT DISTINCT
        SUBSTR(ainf.nu_acao_fiscal,1,5) || SUBSTR(ainf.nu_acao_fiscal,7,8) AS nu_acao_normalizada
    FROM bi.arr_f_lancamento_detalhe l
    INNER JOIN bi.fato_acao_fiscal_ainf ainf
            ON ainf.nu_guia_lanc_multa = l.numero_guia
    WHERE l.cnpj_cpf = :CO_CNPJ_CPF
),
dsf_indireta AS (
    SELECT
        :CO_CNPJ_CPF AS co_cnpj_cpf,
        'DSF' AS tipo_acao,
        TO_CHAR(df.it_co_situacao_diligencia) AS situacao_acao,
        TO_CHAR(df.it_nu_diligencia) AS nu_acao_fiscal,
        dft.it_nu_diligencia AS nu_dsf,
        NULL AS da_periodo_inicio_fisc,
        NULL AS da_periodo_fim_fisc,
        df.it_prazo_max AS nu_prazo_acao,
        NULL AS nu_prazo_prorrog,
        NULL AS da_distri_acao_fiscal,
        TO_DATE(df.it_da_lancamento DEFAULT NULL ON CONVERSION ERROR, 'YYYYMMDD') AS da_abertu_acao_fiscal,
        TO_DATE(df.it_da_retorno DEFAULT NULL ON CONVERSION ERROR, 'YYYYMMDD') AS da_conclu_acao_fiscal,
        oa.tx_origem_acao,
        dft.it_nu_documento_origem AS tx_documento,
        NULL AS tx_observacao
    FROM sitafe.sitafe_diligencia_fiscal_taref dft
    LEFT JOIN sitafe.sitafe_diligencia_fiscal df
           ON df.it_nu_diligencia = SUBSTR(dft.it_nu_diligencia,1,5) || '7' || SUBSTR(dft.it_nu_diligencia,7)
    LEFT JOIN origem_acao oa
           ON oa.tuk = dft.tuk
    WHERE SUBSTR(dft.it_nu_diligencia,1,5) || SUBSTR(dft.it_nu_diligencia,7,8) IN (
        SELECT nu_acao_normalizada FROM acoes_relacionadas
    )
),
bi_acao AS (
    SELECT
        t.co_cnpj_cpf,
        t.in_modelo_acao_fiscal AS tipo_acao,
        t.no_situacao_acao AS situacao_acao,
        t.nu_acao_fiscal,
        t.nu_dfe AS nu_dsf,
        t.da_periodo_inicio_fisc,
        t.da_periodo_fim_fisc,
        t.nu_prazo_acao,
        t.nu_prazo_prorrog,
        t.da_distri_acao_fiscal,
        t.da_abertu_acao_fiscal,
        t.da_conclu_acao_fiscal,
        o.tx_origem_acao,
        t.tx_documento,
        t.tx_observacao
    FROM bi.dm_acao_fiscal t
    LEFT JOIN bi.dm_acao_fiscal_origem_acao o
           ON t.nu_acao_fiscal = o.nu_acao_fiscal
    WHERE t.co_cnpj_cpf = :CO_CNPJ_CPF
)
SELECT * FROM bi_acao
UNION ALL
SELECT * FROM dsf_direta
UNION ALL
SELECT * FROM dsf_indireta;
