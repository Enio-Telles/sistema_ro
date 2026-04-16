-- Objetivo: diligências/vistorias registradas no SITAFE
-- Binds esperados: :CO_CNPJ_CPF

WITH autos AS (
    SELECT
        da.it_nu_acao_fiscal,
        LISTAGG(da.it_nu_ai, ' * ' ON OVERFLOW TRUNCATE) WITHIN GROUP (ORDER BY da.it_nu_acao_fiscal) AS autos
    FROM sitafe.sitafe_diligencia_autos da
    GROUP BY da.it_nu_acao_fiscal
)
SELECT
    'SITAFE_VISTORIA' AS origem_vistoria,
    TO_CHAR(df.it_nu_diligencia) AS id_vistoria,
    df.it_co_situacao_diligencia AS co_status,
    TO_DATE(df.it_da_lancamento, 'YYYYMMDD') AS dt_vistoria,
    dft.it_nu_documento_origem AS modalidade,
    NULL AS dsf,
    dft.it_nu_diligencia AS processo,
    NULL AS solicitante,
    su.it_co_matricula_usuario || ' - ' || su.it_no_usuario AS auditor,
    a.autos
FROM sitafe.sitafe_diligencia_fiscal_taref dft
LEFT JOIN sitafe.sitafe_diligencia_fiscal df
       ON df.it_nu_diligencia = SUBSTR(dft.it_nu_diligencia,1,5) || '7' || SUBSTR(dft.it_nu_diligencia,7)
LEFT JOIN sitafe.sitafe_dilig_it_nu_afte afte
       ON afte.tuk = df.tuk
      AND afte.m_occurs = 1
LEFT JOIN sitafe.sitafe_usuario su
       ON TO_NUMBER(su.it_co_matricula_usuario) = TO_NUMBER(afte.it_nu_afte)
LEFT JOIN autos a
       ON a.it_nu_acao_fiscal = df.it_nu_diligencia
WHERE dft.it_nu_identificacao = :CO_CNPJ_CPF;
