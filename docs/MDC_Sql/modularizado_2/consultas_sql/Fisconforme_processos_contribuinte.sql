SELECT
    p.cpf_cnpj,
    p.malhas_id,
    m.titulo,
    --p.periodo,
    SUBSTR(p.periodo, 5, 2) || '/' || SUBSTR(p.periodo, 1, 4) AS periodo,
    p.data_ciencia,
    p.status,
        CASE
        WHEN p.status = '0' THEN 'pendente'
        WHEN p.status = '4' THEN 'pendente indeferido'
        WHEN p.status = '6' THEN 'notificado'
        ELSE 'outro'
    END AS status_nome
FROM
    APP_PENDENCIA.pendencias p
    LEFT JOIN app_pendencia.malhas m ON p.malhas_id = m.id
    where p.cpf_cnpj = :CNPJ
    and p.status in ('0','4', '6')
