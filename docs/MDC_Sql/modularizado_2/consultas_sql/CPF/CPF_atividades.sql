-- CPF_atividades.sql
-- Extraído de dossie_contribuinte.xml - Atividades (CNAE)
-- Parâmetro: :CO_CNPJ_CPF

SELECT
    base.tipo             TIPO_ATIVIDADE,
    base.co_cnae          CODIGO_CNAE,
    cnae.no_cnae          DESCRICAO_CNAE
FROM
    (
        SELECT
            'SECUNDARIA' tipo,
            t.co_cnae_secundaria co_cnae
        FROM
            bi.dm_cnae_secundaria t
        WHERE
            t.co_cnpj_cpf = :CO_CNPJ_CPF
        UNION
        SELECT
            'PRINCIPAL' tipo,
            t.co_cnae co_cnae
        FROM
            bi.dm_pessoa t
        WHERE
            t.co_cnpj_cpf = :CO_CNPJ_CPF
    ) base
    LEFT JOIN bi.dm_cnae cnae ON base.co_cnae = cnae.co_cnae
ORDER BY
    base.tipo ASC,
    base.co_cnae
