-- Objetivo: exemplo de timeline unificada para posterior enriquecimento em Polars
-- Binds esperados: :CO_CNPJ_CPF, :CO_CAD_ICMS

SELECT
    :CO_CNPJ_CPF AS co_cnpj_cpf,
    'SITUACAO_CADASTRAL' AS tipo_evento,
    TO_DATE(u.it_da_transacao, 'YYYYMMDD') AS data_evento,
    g.it_co_situacao_contribuinte AS chave_evento,
    c.it_no_situacao_contribuinte AS descricao_evento,
    CAST(NULL AS NUMBER) AS valor_evento
FROM sitafe.sitafe_historico_gr_situacao g
LEFT JOIN sitafe.sitafe_historico_situacao u
       ON g.tuk = u.tuk
LEFT JOIN sitafe.sitafe_tabelas_cadastro c
       ON g.it_co_situacao_contribuinte = c.it_co_situacao_contribuinte
WHERE u.it_nu_inscricao_estadual = :CO_CAD_ICMS
  AND g.it_co_situacao_contribuinte NOT IN ('030','150','005')
  AND u.it_co_usuario NOT IN ('INTERNET', 'P30015AC   ')

UNION ALL

SELECT
    :CO_CNPJ_CPF AS co_cnpj_cpf,
    'AUTO_INFRACAO' AS tipo_evento,
    t.da_lavratura_auto AS data_evento,
    t.nu_termo_infracao AS chave_evento,
    t.nu_acao_fiscal AS descricao_evento,
    (t.va_tributo + t.va_multa + t.va_juros) AS valor_evento
FROM bi.fato_acao_fiscal_ainf t
WHERE t.nu_acao_fiscal IN (
    SELECT t2.nu_acao_fiscal
    FROM bi.dm_acao_fiscal t2
    WHERE t2.co_cnpj_cpf = :CO_CNPJ_CPF
)

UNION ALL

SELECT
    :CO_CNPJ_CPF AS co_cnpj_cpf,
    'NOTIFICACAO_DET' AS tipo_evento,
    t.dt_envio AS data_evento,
    t.id_notificacao AS chave_evento,
    UPPER(t.tx_descricao) AS descricao_evento,
    CAST(NULL AS NUMBER) AS valor_evento
FROM bi.fato_det_notificacao t
WHERE t.id_fisconforme IS NULL
  AND t.co_cnpj_notif = :CO_CNPJ_CPF
  AND t.tp_status NOT IN ('1 - PROCESSADA', '5 - CANCELADA');
