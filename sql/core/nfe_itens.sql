-- nfe_itens.sql
-- grupo: core
-- dominio: DF-e NFe
-- objetivo: itens de NFe
-- parametros esperados: cnpj, periodo_inicio, periodo_fim
-- observacao: principal trilha de saídas documentadas
-- status: template curado para implementação no novo projeto
-- regra: selecionar apenas colunas necessárias e preservar chaves físicas

-- Consulta canônica de itens de NFe
--
-- Este script extrai os itens das notas fiscais eletrônicas (NFe) com
-- as colunas essenciais para o pipeline de bronze. Ele se limita a
-- selecionar os campos relevantes sem realizar agregações ou cálculos
-- complexos, seguindo a regra de que a lógica de transformação deve
-- residir no pipeline de processamento.

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
