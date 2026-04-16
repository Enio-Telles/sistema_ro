-- Objetivo: pendências do FisConforme em granularidade detalhada
-- Binds esperados: :CO_CNPJ_CPF

SELECT
    p.cpf_cnpj AS co_cnpj_cpf,
    p.id AS id_pendencia,
    p.malhas_id,
    m.titulo AS titulo_malha,
    p.periodo,
    p.status,
    n.co_cpf_cnpj_ciencia,
    n.no_pessoa_ciencia,
    n.dt_ciencia,
    n.nu_ip_ciencia
FROM app_pendencia.pendencias p
LEFT JOIN app_pendencia.malhas m
       ON p.malhas_id = m.id
LEFT JOIN bi.fato_det_notificacao n
       ON p.id = n.id_fisconforme
WHERE p.cpf_cnpj = :CO_CNPJ_CPF;
