-- Objetivo: vistorias oriundas do aplicativo de vistoria
-- Binds esperados: :CO_CNPJ_CPF

SELECT
    'APP_VISTORIA' AS origem_vistoria,
    TO_CHAR(v.id) AS id_vistoria,
    v.status,
    v.dt_vistoria,
    v.modalidade_id,
    m.nome AS modalidade,
    v.dsf,
    v.processo,
    ps.no_razao_social AS solicitante,
    pa.no_razao_social AS auditor,
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
WHERE v.cnpj_empresa = :CO_CNPJ_CPF;
