-- Core SQL template: Fisconforme malhas por CNPJ
-- Objetivo: retornar malhas e pendências mais recentes por contribuinte.

SELECT
    p.cpf_cnpj AS cnpj,
    p.id AS id_pendencia,
    n.id_notificacao,
    p.malhas_id,
    m.titulo AS titulo_malha,
    p.periodo,
    p.status AS status_pendencia,
    n.tp_status AS status_notificacao,
    COALESCE(n.dt_ciencia, n.data_ciencia) AS data_ciencia_consolidada
FROM app_pendencia.pendencias p
LEFT JOIN app_pendencia.malhas m
    ON m.id = p.malhas_id
LEFT JOIN bi.fato_det_notificacao n
    ON n.id_fisconforme = p.id
WHERE regexp_replace(p.cpf_cnpj, '[^0-9]', '') = :cnpj
  AND p.periodo BETWEEN :periodo_inicio AND :periodo_fim;
