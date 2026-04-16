-- Objetivo: confronto entre cartão (DIMP) e saídas documentais por período
-- Binds esperados: :CO_CNPJ_CPF

WITH cartao AS (
    SELECT
        cnpj_cpf AS co_cnpj_cpf,
        EXTRACT(YEAR FROM dt_op) AS ano,
        TO_CHAR(dt_op, 'YYYY-MM') AS periodo_ym,
        COUNT(*) AS qtd_operacoes_cartao,
        SUM(valor) AS valor_cartao
    FROM bi.mpg_f_detalhe_operacao
    WHERE cnpj_cpf = :CO_CNPJ_CPF
    GROUP BY
        cnpj_cpf,
        EXTRACT(YEAR FROM dt_op),
        TO_CHAR(dt_op, 'YYYY-MM')
),
saidas AS (
    SELECT
        co_emitente AS co_cnpj_cpf,
        EXTRACT(YEAR FROM da_referencia) AS ano,
        TO_CHAR(da_referencia, 'YYYY-MM') AS periodo_ym,
        SUM(prod_vprod + prod_vfrete + prod_vseg + prod_voutro - prod_vdesc) AS valor_nfe_nfce
    FROM bi.fato_nfe_nfce_sumarizada
    WHERE co_emitente = :CO_CNPJ_CPF
      AND co_tp_nf = 1
    GROUP BY
        co_emitente,
        EXTRACT(YEAR FROM da_referencia),
        TO_CHAR(da_referencia, 'YYYY-MM')
)
SELECT
    NVL(c.co_cnpj_cpf, s.co_cnpj_cpf) AS co_cnpj_cpf,
    NVL(c.ano, s.ano) AS ano,
    NVL(c.periodo_ym, s.periodo_ym) AS periodo_ym,
    c.qtd_operacoes_cartao,
    c.valor_cartao,
    s.valor_nfe_nfce,
    NVL(c.valor_cartao, 0) - NVL(s.valor_nfe_nfce, 0) AS excesso_valor
FROM cartao c
FULL OUTER JOIN saidas s
        ON c.co_cnpj_cpf = s.co_cnpj_cpf
       AND c.periodo_ym = s.periodo_ym
ORDER BY ano DESC, periodo_ym DESC;
