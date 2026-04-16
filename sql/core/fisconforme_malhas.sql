-- fisconforme_malhas.sql
-- grupo: core
-- dominio: Fisconforme
-- objetivo: malhas e pendéncias do Fisconforme
-- parametros esperados: cnpj, periodo_inicio, periodo_fim
-- observacao: consulta individual e lote
-- status: query canônica promovida a partir de referência do próprio repositório
-- regra: selecionar apenas colunas necessárias e preservar chaves físicas

/* :cnpj :periodo_inicio :periodo_fim */
WITH PendenciasRankeadas AS (
    SELECT
        REGEXP_REPLACE(dp.cpf_cnpj, '[^0-9]', '') AS cnpj,
        dp.id AS id_pendencia,
        dn.id_notificacao,
        dp.malhas_id,
        m.titulo AS titulo_malha,
        dp.periodo,
        CASE dp.status
            WHEN 0  THEN '0 - pendente'
            WHEN 1  THEN '1 - contestado'
            WHEN 2  THEN '2 - resolvido'
            WHEN 3  THEN '3 - acao fiscal'
            WHEN 4  THEN '4 - pendente indeferido'
            WHEN 5  THEN '5 - deferido'
            WHEN 6  THEN '6 - notificado'
            WHEN 7  THEN '7 - deferido automaticamente'
            WHEN 8  THEN '8 - aguardando autorizacao'
            WHEN 9  THEN '9 - cancelado'
            WHEN 11 THEN '11 - inapta - 5 anos'
            WHEN 12 THEN '12 - pre-fiscalizacao'
            ELSE TO_CHAR(dp.status)
        END AS status_pendencia,
        dn.tp_status AS status_notificacao,
        NVL(dn.dt_ciencia, dp.data_ciencia) AS data_ciencia_consolidada,
        ROW_NUMBER() OVER (
            PARTITION BY dp.id
            ORDER BY NVL(dn.dt_ciencia, dp.data_ciencia) DESC NULLS LAST
        ) AS rn
    FROM app_pendencia.pendencias dp
    LEFT JOIN app_pendencia.malhas m
        ON dp.malhas_id = m.id
    LEFT JOIN bi.fato_det_notificacao dn
        ON dp.id = dn.id_fisconforme
    WHERE REGEXP_REPLACE(dp.cpf_cnpj, '[^0-9]', '') = REGEXP_REPLACE(TRIM(:cnpj), '[^0-9]', '')
      AND dp.periodo BETWEEN REPLACE(:periodo_inicio, '-', '')
                                AND REPLACE(:periodo_fim, '-', '')
)
SELECT
    cnpj,
    id_pendencia,
    id_notificacao,
    malhas_id,
    titulo_malha,
    periodo,
    status_pendencia,
    status_notificacao,
    data_ciencia_consolidada
FROM PendenciasRankeadas
WHERE rn = 1;
