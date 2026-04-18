-- =============================================================
-- ETAPA 1: CRIAÇÃO DA TABELA dbo.cfop (com dados de outro DB)
-- =============================================================
-- 1.1 Habilita a extensão dblink (se ainda não estiver habilitada)
CREATE EXTENSION IF NOT EXISTS dblink;

-- 1.2 Recria a tabela dbo.cfop buscando os dados do banco de dados 'postgres'
-- Dropa a tabela dbo.cfop se ela já existir
DROP TABLE IF EXISTS dbo.cfop;

-- Cria a tabela dbo.cfop usando dblink para conectar ao banco 'postgres'
-- A consulta e os tipos de dados foram ajustados para corresponder à estrutura da tabela de origem.
CREATE TABLE dbo.cfop AS
SELECT *
FROM dblink('dbname=postgres user=postgres password=sefin', -- Credenciais
            'SELECT
                id,
                co_cfop,
                descricao AS ds_cfop,
                codigo_tributacao,
                finalidade,
                (CASE WHEN lower(excluir_estorno::text) IN (''true'', ''t'', ''1'') THEN TRUE ELSE FALSE END) AS excluir_estorno,
                (CASE WHEN lower(excluir_estoque::text) IN (''true'', ''t'', ''1'') THEN TRUE ELSE FALSE END) AS excluir_estoque,
                (CASE WHEN lower(saida_faturamento::text) IN (''true'', ''t'', ''1'') THEN TRUE ELSE FALSE END) AS saida_faturamento,
                (CASE WHEN lower(ciap::text) IN (''true'', ''t'', ''1'') THEN TRUE ELSE FALSE END) AS ciap,
                (CASE WHEN lower(fat_simples::text) IN (''true'', ''t'', ''1'') THEN TRUE ELSE FALSE END) AS fat_simples,
                (CASE WHEN lower(dev_simples::text) IN (''true'', ''t'', ''1'') THEN TRUE ELSE FALSE END) AS dev_simples,
                ativ_simples
            FROM public.cfop')
AS t(
    id integer,
    co_cfop character varying(4),
    ds_cfop character varying(500),
    codigo_tributacao integer,
    finalidade integer,
    excluir_estorno boolean,
    excluir_estoque boolean,
    saida_faturamento boolean,
    ciap boolean,
    fat_simples boolean,
    dev_simples boolean,
    ativ_simples integer
);

-- Adiciona uma chave primária
ALTER TABLE dbo.cfop ADD PRIMARY KEY (co_cfop);

-- =============================================================
-- ETAPA 2: CRIAÇÃO DA TABELA dbo.mov_estoque_completa_otimizada (filtrada por data)
-- =============================================================
-- Dropa a tabela materializada se ela já existir
DROP TABLE IF EXISTS dbo.mov_estoque_completa_otimizada;

-- Cria a nova tabela materializada
CREATE TABLE dbo.mov_estoque_completa_otimizada AS
WITH RECURSIVE
-- CTE para buscar o intervalo de datas da designação fiscal
DatasFiscais AS (
    SELECT data_inicio::date, data_final::date
    FROM dbo.designacao_fiscal
    LIMIT 1 -- Garante apenas uma linha, conforme mencionado
),
C170_entrada AS (
    SELECT DISTINCT
        '1 - ENTRADA'::TEXT AS entrada_saida,
        c170.chave_acesso,
        c170.num_doc AS nnf,
        CAST(NULL AS BOOLEAN) AS excluir_omissao,
        CAST(NULL AS INTEGER) AS status,
        CAST(NULL AS INTEGER) AS finnfe,
        c170.cfop AS cfop_c170,
        nf.cfop AS cfop_nf,
        GREATEST(c170.dt_e_s, c170.dt_doc) AS data_evento,
        c170.num_item,
        p.produto_id,
        p.codigo_barra,
        c170.codigo_produto,
        c170.descricao_produto,
        c170.chave_produto,
        p.codigo_tributacao,
        c170.unid,
        c170.qtd,
        c170.vl_item,
        c170.vl_desc,
        CAST(NULL AS NUMERIC) AS vdesc,
        CAST(NULL AS NUMERIC) AS voutro,
        (COALESCE(c170.vl_item, 0) - COALESCE(c170.vl_desc, 0)) AS preco_item,
        CAST(NULL AS INTEGER) AS mot_inv,
        -- Colunas C170
        c170.aliq_icms AS aliq_icms_c170,
        c170.aliq_nf AS aliq_nf_c170,
        c170.vl_icms AS vl_icms_c170,
        c170.vl_bc_icms_st AS vl_bc_icms_st_c170,
        c170.vl_icms_st AS vl_icms_st_c170,
        -- Colunas NF (nulas)
        CAST(NULL AS NUMERIC) AS vbc_nf,
        CAST(NULL AS NUMERIC) AS picms_nf,
        CAST(NULL AS NUMERIC) AS vicms_nf,
        CAST(NULL AS NUMERIC) AS vb_st_nf,
        CAST(NULL AS NUMERIC) AS picms_st_nf,
        CAST(NULL AS NUMERIC) AS vicms_st_nf
    FROM dbo.efd_regc170 AS c170
    INNER JOIN dbo.produto p ON p.chave_produto = c170.chave_produto
    LEFT JOIN dbo.nf_detalhe nf ON nf.chave_acesso = c170.chave_acesso
        AND nf.nitem = c170.num_item AND nf.tpnf = '0' AND nf.status = 0
    CROSS JOIN DatasFiscais df -- Junta com as datas
    WHERE c170.ind_oper = 0
      AND GREATEST(c170.dt_e_s, c170.dt_doc)::date BETWEEN df.data_inicio AND df.data_final -- Filtro de data
),
NF_saida AS (
    SELECT DISTINCT
        '2 - SAIDA'::TEXT AS entrada_saida,
        nf.chave_acesso,
        nf.nnf,
        nfr.excluir_omissao,
        nf.status,
        NULLIF(nf.finnfe, '')::INTEGER AS finnfe,
        CAST(NULL AS VARCHAR(4)) AS cfop_c170,
        nf.cfop AS cfop_nf,
        nf.demi AS data_evento,
        nf.nitem AS num_item,
        p.produto_id,
        nf.cean AS codigo_barra,
        nf.cprod AS codigo_produto,
        nf.xprod AS descricao_produto,
        nf.chave_produto,
        p.codigo_tributacao,
        nf.ucom AS unid,
        nf.qcom * -1 AS qtd,
        nf.vprod AS vl_item,
        CAST(NULL AS NUMERIC) AS vl_desc,
        nf.vdesc,
        nf.voutro,
        (COALESCE(nf.vprod, 0) - COALESCE(nf.vdesc, 0) + COALESCE(nf.voutro, 0)) AS preco_item,
        CAST(NULL AS INTEGER) AS mot_inv,
        -- Colunas C170 (nulas)
        CAST(NULL AS NUMERIC) AS aliq_icms_c170,
        CAST(NULL AS NUMERIC) AS aliq_nf_c170,
        CAST(NULL AS NUMERIC) AS vl_icms_c170,
        CAST(NULL AS NUMERIC) AS vl_bc_icms_st_c170,
        CAST(NULL AS NUMERIC) AS vl_icms_st_c170,
        -- Colunas NF
        nf.vbc AS vbc_nf,
        nf.picms AS picms_nf,
        nf.vicms AS vicms_nf,
        nf.vb_st AS vb_st_nf,
        nf.picms_st AS picms_st_nf,
        nf.vicms_st AS vicms_st_nf
    FROM dbo.nf_detalhe AS nf
    INNER JOIN dbo.nf_resumo nfr ON nf.nf_resumo_id = nfr.id
    INNER JOIN dbo.produto p ON p.chave_produto = nf.chave_produto
    CROSS JOIN DatasFiscais df -- Junta com as datas
    WHERE nf.tpnf = '1'
      AND nf.status = 0
      AND (nfr.excluir_omissao = FALSE OR nfr.excluir_omissao IS NULL)
      AND nf.demi::date BETWEEN df.data_inicio AND df.data_final -- Filtro de data
),
inventario_entrada AS (
    SELECT DISTINCT
        '0 - ESTOQUE INICIAL'::TEXT AS entrada_saida,
        CAST(NULL AS VARCHAR(44)) AS chave_acesso,
        CAST(NULL AS VARCHAR(9)) AS nnf,
        CAST(NULL AS BOOLEAN) AS excluir_omissao,
        CAST(NULL AS INTEGER) AS status,
        CAST(NULL AS INTEGER) AS finnfe,
        CAST(NULL AS VARCHAR(4)) AS cfop_c170,
        CAST(NULL AS VARCHAR(4)) AS cfop_nf,
        df.data_inicio::timestamp AS data_evento, -- Data do evento é o início do período fiscal
        CAST(NULL AS INTEGER) AS num_item,
        p.produto_id,
        p.codigo_barra,
        h010.codigo_produto,
        h010.descricao_produto,
        h010.chave_produto,
        p.codigo_tributacao,
        h010.unid,
        h010.qtd,
        h010.vl_item,
        CAST(NULL AS NUMERIC) AS vl_desc,
        CAST(NULL AS NUMERIC) AS vdesc,
        CAST(NULL AS NUMERIC) AS voutro,
        h010.vl_item AS preco_item,
        h005.mot_inv::INTEGER AS mot_inv,
        -- Colunas C170 (nulas)
        CAST(NULL AS NUMERIC) AS aliq_icms_c170,
        CAST(NULL AS NUMERIC) AS aliq_nf_c170,
        CAST(NULL AS NUMERIC) AS vl_icms_c170,
        CAST(NULL AS NUMERIC) AS vl_bc_icms_st_c170,
        CAST(NULL AS NUMERIC) AS vl_icms_st_c170,
        -- Colunas NF (nulas)
        CAST(NULL AS NUMERIC) AS vbc_nf,
        CAST(NULL AS NUMERIC) AS picms_nf,
        CAST(NULL AS NUMERIC) AS vicms_nf,
        CAST(NULL AS NUMERIC) AS vb_st_nf,
        CAST(NULL AS NUMERIC) AS picms_st_nf,
        CAST(NULL AS NUMERIC) AS vicms_st_nf
    FROM dbo.efd_regh005 h005
    LEFT JOIN dbo.efd_regh010 h010 ON h005.id = h010.regh005_id
    INNER JOIN dbo.produto p ON p.chave_produto = h010.chave_produto
    CROSS JOIN DatasFiscais df -- Junta com as datas
    -- Pega o inventário cujo dia seguinte é o início do período fiscal
    WHERE (h005.dt_inv + INTERVAL '1 day')::date = df.data_inicio
),
inventario_final AS (
    SELECT DISTINCT
        '3 - ESTOQUE FINAL'::TEXT AS entrada_saida,
        CAST(NULL AS VARCHAR(44)) AS chave_acesso,
        CAST(NULL AS VARCHAR(9)) AS nnf,
        CAST(NULL AS BOOLEAN) AS excluir_omissao,
        CAST(NULL AS INTEGER) AS status,
        CAST(NULL AS INTEGER) AS finnfe,
        CAST(NULL AS VARCHAR(4)) AS cfop_c170,
        CAST(NULL AS VARCHAR(4)) AS cfop_nf,
        df.data_final::timestamp AS data_evento, -- Data do evento é o fim do período fiscal
        CAST(NULL AS INTEGER) AS num_item,
        p.produto_id,
        p.codigo_barra,
        h010.codigo_produto,
        h010.descricao_produto,
        h010.chave_produto,
        p.codigo_tributacao,
        h010.unid,
        h010.qtd,
        h010.vl_item,
        CAST(NULL AS NUMERIC) AS vl_desc,
        CAST(NULL AS NUMERIC) AS vdesc,
        CAST(NULL AS NUMERIC) AS voutro,
        h010.vl_item AS preco_item,
        h005.mot_inv::INTEGER AS mot_inv,
        -- Colunas C170 (nulas)
        CAST(NULL AS NUMERIC) AS aliq_icms_c170,
        CAST(NULL AS NUMERIC) AS aliq_nf_c170,
        CAST(NULL AS NUMERIC) AS vl_icms_c170,
        CAST(NULL AS NUMERIC) AS vl_bc_icms_st_c170,
        CAST(NULL AS NUMERIC) AS vl_icms_st_c170,
        -- Colunas NF (nulas)
        CAST(NULL AS NUMERIC) AS vbc_nf,
        CAST(NULL AS NUMERIC) AS picms_nf,
        CAST(NULL AS NUMERIC) AS vicms_nf,
        CAST(NULL AS NUMERIC) AS vb_st_nf,
        CAST(NULL AS NUMERIC) AS picms_st_nf,
        CAST(NULL AS NUMERIC) AS vicms_st_nf
    FROM dbo.efd_regh005 h005
    LEFT JOIN dbo.efd_regh010 h010 ON h005.id = h010.regh005_id
    INNER JOIN dbo.produto p ON p.chave_produto = h010.chave_produto
    CROSS JOIN DatasFiscais df -- Junta com as datas
    -- Pega o inventário cuja data é o fim do período fiscal
    WHERE h005.dt_inv::date = df.data_final
),
cfops_devolucao AS (
    SELECT co_cfop FROM dbo.cfop WHERE dev_simples = TRUE
),
cfops_excluir AS (
    SELECT co_cfop FROM dbo.cfop WHERE excluir_estoque = TRUE
),
-- Filtra os anos ativos com base nas datas fiscais
produtos_e_anos_ativos AS (
    SELECT DISTINCT produto_id, EXTRACT(YEAR FROM data_evento)::INTEGER AS ano
    FROM C170_entrada
    UNION
    SELECT DISTINCT produto_id, EXTRACT(YEAR FROM data_evento)::INTEGER AS ano
    FROM NF_saida
    UNION
    SELECT DISTINCT produto_id, EXTRACT(YEAR FROM data_evento)::INTEGER AS ano
    FROM inventario_entrada
),
-- União preliminar com dados já filtrados
uniao_preliminar AS (
    SELECT * FROM inventario_entrada
    UNION ALL SELECT * FROM C170_entrada
    UNION ALL SELECT * FROM NF_saida
    UNION ALL SELECT * FROM inventario_final
),
-- Lógica de estoque inicial faltante considera os anos ativos DENTRO do período fiscal
produtos_com_estoque_inicial AS (
    SELECT DISTINCT
        produto_id,
        EXTRACT(YEAR FROM data_evento)::INTEGER AS ano
    FROM uniao_preliminar
    WHERE entrada_saida LIKE '0%'
),
-- Lógica de estoque final faltante considera os anos ativos DENTRO do período fiscal
produtos_com_estoque_final AS (
    SELECT DISTINCT
        produto_id,
        EXTRACT(YEAR FROM data_evento)::INTEGER AS ano
    FROM uniao_preliminar
    WHERE entrada_saida LIKE '3%'
),
-- Adiciona estoque inicial zerado para anos/produtos ativos dentro do período que não tiveram registro inicial
estoques_iniciais_faltantes AS (
    SELECT
        '0 - ESTOQUE INICIAL ZERO' AS entrada_saida, CAST(NULL AS VARCHAR(44)) AS chave_acesso, CAST(NULL AS VARCHAR(9)) AS nnf,
        CAST(NULL AS BOOLEAN) AS excluir_omissao, CAST(NULL AS INTEGER) AS status, CAST(NULL AS INTEGER) AS finnfe,
        CAST(NULL AS VARCHAR(4)) AS cfop_c170, CAST(NULL AS VARCHAR(4)) AS cfop_nf,
        -- Data do estoque inicial é o início do ano ou o início do período fiscal, o que for maior
        GREATEST(TO_DATE(pa.ano::TEXT || '-01-01', 'YYYY-MM-DD'), (SELECT data_inicio FROM DatasFiscais)) AS data_evento,
        CAST(NULL AS INTEGER) AS num_item, pa.produto_id, p.codigo_barra, p.codigo_produto, p.descricao_produto,
        p.chave_produto, p.codigo_tributacao, p.unid_inv AS unid,
        CAST(0 AS NUMERIC) AS qtd, CAST(0 AS NUMERIC) AS vl_item,
        CAST(NULL AS NUMERIC) AS vl_desc, CAST(NULL AS NUMERIC) AS vdesc, CAST(NULL AS NUMERIC) AS voutro, CAST(0 AS NUMERIC) AS preco_item,
        CAST(NULL AS INTEGER) AS mot_inv,
        -- Colunas C170 (nulas)
        CAST(NULL AS NUMERIC) AS aliq_icms_c170,
        CAST(NULL AS NUMERIC) AS aliq_nf_c170,
        CAST(NULL AS NUMERIC) AS vl_icms_c170,
        CAST(NULL AS NUMERIC) AS vl_bc_icms_st_c170,
        CAST(NULL AS NUMERIC) AS vl_icms_st_c170,
        -- Colunas NF (nulas)
        CAST(NULL AS NUMERIC) AS vbc_nf,
        CAST(NULL AS NUMERIC) AS picms_nf,
        CAST(NULL AS NUMERIC) AS vicms_nf,
        CAST(NULL AS NUMERIC) AS vb_st_nf,
        CAST(NULL AS NUMERIC) AS picms_st_nf,
        CAST(NULL AS NUMERIC) AS vicms_st_nf
    FROM produtos_e_anos_ativos pa
    JOIN dbo.produto p ON pa.produto_id = p.produto_id
    CROSS JOIN DatasFiscais df
    WHERE pa.ano >= EXTRACT(YEAR FROM df.data_inicio) AND pa.ano <= EXTRACT(YEAR FROM df.data_final)
      AND NOT EXISTS (
        SELECT 1 FROM uniao_preliminar u
        WHERE u.produto_id = pa.produto_id
          AND u.entrada_saida LIKE '0%'
          AND EXTRACT(YEAR FROM u.data_evento) = pa.ano
    )
),
-- Adiciona estoque final zerado para anos/produtos ativos dentro do período que não tiveram registro final
estoques_finais_faltantes AS (
    SELECT
        '3 - ESTOQUE FINAL ZERO' AS entrada_saida, CAST(NULL AS VARCHAR(44)) AS chave_acesso, CAST(NULL AS VARCHAR(9)) AS nnf,
        CAST(NULL AS BOOLEAN) AS excluir_omissao, CAST(NULL AS INTEGER) AS status, CAST(NULL AS INTEGER) AS finnfe,
        CAST(NULL AS VARCHAR(4)) AS cfop_c170, CAST(NULL AS VARCHAR(4)) AS cfop_nf,
         -- Data do estoque final é o fim do ano ou o fim do período fiscal, o que for menor
        LEAST(TO_DATE(pa.ano::TEXT || '-12-31', 'YYYY-MM-DD'), (SELECT data_final FROM DatasFiscais)) AS data_evento,
        CAST(NULL AS INTEGER) AS num_item, pa.produto_id, p.codigo_barra, p.codigo_produto, p.descricao_produto,
        p.chave_produto, p.codigo_tributacao, p.unid_inv AS unid,
        CAST(0 AS NUMERIC) AS qtd, CAST(0 AS NUMERIC) AS vl_item,
        CAST(NULL AS NUMERIC) AS vl_desc, CAST(NULL AS NUMERIC) AS vdesc, CAST(NULL AS NUMERIC) AS voutro, CAST(0 AS NUMERIC) AS preco_item,
        CAST(NULL AS INTEGER) AS mot_inv,
        -- Colunas C170 (nulas)
        CAST(NULL AS NUMERIC) AS aliq_icms_c170,
        CAST(NULL AS NUMERIC) AS aliq_nf_c170,
        CAST(NULL AS NUMERIC) AS vl_icms_c170,
        CAST(NULL AS NUMERIC) AS vl_bc_icms_st_c170,
        CAST(NULL AS NUMERIC) AS vl_icms_st_c170,
        -- Colunas NF (nulas)
        CAST(NULL AS NUMERIC) AS vbc_nf,
        CAST(NULL AS NUMERIC) AS picms_nf,
        CAST(NULL AS NUMERIC) AS vicms_nf,
        CAST(NULL AS NUMERIC) AS vb_st_nf,
        CAST(NULL AS NUMERIC) AS picms_st_nf,
        CAST(NULL AS NUMERIC) AS vicms_st_nf
    FROM produtos_e_anos_ativos pa
    JOIN dbo.produto p ON pa.produto_id = p.produto_id
    CROSS JOIN DatasFiscais df
    WHERE pa.ano >= EXTRACT(YEAR FROM df.data_inicio) AND pa.ano <= EXTRACT(YEAR FROM df.data_final)
      AND NOT EXISTS (
        SELECT 1 FROM uniao_preliminar u
        WHERE u.produto_id = pa.produto_id
          AND u.entrada_saida LIKE '3%'
          AND EXTRACT(YEAR FROM u.data_evento) = pa.ano
    )
),
uniao AS (
    SELECT * FROM uniao_preliminar
    UNION ALL SELECT * FROM estoques_iniciais_faltantes
    UNION ALL SELECT * FROM estoques_finais_faltantes
),
-- O restante da consulta permanece igual
movimentacoes_com_periodo AS (
    SELECT *, SUM(CASE WHEN entrada_saida LIKE '0%' THEN 1 ELSE 0 END) OVER (PARTITION BY produto_id ORDER BY data_evento, entrada_saida, nnf) AS grupo_periodo
    FROM uniao
),
movimentacoes_com_flags_custo AS (
    SELECT mcp.*,
        CASE
            WHEN mcp.entrada_saida = '1 - ENTRADA'
                 AND (mcp.cfop_c170 IN (SELECT co_cfop FROM cfops_devolucao)
                      OR mcp.cfop_nf IN (SELECT co_cfop FROM cfops_devolucao))
            THEN TRUE ELSE FALSE
        END AS eh_devolucao,
        CASE
            WHEN mcp.entrada_saida = '1 - ENTRADA' AND
                 (CASE
                    WHEN mcp.entrada_saida = '1 - ENTRADA'
                         AND (mcp.cfop_c170 IN (SELECT co_cfop FROM cfops_devolucao)
                              OR mcp.cfop_nf IN (SELECT co_cfop FROM cfops_devolucao))
                    THEN TRUE ELSE FALSE
                 END) = FALSE
            THEN TRUE
            ELSE FALSE
        END AS eh_compra_para_preco_medio,
        CASE
            WHEN mcp.entrada_saida = '2 - SAIDA'
                 AND mcp.finnfe <> 4
                 AND (mcp.cfop_nf NOT IN (SELECT co_cfop FROM cfops_devolucao))
            THEN TRUE
            ELSE FALSE
        END AS eh_venda_para_preco_medio,
        CASE
            WHEN COALESCE(mcp.cfop_c170, mcp.cfop_nf) IN (SELECT co_cfop FROM cfops_excluir) THEN 'excluir'
            WHEN COALESCE(mcp.cfop_c170, mcp.cfop_nf) IN (SELECT co_cfop FROM cfops_devolucao) THEN 'devolucao'
            ELSE NULL
        END AS dev_ou_exclusao
    FROM movimentacoes_com_periodo mcp
),
movimentacoes_numeradas AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY produto_id, grupo_periodo ORDER BY data_evento, entrada_saida, nnf) as rn
    FROM movimentacoes_com_flags_custo
),
movimentacoes_base_calculo AS (
    SELECT
        produto_id,
        grupo_periodo,
        entrada_saida,
        CASE
            WHEN dev_ou_exclusao = 'excluir' THEN 0
            WHEN entrada_saida LIKE '3%' THEN qtd * -1 -- Negativar qtd para estoque final
            ELSE qtd
        END AS qtd,
        preco_item,
        eh_devolucao,
        rn
    FROM movimentacoes_numeradas
),
calculo_custo_recursivo AS (
    SELECT
        base.produto_id,
        base.grupo_periodo,
        base.rn,
        base.qtd::NUMERIC AS saldo_apos_operacao,
        base.qtd::NUMERIC AS saldo_bruto,
        COALESCE(base.preco_item, 0)::NUMERIC AS valor_saldo_estoque,
        COALESCE(base.preco_item, 0)::NUMERIC AS valor_saldo_estoque_zeros,
        COALESCE(base.preco_item, 0)::NUMERIC AS valor_saldo_estoque_dev,
        COALESCE(base.preco_item, 0)::NUMERIC AS valor_saldo_estoque_dev_zeros,
        CASE
            WHEN base.qtd > 0 THEN (COALESCE(base.preco_item, 0) / NULLIF(base.qtd, 0))::NUMERIC
            ELSE 0::NUMERIC
        END AS custo_medio,
        CASE
            WHEN base.qtd > 0 AND COALESCE(base.preco_item, 0) > 0 THEN (COALESCE(base.preco_item, 0) / NULLIF(base.qtd, 0))::NUMERIC
            ELSE 0::NUMERIC
        END AS custo_medio_zeros,
        CASE
            WHEN base.qtd > 0 THEN (COALESCE(base.preco_item, 0) / NULLIF(base.qtd, 0))::NUMERIC
            ELSE 0::NUMERIC
        END AS custo_medio_dev,
        CASE
            WHEN base.qtd > 0 AND COALESCE(base.preco_item, 0) > 0 THEN (COALESCE(base.preco_item, 0) / NULLIF(base.qtd, 0))::NUMERIC
            ELSE 0::NUMERIC
        END AS custo_medio_dev_zeros
    FROM movimentacoes_base_calculo base
    WHERE base.rn = 1

    UNION ALL

    SELECT
        curr.produto_id,
        curr.grupo_periodo,
        curr.rn,
        GREATEST(0, (prev.saldo_apos_operacao + curr.qtd))::NUMERIC AS saldo_apos_operacao,
        (prev.saldo_apos_operacao + curr.qtd)::NUMERIC AS saldo_bruto,
        (CASE
            WHEN (prev.saldo_apos_operacao + curr.qtd) <= 0 THEN 0
            WHEN curr.entrada_saida LIKE '2%' OR curr.entrada_saida LIKE '3%' THEN prev.valor_saldo_estoque + (curr.qtd * prev.custo_medio)
            ELSE prev.valor_saldo_estoque + COALESCE(curr.preco_item, 0)
        END)::NUMERIC AS valor_saldo_estoque,
        (CASE
            WHEN (prev.saldo_apos_operacao + curr.qtd) <= 0 THEN 0
            WHEN curr.entrada_saida LIKE '2%' OR curr.entrada_saida LIKE '3%' THEN prev.valor_saldo_estoque_zeros + (curr.qtd * prev.custo_medio_zeros)
            ELSE prev.valor_saldo_estoque_zeros + (CASE WHEN COALESCE(curr.preco_item, 0) > 0 THEN COALESCE(curr.preco_item, 0) ELSE 0 END)
        END)::NUMERIC AS valor_saldo_estoque_zeros,
        (CASE
            WHEN (prev.saldo_apos_operacao + curr.qtd) <= 0 THEN 0
            WHEN curr.entrada_saida LIKE '2%' OR curr.entrada_saida LIKE '3%' THEN prev.valor_saldo_estoque_dev + (curr.qtd * prev.custo_medio_dev)
            WHEN curr.eh_devolucao THEN prev.valor_saldo_estoque_dev + (curr.qtd * prev.custo_medio_dev)
            ELSE prev.valor_saldo_estoque_dev + COALESCE(curr.preco_item, 0)
        END)::NUMERIC AS valor_saldo_estoque_dev,
        (CASE
            WHEN (prev.saldo_apos_operacao + curr.qtd) <= 0 THEN 0
            WHEN curr.entrada_saida LIKE '2%' OR curr.entrada_saida LIKE '3%' THEN prev.valor_saldo_estoque_dev_zeros + (curr.qtd * prev.custo_medio_dev_zeros)
            WHEN curr.eh_devolucao THEN prev.valor_saldo_estoque_dev_zeros + (curr.qtd * prev.custo_medio_dev_zeros)
            ELSE prev.valor_saldo_estoque_dev_zeros + (CASE WHEN COALESCE(curr.preco_item, 0) > 0 THEN COALESCE(curr.preco_item, 0) ELSE 0 END)
        END)::NUMERIC AS valor_saldo_estoque_dev_zeros,
        (CASE
            WHEN GREATEST(0, (prev.saldo_apos_operacao + curr.qtd)) <= 0 THEN 0
            WHEN curr.entrada_saida LIKE '2%' OR curr.entrada_saida LIKE '3%' OR curr.eh_devolucao THEN prev.custo_medio
            ELSE ((prev.valor_saldo_estoque + COALESCE(curr.preco_item, 0)) / NULLIF((prev.saldo_apos_operacao + curr.qtd), 0))
        END)::NUMERIC AS custo_medio,
        (CASE
            WHEN GREATEST(0, (prev.saldo_apos_operacao + curr.qtd)) <= 0 THEN 0
            WHEN curr.entrada_saida LIKE '2%' OR curr.entrada_saida LIKE '3%' OR curr.eh_devolucao OR COALESCE(curr.preco_item, 0) = 0 THEN prev.custo_medio_zeros
            ELSE (prev.valor_saldo_estoque_zeros + COALESCE(curr.preco_item, 0)) / NULLIF((prev.saldo_apos_operacao + curr.qtd), 0)
        END)::NUMERIC AS custo_medio_zeros,
        (CASE
            WHEN GREATEST(0, (prev.saldo_apos_operacao + curr.qtd)) <= 0 THEN 0
            WHEN curr.entrada_saida LIKE '2%' OR curr.entrada_saida LIKE '3%' THEN prev.custo_medio_dev
            ELSE
                ((CASE
                    WHEN curr.eh_devolucao THEN prev.valor_saldo_estoque_dev + (curr.qtd * prev.custo_medio_dev)
                    ELSE prev.valor_saldo_estoque_dev + COALESCE(curr.preco_item, 0)
                 END) / NULLIF(prev.saldo_apos_operacao + curr.qtd, 0))
        END)::NUMERIC AS custo_medio_dev,
        (CASE
            WHEN GREATEST(0, (prev.saldo_apos_operacao + curr.qtd)) <= 0 THEN 0
            WHEN curr.entrada_saida LIKE '2%' OR curr.entrada_saida LIKE '3%' THEN prev.custo_medio_dev_zeros
            ELSE
                ((CASE
                    WHEN curr.eh_devolucao THEN prev.valor_saldo_estoque_dev_zeros + (curr.qtd * prev.custo_medio_dev_zeros)
                    ELSE prev.valor_saldo_estoque_dev_zeros + (CASE WHEN COALESCE(curr.preco_item, 0) > 0 THEN COALESCE(curr.preco_item, 0) ELSE 0 END)
                 END) / NULLIF(prev.saldo_apos_operacao + curr.qtd, 0))
        END)::NUMERIC AS custo_medio_dev_zeros
    FROM
        movimentacoes_base_calculo curr
    JOIN
        calculo_custo_recursivo prev ON curr.produto_id = prev.produto_id
                                    AND curr.grupo_periodo = prev.grupo_periodo
                                    AND curr.rn = prev.rn + 1
),
resultado_calculado AS (
    SELECT
        m.produto_id, m.grupo_periodo, m.rn,
        c.saldo_apos_operacao, c.valor_saldo_estoque, c.custo_medio, c.saldo_bruto, c.custo_medio_zeros,
        c.custo_medio_dev, c.custo_medio_dev_zeros,
        COALESCE(LAG(c.custo_medio, 1) OVER (PARTITION BY m.produto_id, m.grupo_periodo ORDER BY m.rn), 0) AS custo_medio_anterior,
        COALESCE(LAG(c.custo_medio_zeros, 1) OVER (PARTITION BY m.produto_id, m.grupo_periodo ORDER BY m.rn), 0) AS custo_medio_zeros_anterior,
        COALESCE(LAG(c.custo_medio_dev, 1) OVER (PARTITION BY m.produto_id, m.grupo_periodo ORDER BY m.rn), 0) AS custo_medio_dev_ant,
        COALESCE(LAG(c.saldo_apos_operacao, 1) OVER (PARTITION BY m.produto_id, m.grupo_periodo ORDER BY m.rn), 0) AS saldo_anterior
    FROM movimentacoes_base_calculo m
    JOIN calculo_custo_recursivo c ON m.produto_id = c.produto_id AND m.grupo_periodo = c.grupo_periodo AND m.rn = c.rn
),
periodos AS (
    SELECT
        produto_id, grupo_periodo, MIN(data_evento) AS data_inicio_periodo, MAX(data_evento) AS data_fim_periodo
    FROM movimentacoes_numeradas
    GROUP BY produto_id, grupo_periodo
)
SELECT
    mov.entrada_saida,
    p.data_inicio_periodo,
    p.data_fim_periodo,
    mov.data_evento,
    mov.produto_id,
    mov.codigo_produto,
    mov.descricao_produto,
    mov.qtd AS qtd_operacao,
    mov.vl_item,
    mov.vl_desc,
    mov.vdesc,
    mov.voutro,
    mov.preco_item,
    (mov.preco_item / NULLIF(ABS(mov.qtd), 0)) AS preco_un,
    res.custo_medio_dev_ant,
    CASE
        WHEN mov.entrada_saida LIKE '2%' THEN
            CASE
                WHEN res.custo_medio_dev_ant > (mov.preco_item / NULLIF(ABS(mov.qtd), 0))
                THEN res.custo_medio_dev_ant - (mov.preco_item / NULLIF(ABS(mov.qtd), 0))
                ELSE 0
            END
        ELSE NULL
    END AS subfaturamento_venda,
    mov.dev_ou_exclusao,
    res.custo_medio,
    res.custo_medio_zeros,
    res.custo_medio_dev,
    res.custo_medio_dev_zeros,
    res.custo_medio_anterior,
    res.saldo_anterior,
    res.saldo_apos_operacao,
    res.valor_saldo_estoque,
    CASE
        WHEN mov.eh_devolucao THEN res.custo_medio_zeros_anterior
        ELSE NULL
    END AS custo_medio_zeros_dev_anterior, -- Renomeado para clareza
    mov.codigo_tributacao AS cod_trib,
    CASE
        WHEN mov.codigo_tributacao = 99 THEN mc.codigo_tributacao
        ELSE mov.codigo_tributacao
    END AS cod_trib_mult,
    SUM(CASE WHEN mov.entrada_saida = '1 - ENTRADA' THEN mov.qtd ELSE 0 END)
        OVER (PARTITION BY mov.produto_id, mov.grupo_periodo ORDER BY mov.rn) AS entrada_cum,
    SUM(CASE WHEN mov.entrada_saida LIKE '2%' THEN ABS(mov.qtd) ELSE 0 END)
        OVER (PARTITION BY mov.produto_id, mov.grupo_periodo ORDER BY mov.rn) AS saidas_cum, -- Exclui '3%'
    (SUM(CASE WHEN mov.eh_venda_para_preco_medio THEN mov.vl_item ELSE 0 END) OVER (PARTITION BY mov.produto_id, mov.grupo_periodo ORDER BY mov.rn))
    /
    NULLIF((SUM(CASE WHEN mov.eh_venda_para_preco_medio THEN ABS(mov.qtd) ELSE 0 END) OVER (PARTITION BY mov.produto_id, mov.grupo_periodo ORDER BY mov.rn)), 0)
    AS preco_medio_saida,
    (SUM(CASE WHEN mov.eh_venda_para_preco_medio AND mov.vl_item > 0 THEN mov.vl_item ELSE 0 END) OVER (PARTITION BY mov.produto_id, mov.grupo_periodo ORDER BY mov.rn))
    /
    NULLIF((SUM(CASE WHEN mov.eh_venda_para_preco_medio AND mov.vl_item > 0 THEN ABS(mov.qtd) ELSE 0 END) OVER (PARTITION BY mov.produto_id, mov.grupo_periodo ORDER BY mov.rn)), 0)
    AS preco_medio_saida_zeros,
    (SUM(CASE WHEN mov.eh_compra_para_preco_medio THEN mov.vl_item ELSE 0 END) OVER (PARTITION BY mov.produto_id, mov.grupo_periodo ORDER BY mov.rn))
    /
    NULLIF((SUM(CASE WHEN mov.eh_compra_para_preco_medio THEN mov.qtd ELSE 0 END) OVER (PARTITION BY mov.produto_id, mov.grupo_periodo ORDER BY mov.rn)), 0)
    AS preco_medio_entrada,
    (SUM(CASE WHEN mov.eh_compra_para_preco_medio AND mov.vl_item > 0 THEN mov.vl_item ELSE 0 END) OVER (PARTITION BY mov.produto_id, mov.grupo_periodo ORDER BY mov.rn))
    /
    NULLIF((SUM(CASE WHEN mov.eh_compra_para_preco_medio AND mov.vl_item > 0 THEN mov.qtd ELSE 0 END) OVER (PARTITION BY mov.produto_id, mov.grupo_periodo ORDER BY mov.rn)), 0)
    AS preco_medio_entrada_zeros,
    CASE
        WHEN res.saldo_bruto < 0 THEN ABS(res.saldo_bruto)
        ELSE 0
    END AS entradas_desacobertadas_operacao,
    SUM(CASE WHEN res.saldo_bruto < 0 THEN ABS(mov.qtd) - res.saldo_anterior ELSE 0 END)
        OVER (PARTITION BY mov.produto_id, mov.grupo_periodo ORDER BY mov.rn) AS entradas_desacobertadas_acumuladas,
    MAX(CASE WHEN mov.entrada_saida LIKE '3%' THEN ABS(mov.qtd) END) OVER (PARTITION BY mov.produto_id, mov.grupo_periodo) AS estoque_final_declarado, -- Pega o valor original antes de negativar
    mov.chave_acesso,
    mov.nnf,
    mov.num_item,
    mov.cfop_c170,
    mov.cfop_nf,

    -- Colunas C170
    mov.aliq_icms_c170,
    mov.aliq_nf_c170,
    mov.vl_icms_c170,
    mov.vl_bc_icms_st_c170,
    mov.vl_icms_st_c170,
    -- Colunas NF
    mov.vbc_nf,
    mov.picms_nf,
    mov.vicms_nf,
    mov.vb_st_nf,
    mov.picms_st_nf,
    mov.vicms_st_nf,

    cfop.ds_cfop,
    cfop.excluir_estoque,
    cfop.dev_simples,
    mov.chave_produto,
    mov.codigo_barra,
    mov.unid,
    SUM(CASE WHEN mov.entrada_saida = '1 - ENTRADA' AND COALESCE(cfop.excluir_estoque, FALSE) = FALSE THEN mov.qtd ELSE 0 END)
        OVER (PARTITION BY mov.produto_id, mov.grupo_periodo) AS entradas_totais,
    SUM(CASE WHEN mov.entrada_saida LIKE '2%' AND COALESCE(cfop.excluir_estoque, FALSE) = FALSE THEN ABS(mov.qtd) ELSE 0 END)
        OVER (PARTITION BY mov.produto_id, mov.grupo_periodo) AS saidas_totais -- Exclui '3%'
