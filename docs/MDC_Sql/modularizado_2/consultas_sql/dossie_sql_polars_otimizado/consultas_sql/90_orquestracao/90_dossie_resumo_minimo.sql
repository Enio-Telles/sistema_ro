-- Objetivo: exemplo de resumo mínimo para consumo rápido
-- Observação: a consolidação final recomendada deve ocorrer em Polars.
-- Binds esperados: :CO_CNPJ_CPF

WITH cadastro AS (
    SELECT
        p.co_cnpj_cpf,
        p.co_cad_icms,
        p.no_razao_social,
        p.in_situacao,
        p.co_regime_pagto,
        p.da_inicio_atividade
    FROM bi.dm_pessoa p
    WHERE p.co_cnpj_cpf = :CO_CNPJ_CPF
),
vaf AS (
    SELECT
        :CO_CNPJ_CPF AS co_cnpj_cpf,
        SUM(
            CASE
                WHEN t.co_emitente = :CO_CNPJ_CPF     AND t.co_tp_nf = 1 THEN (t.prod_vprod + t.prod_vfrete + t.prod_vseg + t.prod_voutro - t.prod_vdesc)
                WHEN t.co_destinatario = :CO_CNPJ_CPF AND t.co_tp_nf = 0 THEN (t.prod_vprod + t.prod_vfrete + t.prod_vseg + t.prod_voutro - t.prod_vdesc)
                ELSE 0
            END
        ) AS saida_total,
        SUM(
            CASE
                WHEN t.co_destinatario = :CO_CNPJ_CPF AND t.co_tp_nf = 1 THEN (t.prod_vprod + t.prod_vfrete + t.prod_vseg + t.prod_voutro - t.prod_vdesc)
                WHEN t.co_emitente     = :CO_CNPJ_CPF AND t.co_tp_nf = 0 THEN (t.prod_vprod + t.prod_vfrete + t.prod_vseg + t.prod_voutro - t.prod_vdesc)
                ELSE 0
            END
        ) AS entrada_total
    FROM bi.fato_nfe_nfce_sumarizada t
),
conta AS (
    SELECT
        t.id_cpf_cnpj AS co_cnpj_cpf,
        SUM(
            CASE
                WHEN t.va_pago IS NULL THEN (t.va_principal + t.va_multa + t.va_juros + t.va_acrescimo)
                ELSE t.va_pago
            END
        ) AS saldo_total
    FROM bi.fato_lanc_arrec t
    WHERE t.id_cpf_cnpj = :CO_CNPJ_CPF
    GROUP BY t.id_cpf_cnpj
),
acoes AS (
    SELECT
        :CO_CNPJ_CPF AS co_cnpj_cpf,
        COUNT(DISTINCT nu_acao_fiscal) AS qtd_acoes
    FROM (
        SELECT t.nu_acao_fiscal
        FROM bi.dm_acao_fiscal t
        WHERE t.co_cnpj_cpf = :CO_CNPJ_CPF
        UNION
        SELECT SUBSTR(dft.it_nu_diligencia,1,5) || '7' || SUBSTR(dft.it_nu_diligencia,7)
        FROM sitafe.sitafe_diligencia_fiscal_taref dft
        WHERE dft.it_nu_identificacao = :CO_CNPJ_CPF
    )
)
SELECT
    c.co_cnpj_cpf,
    c.co_cad_icms,
    c.no_razao_social,
    c.in_situacao,
    c.co_regime_pagto,
    c.da_inicio_atividade,
    v.entrada_total,
    v.saida_total,
    cc.saldo_total,
    a.qtd_acoes
FROM cadastro c
LEFT JOIN vaf v
       ON c.co_cnpj_cpf = v.co_cnpj_cpf
LEFT JOIN conta cc
       ON c.co_cnpj_cpf = cc.co_cnpj_cpf
LEFT JOIN acoes a
       ON c.co_cnpj_cpf = a.co_cnpj_cpf;
