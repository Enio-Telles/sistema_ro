-- Objetivo: consolidar vistorias das duas origens em formato uniforme
-- Binds esperados: :CO_CNPJ_CPF

WITH app_vistoria AS (
    SELECT
        'APP_VISTORIA' AS origem_vistoria,
        TO_CHAR(v.id) AS id_vistoria,
        v.status AS ds_status,
        v.dt_vistoria,
        m.nome AS modalidade,
        v.dsf,
        v.processo,
        ps.no_razao_social AS solicitante,
        pa.no_razao_social AS auditor,
        CAST(NULL AS VARCHAR2(4000)) AS autos,
        d.documento_assinatura
    FROM vistoria.empresas_vistorias@vistoria_producao v
    LEFT JOIN vistoria.modalidades@vistoria_producao m
           ON v.modalidade_id = m.id
    LEFT JOIN bi.dm_pessoa pa
           ON v.cpf_auditor = pa.co_cnpj_cpf
    LEFT JOIN bi.dm_pessoa ps
           ON v.cpf_solicitante = ps.co_cnpj_cpf
    LEFT JOIN vistoria.documentos_assinados@vistoria_producao d
           ON v.id = d.empresa_vistoria_id
    WHERE v.cnpj_empresa = :CO_CNPJ_CPF
),
autos AS (
    SELECT
        da.it_nu_acao_fiscal,
        LISTAGG(da.it_nu_ai, ' * ' ON OVERFLOW TRUNCATE) WITHIN GROUP (ORDER BY da.it_nu_acao_fiscal) AS autos
    FROM sitafe.sitafe_diligencia_autos da
    GROUP BY da.it_nu_acao_fiscal
),
sitafe_vistoria AS (
    SELECT
        'SITAFE_VISTORIA' AS origem_vistoria,
        TO_CHAR(df.it_nu_diligencia) AS id_vistoria,
        TO_CHAR(df.it_co_situacao_diligencia) AS ds_status,
        TO_DATE(df.it_da_lancamento, 'YYYYMMDD') AS dt_vistoria,
        dft.it_nu_documento_origem AS modalidade,
        NULL AS dsf,
        dft.it_nu_diligencia AS processo,
        NULL AS solicitante,
        su.it_co_matricula_usuario || ' - ' || su.it_no_usuario AS auditor,
        a.autos,
        CAST(NULL AS BLOB) AS documento_assinatura
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
    WHERE dft.it_nu_identificacao = :CO_CNPJ_CPF
)
SELECT * FROM app_vistoria
UNION ALL
SELECT * FROM sitafe_vistoria;