FROM movimentacoes_numeradas mov
JOIN periodos p
  ON p.produto_id = mov.produto_id
 AND p.grupo_periodo = mov.grupo_periodo
JOIN resultado_calculado res
  ON mov.produto_id = res.produto_id
 AND mov.grupo_periodo = res.grupo_periodo
 AND mov.rn = res.rn
LEFT JOIN dbo.cfop cfop ON cfop.co_cfop = COALESCE(mov.cfop_c170, mov.cfop_nf)
LEFT JOIN dbo.multipla_classificacao mc
  ON mov.produto_id = mc.produto_id
 AND mov.data_evento BETWEEN mc.vigencia_inicio AND mc.vigencia_fim
ORDER BY
    mov.produto_id,
    mov.rn;

-- =============================================================
-- ETAPA 3: CRIAÇÃO DA TABELA dbo.relatorio_mensal_estoque (lê da tabela filtrada)
-- =============================================================
-- Dropa a tabela do relatório mensal se ela já existir, para garantir a atualização
DROP TABLE IF EXISTS dbo.relatorio_mensal_estoque;

-- Cria a tabela com o relatório mensal agregado
CREATE TABLE dbo.relatorio_mensal_estoque AS
WITH
-- Adiciona o filtro de datas da designacao_fiscal
DatasFiscais AS (
    SELECT data_inicio::date, data_final::date
    FROM dbo.designacao_fiscal
    LIMIT 1
),
-- CTE para extrair o período (MM/YYYY) e identificar a última movimentação REAL de cada mês (excluindo estoque final)
movimentacoes_com_periodo AS (
    SELECT
        m.*,
        TO_CHAR(m.data_evento, 'MM/YYYY') AS periodo,
        ROW_NUMBER() OVER(PARTITION BY m.produto_id, TO_CHAR(m.data_evento, 'MM/YYYY') ORDER BY m.data_evento DESC, m.nnf DESC, m.num_item DESC) as rn_fim_mes
    FROM
        dbo.mov_estoque_completa_otimizada m
    CROSS JOIN DatasFiscais df
    WHERE m.entrada_saida NOT LIKE '3%' -- Exclui a linha '3 - ESTOQUE FINAL' da numeração
      AND m.data_evento::date BETWEEN df.data_inicio AND df.data_final -- Filtra pelo período fiscal
),
-- CTE para agregar os totais mensais (lê de 'movimentacoes_com_periodo' que já está filtrada)
totais_mensais AS (
    SELECT
        produto_id,
        codigo_produto,
        descricao_produto,
        periodo,
        SUM(CASE WHEN entrada_saida = '1 - ENTRADA' AND COALESCE(excluir_estoque, FALSE) = FALSE AND COALESCE(dev_simples, FALSE) = FALSE THEN qtd_operacao ELSE 0 END) AS entradas_totais_qtd,
        SUM(CASE WHEN entrada_saida = '1 - ENTRADA' AND COALESCE(excluir_estoque, FALSE) = FALSE AND COALESCE(dev_simples, FALSE) = FALSE THEN vl_item ELSE 0 END) AS valor_total_entradas,
        SUM(CASE WHEN entrada_saida = '1 - ENTRADA' AND COALESCE(excluir_estoque, FALSE) = FALSE AND COALESCE(dev_simples, FALSE) = FALSE THEN preco_item ELSE 0 END) AS valor_tot_ent_2,
        SUM(CASE WHEN entrada_saida = '2 - SAIDA' AND COALESCE(excluir_estoque, FALSE) = FALSE AND COALESCE(dev_simples, FALSE) = FALSE THEN ABS(qtd_operacao) ELSE 0 END) AS saidas_totais_qtd,
        SUM(CASE WHEN entrada_saida = '2 - SAIDA' AND COALESCE(excluir_estoque, FALSE) = FALSE AND COALESCE(dev_simples, FALSE) = FALSE THEN preco_item ELSE 0 END) AS valor_total_saidas,
        SUM(entradas_desacobertadas_operacao) AS total_entradas_desacobertadas
    FROM
        movimentacoes_com_periodo
    GROUP BY
        produto_id, codigo_produto, descricao_produto, periodo
),
-- CTE para buscar os valores finais de cada mês (saldo, custo, etc.) da ÚLTIMA OPERAÇÃO REAL
valores_finais_mes AS (
    SELECT
        produto_id,
        periodo,
        saldo_apos_operacao AS quantidade_final_periodo,
        custo_medio_dev AS custo_medio_unitario,
        (saldo_apos_operacao * custo_medio_dev) AS valor_estoque_final_periodo
    FROM
        movimentacoes_com_periodo
    WHERE
        rn_fim_mes = 1 -- Pega a última linha REAL do mês
)
-- Junção final para montar o relatório
SELECT
    t.periodo,
    t.produto_id,
    t.codigo_produto,
    t.descricao_produto,
    t.valor_total_entradas,
    t.valor_tot_ent_2,
    t.entradas_totais_qtd,
    t.valor_total_entradas / NULLIF(t.entradas_totais_qtd, 0) AS preco_medio_unitario_entradas,
    t.valor_total_saidas,
    t.saidas_totais_qtd,
    t.valor_total_saidas / NULLIF(t.saidas_totais_qtd, 0) AS preco_medio_unitario_saidas,
    f.quantidade_final_periodo,
    f.custo_medio_unitario,
    f.valor_estoque_final_periodo,
    t.total_entradas_desacobertadas
