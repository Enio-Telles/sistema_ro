-- Objetivo: histórico de situações cadastrais válidas
-- Binds esperados: :CO_CAD_ICMS

SELECT
    u.it_nu_inscricao_estadual AS co_cad_icms,
    TO_DATE(u.it_da_transacao, 'YYYYMMDD') AS data_transacao,
    g.it_co_situacao_contribuinte AS co_situacao,
    c.it_no_situacao_contribuinte AS ds_situacao,
    u.it_nu_fac,
    u.it_co_usuario,
    u.tuk
FROM sitafe.sitafe_historico_gr_situacao g
LEFT JOIN sitafe.sitafe_historico_situacao u
       ON g.tuk = u.tuk
LEFT JOIN sitafe.sitafe_tabelas_cadastro c
       ON g.it_co_situacao_contribuinte = c.it_co_situacao_contribuinte
WHERE u.it_nu_inscricao_estadual = :CO_CAD_ICMS
  AND g.it_co_situacao_contribuinte NOT IN ('030','150','005')
  AND u.it_co_usuario NOT IN ('INTERNET', 'P30015AC   ')
ORDER BY
    u.it_in_ultima_situacao DESC,
    u.it_da_atualizacao_situacao DESC,
    u.it_ho_transacao DESC,
    g.it_da_situacao_contribuinte DESC;
