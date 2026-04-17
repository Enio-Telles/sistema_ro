-- CPF_contador.sql
-- Extraído de dossie_contribuinte.xml - Histórico de Contadores
-- Parâmetro: :CO_CAD_ICMS (Inscrição Estadual)

SELECT
    CASE
        WHEN b.fim_ref IS NULL AND b.co_cnpj_cpf_contador = '   -   ' THEN 'Atual - sem contador indicado'
        WHEN b.fim_ref IS NULL AND b.co_cnpj_cpf_contador != '   -   ' THEN 'Atual'
        WHEN b.fim_ref IS NOT NULL AND b.co_cnpj_cpf_contador = '   -   ' THEN 'Anterior - Período sem indicação'
        ELSE 'Anterior'
    END SITUACAO,
    b.co_cnpj_cpf_contador CNPJ_CPF_CONTADOR,
    p.no_razao_social NOME_CONTADOR,
    l.no_municipio MUNICIPIO,
    l.co_uf UF,
    b.ini_ref DATA_INICIO,
    b.fim_ref DATA_FIM
FROM (
    SELECT
        it_nu_inscricao_estadual ie,
        cnpj,
        CASE
            WHEN substr(gr_ident_contador, 2) IS NULL THEN '   -   '
            ELSE substr(gr_ident_contador, 2)
        END co_cnpj_cpf_contador,
        to_date(it_da_referencia, 'yyyymmdd') ini_ref,
        CASE
            WHEN lead(it_da_referencia) over(order by it_nu_fac) IS NULL THEN NULL
            ELSE to_date(lead(it_da_referencia) over(order by it_nu_fac), 'yyyymmdd')
        END fim_ref
    FROM (
        SELECT
            c.it_nu_inscricao_estadual,
            substr(c.gr_identificacao, 2) cnpj,
            c.it_nu_fac,
            c.it_da_referencia,
            c.gr_ident_contador,
            CASE
                WHEN row_number() over(order by c.it_nu_fac) = 1 THEN 1
                WHEN c.gr_ident_contador != lag(c.gr_ident_contador) over(order by c.it_nu_fac) THEN 1
                ELSE 0
            END usar
        FROM sitafe.sitafe_historico_contribuinte c
        WHERE c.it_nu_inscricao_estadual = :CO_CAD_ICMS
        ORDER BY c.it_nu_inscricao_estadual, c.it_nu_fac
    )
    WHERE usar = 1
    ORDER BY
        CASE
            WHEN lead(it_da_referencia) over(order by it_nu_fac) IS NULL THEN '99999999'
            ELSE lead(it_da_referencia) over(order by it_nu_fac)
        END DESC
) b
LEFT JOIN bi.dm_pessoa p ON b.co_cnpj_cpf_contador = p.co_cnpj_cpf
LEFT JOIN bi.dm_localidade l ON p.co_municipio = l.co_municipio