FROM
    totais_mensais t
JOIN
    valores_finais_mes f ON t.produto_id = f.produto_id AND t.periodo = f.periodo
ORDER BY
    t.produto_id,
    TO_DATE(t.periodo, 'MM/YYYY');

-- Criação de Índices para a nova tabela de relatório mensal
CREATE INDEX idx_rel_mensal_produto_periodo ON dbo.relatorio_mensal_estoque (produto_id, periodo);
CREATE INDEX idx_rel_mensal_periodo ON dbo.relatorio_mensal_estoque (periodo);
CREATE INDEX idx_rel_mensal_produto_id ON dbo.relatorio_mensal_estoque (produto_id);

-- =============================================================
-- ETAPA 4: CRIAÇÃO DA TABELA dbo.relatorio_anual_estoque (lê da tabela filtrada)
-- =============================================================
-- Dropa a tabela do relatório anual se ela já existir
DROP TABLE IF EXISTS dbo.relatorio_anual_estoque;

-- Cria a tabela com o relatório anual agregado
CREATE TABLE dbo.relatorio_anual_estoque AS
WITH
-- Adiciona o filtro de datas da designacao_fiscal
DatasFiscais AS (
    SELECT data_inicio::date, data_final::date
    FROM dbo.designacao_fiscal
    LIMIT 1
),
-- Adiciona o ano a cada movimentação, já filtrando pelo período fiscal
movimentacoes_com_ano AS (
    SELECT
        m.*,
        EXTRACT(YEAR FROM m.data_evento) AS ano_apuracao
    FROM
        dbo.mov_estoque_completa_otimizada m
    CROSS JOIN DatasFiscais df
    WHERE m.data_evento::date BETWEEN df.data_inicio AND df.data_final -- Filtra pelo período fiscal
),
-- Calcula o estoque inicial de cada ano/produto (Corrigido para PostgreSQL)
estoque_inicial_ano AS (
    SELECT
        produto_id,
        ano_apuracao,
        estoque_inicial_qtd
    FROM (
        SELECT
            produto_id,
            ano_apuracao,
            qtd_operacao AS estoque_inicial_qtd,
            ROW_NUMBER() OVER(PARTITION BY produto_id, ano_apuracao ORDER BY data_evento) as rn
        FROM
            movimentacoes_com_ano
        WHERE entrada_saida LIKE '0%' -- Busca a linha de estoque inicial (que já foi filtrada pela data de início)
    ) AS ranked_inicial
    WHERE rn = 1
),
-- Calcula os totais anuais de entradas, saídas declaradas e entradas desacobertadas
totais_anuais AS (
    SELECT
        produto_id,
        ano_apuracao,
        SUM(CASE WHEN entrada_saida = '1 - ENTRADA' AND COALESCE(excluir_estoque, FALSE) = FALSE THEN qtd_operacao ELSE 0 END) AS entradas_totais,
        SUM(CASE WHEN entrada_saida LIKE '2%' AND COALESCE(excluir_estoque, FALSE) = FALSE THEN ABS(qtd_operacao) ELSE 0 END) AS saidas_totais_declaradas,
        SUM(CASE WHEN entrada_saida NOT LIKE '3%' THEN entradas_desacobertadas_operacao ELSE 0 END) AS entradas_desacobertadas,
        -- Captura o valor de desacobertadas_operacao da linha de Estoque Final
        MAX(CASE WHEN entrada_saida LIKE '3%' THEN entradas_desacobertadas_operacao ELSE 0 END) AS entradas_desac_estoque_final_val
    FROM
        movimentacoes_com_ano
    GROUP BY
        produto_id, ano_apuracao
),
-- Busca o estoque final declarado
valores_finais_ano AS (
     SELECT DISTINCT
        produto_id,
        ano_apuracao,
        -- Pega o estoque final declarado da última linha '3 - ESTOQUE FINAL'
        FIRST_VALUE(estoque_final_declarado) OVER (PARTITION BY produto_id, ano_apuracao ORDER BY data_evento DESC, nnf DESC, num_item DESC) as estoque_final_declarado
     FROM
        movimentacoes_com_ano
    WHERE entrada_saida LIKE '3%' -- Garante que estamos pegando o valor da linha de estoque final
)

