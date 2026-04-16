-- Objetivo: notificações DET não vinculadas ao FisConforme
-- Binds esperados: :CO_CNPJ_CPF

SELECT
    t.co_cnpj_notif AS co_cnpj_cpf,
    t.dt_envio,
    t.id_notificacao,
    UPPER(t.tx_descricao) AS descricao,
    t.tp_status,
    t.dt_ciencia,
    t.co_cpf_cnpj_ciencia,
    t.no_pessoa_ciencia,
    t.nu_ip_ciencia,
    n.cpf AS cpf_notificador,
    p.no_razao_social AS no_notificador
FROM bi.fato_det_notificacao t
LEFT JOIN det.notificadores n
       ON t.id_notificador = n.id
LEFT JOIN bi.dm_pessoa p
       ON n.cpf = p.co_cnpj_cpf
WHERE t.id_fisconforme IS NULL
  AND t.co_cnpj_notif = :CO_CNPJ_CPF
  AND t.tp_status NOT IN ('1 - PROCESSADA', '5 - CANCELADA')
ORDER BY t.dt_envio DESC;
