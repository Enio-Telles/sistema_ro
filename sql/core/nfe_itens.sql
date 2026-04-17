-- nfe_itens.sql
-- grupo: core
-- dominio: DF-e NFe
-- objetivo: itens de NFe
-- parametros esperados: cnpj, periodo_inicio, periodo_fim
-- observacao: principal trilha de saídas documentadas
-- status: query canônica promovida a partir do template curado
-- regra: selecionar apenas colunas necessárias e preservar chaves físicas
SELECT
    i.chave_acesso,
    i.n_item AS num_item,
    i.cprod AS codigo_produto,
    i.xprod AS descricao_produto,
    i.cean AS cod_barra,
    i.ncm,
    i.cest,
    i.cfop,
    i.ucom AS unid,
    i.qcom AS qtd,
    i.vprod AS vl_item,
    n.dhemi,
    n.dhsaient,
    n.cnpj_emit,
    n.cnpj_dest,
    n.infprot_cstat,
    n.finnfe
FROM nfe_itens i
JOIN nfe_cabecalho n
  ON n.chave_acesso = i.chave_acesso
WHERE regexp_replace(COALESCE(n.cnpj_emit, n.cnpj_dest), '[^0-9]', '') = :cnpj
  AND COALESCE(n.dhemi, n.dhsaient) BETWEEN :periodo_inicio AND :periodo_fim;