-- Monta o relatório anual final
SELECT
    -- Define os períodos inicial e final do ano
    (t.ano_apuracao::text || '-01-01')::date AS periodo_apuracao_inicial,
    (t.ano_apuracao::text || '-12-31')::date AS periodo_apuracao_final,
    t.produto_id,
    p.codigo_produto,
    p.descricao_produto,
    COALESCE(ei.estoque_inicial_qtd, 0) AS estoque_inicial,
    COALESCE(t.entradas_totais, 0) AS entradas_totais,
    COALESCE(vf.estoque_final_declarado, 0) AS estoque_final_declarado,
    -- Saídas Calculadas = Estoque Inicial + Entradas Totais + Entradas Desacorbertadas - Estoque Final Declarado
    (COALESCE(ei.estoque_inicial_qtd, 0) + COALESCE(t.entradas_totais, 0) + COALESCE(t.entradas_desacobertadas, 0) - COALESCE(vf.estoque_final_declarado, 0)) AS saidas_totais_calculadas,
    COALESCE(t.saidas_totais_declaradas, 0) AS saidas_totais_declaradas,
    COALESCE(t.entradas_desacobertadas, 0) AS entradas_desacobertadas,
    COALESCE(t.entradas_desac_estoque_final_val, 0) AS entradas_desac_estoque_final,
    -- Saídas Desacobertadas = Saídas Calculadas - Saídas Declaradas
    GREATEST(0, (COALESCE(ei.estoque_inicial_qtd, 0) + COALESCE(t.entradas_totais, 0) + COALESCE(t.entradas_desacobertadas, 0) - COALESCE(vf.estoque_final_declarado, 0)) - COALESCE(t.saidas_totais_declaradas, 0)) AS saidas_desacobertadas
