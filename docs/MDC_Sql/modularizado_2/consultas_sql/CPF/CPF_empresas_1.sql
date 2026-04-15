/*
    CONSULTA INTEGRADA: DADOS CADASTRAIS DE EMPRESAS VINCULADAS A UM CPF
    --------------------------------------------------------------------
    Objetivo: Dado um CPF (:CPF), localiza todas as empresas (CNPJs) onde 
    ele figura como sócio e retorna os dados cadastrais detalhados e débitos.
*/

SELECT
    t.co_cnpj_cpf                                           AS CNPJ,
    t.co_cad_icms                                           AS IE,
    t.no_razao_social                                       AS NOME,
    t.DESC_ENDERECO || ' ' || t.BAIRRO                      AS ENDERECO,
    localid.no_municipio                                    AS MUNICIPIO,
    localid.co_uf                                           AS UF,
    t.co_regime_pagto || ' - ' || rp.no_regime_pagamento    AS REGIME_PAGAMENTO,
    t.in_situacao || ' - ' || s.desc_situacao               AS SITUACAO_IE,
    t.da_inicio_atividade                                   AS DATA_INICIO_ATIVIDADE,
    to_date(us.data_ult_sit, 'YYYYMMDD')                    AS DATA_ULTIMA_SITUACAO,
    -- Cálculo do tempo de atividade (Query 1)
    to_char(trunc(months_between(
        CASE WHEN t.in_situacao = '001' THEN SYSDATE
             ELSE to_date(us.data_ult_sit, 'YYYYMMDD') 
        END,
        t.da_inicio_atividade), 2)) || ' meses'             AS PERIODO_ATIVIDADE,
    -- Cálculo de Inadimplência (Vindo da Query 2)
    lpad(
        TRIM(to_char(
            NVL(vencido.total_divida, 0), 
            '999G999G999G990D00'
        )),
        length(NVL(vencido.total_divida, 0)) + 6
    )                                                       AS INADIMPLENCIA_TOTAL
FROM
    bi.dm_pessoa t
    -- 1. JOIN para filtrar apenas empresas onde o CPF informado é sócio (Lógica da Query 2)
    INNER JOIN (
        SELECT DISTINCT substr(h.gr_identificacao, 2) AS cnpj_empresa
        FROM sitafe.sitafe_historico_socio soc
        INNER JOIN sitafe.sitafe_historico_contribuinte h ON soc.it_nu_fac = h.it_nu_fac
        WHERE substr(soc.gr_identificacao, 2) = :CPF  -- PARÂMETRO DE ENTRADA (CPF DO SÓCIO)
    ) socios ON t.co_cnpj_cpf = socios.cnpj_empresa
    
    -- 2. JOINS de Metadados (Lógica da Query 1)
    LEFT JOIN bi.dm_localidade localid ON t.co_municipio = localid.co_municipio
    LEFT JOIN bi.dm_regime_pagto_descricao rp ON t.co_regime_pagto = rp.co_regime_pagamento
    LEFT JOIN (
        SELECT
            CO_SITUACAO_CONTRIBUINTE CO_SITUACAO,
            NO_SITUACAO_CONTRIBUINTE DESC_SITUACAO
        FROM BI.DM_SITUACAO_CONTRIBUINTE
    ) s ON t.in_situacao = s.co_situacao
    LEFT JOIN (
        SELECT
            MAX(u.it_da_transacao) data_ult_sit,
            u.it_nu_inscricao_estadual
        FROM
            sitafe.sitafe_historico_gr_situacao t
            LEFT JOIN sitafe.sitafe_historico_situacao u ON t.tuk = u.tuk
        WHERE
            t.it_co_situacao_contribuinte NOT IN ('030', '150', '005')
            AND u.it_co_usuario NOT IN ('INTERNET', 'P30015AC   ')
        GROUP BY u.it_nu_inscricao_estadual
    ) us ON t.co_cad_icms = us.it_nu_inscricao_estadual
    
    -- 3. JOIN de Inadimplência (Lógica da Query 2)
    LEFT JOIN (
        SELECT
            v.co_cnpj_cpf,
            SUM(v.va_principal + v.va_multa + v.va_juros + v.va_acrescimo) AS total_divida
        FROM
            bi.fato_lanc_arrec_sum v
        WHERE
            v.vencido = 3
            AND v.id_situacao = '01'
        GROUP BY
            v.co_cnpj_cpf
    ) vencido ON t.co_cnpj_cpf = vencido.co_cnpj_cpf;