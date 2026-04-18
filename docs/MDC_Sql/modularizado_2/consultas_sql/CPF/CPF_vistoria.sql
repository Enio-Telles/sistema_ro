-- CPF_vistoria.sql
-- Extraído de dossie_contribuinte.xml - Vistorias
-- Parâmetro: :CO_CNPJ_CPF

WITH total AS (
    SELECT
        'APP VISTORIA' tipo,
        to_char(t.id) id,
        t.status,
        t.dt_vistoria,
        t.modalidade_id || ' - ' || m.nome modalidade,
        t.dsf,
        t.processo,
        ps.no_razao_social solicitante,
        p.no_razao_social auditor,
        null autos
    FROM
        vistoria.empresas_vistorias@vistoria_producao t
        LEFT JOIN vistoria.modalidades@vistoria_producao m ON t.modalidade_id = m.id
        LEFT JOIN bi.dm_pessoa p ON t.cpf_auditor = p.co_cnpj_cpf
        LEFT JOIN bi.dm_pessoa ps ON t.cpf_solicitante = ps.co_cnpj_cpf
        LEFT JOIN vistoria.documentos_assinados@vistoria_producao d ON t.id = d.empresa_vistoria_id
    WHERE t.cnpj_empresa = :CO_CNPJ_CPF

    UNION

    SELECT
        'SITAFE VISTORIA' tipo,
        to_char(df.it_nu_diligencia) id,
        CASE
            WHEN df.it_co_situacao_diligencia = 01 THEN '01 - DOC. REGISTRADO'
            WHEN df.it_co_situacao_diligencia = 02 THEN '02 - DIL. GERADA'
            WHEN df.it_co_situacao_diligencia = 03 THEN '03 - DIL. ENTREGUE'
            WHEN df.it_co_situacao_diligencia = 04 THEN '04 - DIL. CONCLUÍDA'
            WHEN df.it_co_situacao_diligencia = 05 THEN '05 - DIL. EXCLUÍDA'
        END status,
        to_date(df.it_da_lancamento,'yyyymmdd') dt_vistoria,
        dft.it_nu_documento_origem modalidade,
        null dsf,
        dft.it_nu_diligencia processo,
        null solicitante,
        su.it_co_matricula_usuario||' - '||su.it_no_usuario auditor,
        da.autos autos
    FROM sitafe.sitafe_diligencia_fiscal_taref dft
        LEFT JOIN sitafe.sitafe_diligencia_fiscal df
            ON df.it_nu_diligencia = substr(dft.it_nu_diligencia,1,5)||'7'||substr(dft.it_nu_diligencia,7)
        LEFT JOIN sitafe.sitafe_dilig_it_nu_afte afte
            ON afte.tuk = df.tuk
            AND afte.m_occurs = 1
        LEFT JOIN sitafe.sitafe_usuario su
            ON to_number(su.it_co_matricula_usuario) = to_number(afte.it_nu_afte)
        LEFT JOIN (
            SELECT da.it_nu_acao_fiscal,
                   listagg(da.it_nu_ai,' * ' on overflow truncate) within group (order by da.it_nu_acao_fiscal) autos
            FROM sitafe.sitafe_diligencia_autos da
            GROUP BY da.it_nu_acao_fiscal
        ) da ON da.it_nu_acao_fiscal = df.it_nu_diligencia
    WHERE dft.it_nu_identificacao = :CO_CNPJ_CPF
)
SELECT
    t.tipo TIPO,
    t.id ID,
    t.status STATUS,
    t.dt_vistoria DATA_VISTORIA,
    t.modalidade MODALIDADE,
    t.dsf DSF,
    t.processo PROCESSO,
    t.solicitante SOLICITANTE,
    t.auditor AUDITOR,
    t.autos AUTOS,
    d.documento_assinatura RELATORIO
FROM
    total t
    LEFT JOIN vistoria.documentos_assinados@vistoria_producao d
        ON t.tipo || t.id = 'APP VISTORIA' || d.empresa_vistoria_id
ORDER BY 4 DESC