FROM
    totais_anuais t
LEFT JOIN
    estoque_inicial_ano ei ON t.produto_id = ei.produto_id AND t.ano_apuracao = ei.ano_apuracao
LEFT JOIN
    valores_finais_ano vf ON t.produto_id = vf.produto_id AND t.ano_apuracao = vf.ano_apuracao
LEFT JOIN -- Join para buscar codigo e descricao do produto
    dbo.produto p ON t.produto_id = p.produto_id
ORDER BY
    t.produto_id,
    t.ano_apuracao;

-- Criação de Índices para a nova tabela de relatório anual
CREATE INDEX idx_rel_anual_produto_ano ON dbo.relatorio_anual_estoque (produto_id, periodo_apuracao_inicial);
CREATE INDEX idx_rel_anual_ano ON dbo.relatorio_anual_estoque (periodo_apuracao_inicial);
CREATE INDEX idx_rel_anual_produto_id ON dbo.relatorio_anual_estoque (produto_id);

-- =============================================================
-- ETAPA 5: CRIAÇÃO DE ÍNDICES PARA dbo.mov_estoque_completa_otimizada
-- =============================================================
CREATE INDEX idx_mov_estoque_produto_data ON dbo.mov_estoque_completa_otimizada (produto_id, data_evento);
CREATE INDEX idx_mov_estoque_chave_acesso ON dbo.mov_estoque_completa_otimizada (chave_acesso);
CREATE INDEX idx_mov_estoque_codigo_produto ON dbo.mov_estoque_completa_otimizada (codigo_produto);
CREATE INDEX idx_mov_estoque_data_evento ON dbo.mov_estoque_completa_otimizada (data_evento);
CREATE INDEX idx_mov_estoque_produto_id ON dbo.mov_estoque_completa_otimizada (produto_id);
