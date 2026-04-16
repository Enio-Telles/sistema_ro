-- Objetivo: diligências fiscais vinculadas diretamente ao identificador do contribuinte
-- Binds esperados: :CO_CNPJ_CPF

WITH origem_acao AS (
    SELECT
        dta.tuk,
        LISTAGG(dta.it_tx_atividade) WITHIN GROUP (ORDER BY dta.m_occurs) AS tx_origem_acao
    FROM sitafe.sitafe_diligencia_tx_atividade dta
    GROUP BY dta.tuk
)
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
WHERE dft.it_nu_identificacao = :CO_CNPJ_CPF;
