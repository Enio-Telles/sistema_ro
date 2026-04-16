-- Objetivo: endereços observados em documentos fiscais de entrada
-- Binds esperados: :CO_CNPJ_CPF

SELECT
    t.co_destinatario AS co_cnpj_cpf,
    'NFE' AS origem_endereco,
    EXTRACT(YEAR FROM t.dhemi) AS ano,
    LPAD(EXTRACT(MONTH FROM t.dhemi), 2, '0') AS mes,
    UPPER(t.xlgr_dest) AS logradouro,
    UPPER(t.nro_dest) AS numero,
    UPPER(t.xcpl_dest) AS complemento,
    UPPER(t.xbairro_dest) AS bairro,
    UPPER(t.fone_dest) AS fone,
    UPPER(t.cep_dest) AS cep,
    UPPER(t.xmun_dest) AS municipio,
    UPPER(t.co_uf_dest) AS uf,
    COUNT(DISTINCT t.chave_acesso) AS qtd_notas
FROM bi.fato_nfe_detalhe t
WHERE t.co_destinatario = :CO_CNPJ_CPF
GROUP BY
    t.co_destinatario,
    EXTRACT(YEAR FROM t.dhemi),
    LPAD(EXTRACT(MONTH FROM t.dhemi), 2, '0'),
    UPPER(t.xlgr_dest),
    UPPER(t.nro_dest),
    UPPER(t.xcpl_dest),
    UPPER(t.xbairro_dest),
    UPPER(t.fone_dest),
    UPPER(t.cep_dest),
    UPPER(t.xmun_dest),
    UPPER(t.co_uf_dest)
ORDER BY ano DESC, mes DESC, qtd_notas DESC;
