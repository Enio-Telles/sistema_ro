WITH PARAMETROS AS (
    SELECT
        :CNPJ_CPF AS cnpj_cpf_filtro,
        TO_DATE(:DATA_INICIAL, 'DD/MM/YYYY') AS dt_ini_filtro,
        TO_DATE(:DATA_FINAL,   'DD/MM/YYYY') AS dt_fim_filtro
    FROM dual
),

ORDEM AS (
    SELECT
        1 AS ordem,
        p.cnpj_cpf_filtro AS cnpj_cpf
    FROM PARAMETROS p
),

NOTIFICACOES_FISCONFORME AS (
    SELECT
        n.co_cnpj_notif,
        n.id_fisconforme,
        p.num_processo,
        MAX(n.id_notificacao) AS notificacao
    FROM ORDEM o
    JOIN bi.fato_det_notificacao n
      ON n.co_cnpj_notif = o.cnpj_cpf
     AND n.cpf_notificador = 'FISCONFORME'
     AND n.tp_status NOT IN ('5 - CANCELADA', '1 - PROCESSADA')
    LEFT JOIN processo_det.processos p
      ON p.id_sistema = n.id_fisconforme
    GROUP BY
        n.co_cnpj_notif,
        n.id_fisconforme,
        p.num_processo
)

SELECT
    o.cnpj_cpf AS cnpj_cpf,
    t.malhas_id AS "ID MALHA",
    m.titulo AS MALHA,
    t.id AS "ID FISCONF",
    TO_CHAR(n.notificacao) AS notificacao,
    SUBSTR(t.periodo, 1, 4) || '/' || SUBSTR(t.periodo, 5, 2) AS periodo,
    c.qtd_json AS "QTDE DOC",
    CASE
        WHEN t.status = 0  THEN '0- Pendente'
        WHEN t.status = 1  THEN '1- contestado'
        WHEN t.status = 2  THEN '2- resolvido'
        WHEN t.status = 4  THEN '4- Indeferido'
        WHEN t.status = 5  THEN '5- Deferido'
        WHEN t.status = 7  THEN '7- Deferido Automaticamente'
        WHEN t.status = 10 THEN '10- Fiscalizado'
        WHEN t.status = 11 THEN '11- Inapta'
        ELSE TO_CHAR(t.status)
    END AS status,
    c.valor,
    n.num_processo AS "PROCESSO DET"
FROM ORDEM o
JOIN PARAMETROS p
  ON 1 = 1
JOIN app_pendencia.pendencias t
  ON t.cpf_cnpj = o.cnpj_cpf
 AND t.status IN (0, 4)
 AND TO_DATE(t.periodo, 'YYYYMM')
        BETWEEN TRUNC(p.dt_ini_filtro, 'MM')
            AND TRUNC(p.dt_fim_filtro, 'MM')
 AND t.malhas_id IN (10120, 10061)
LEFT JOIN app_pendencia.malhas m
  ON m.id = t.malhas_id
LEFT JOIN bi.dm_consolidado_pendencias c
  ON c.pendencia_id = t.id
LEFT JOIN NOTIFICACOES_FISCONFORME n
  ON n.id_fisconforme = t.id
 AND n.co_cnpj_notif = t.cpf_cnpj
ORDER BY
    o.ordem,
    m.titulo,
    t.id,
    periodo,
    notificacao;