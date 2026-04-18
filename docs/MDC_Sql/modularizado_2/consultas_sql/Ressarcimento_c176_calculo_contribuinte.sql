WITH PARAMETROS AS (
    SELECT
        :CNPJ AS cnpj_filtro,
        TO_DATE(:data_inicial, 'DD/MM/YYYY') AS dt_ini_filtro,
        TO_DATE(:data_final,   'DD/MM/YYYY') AS dt_fim_filtro,
        NVL(TO_DATE(:data_limite_processamento, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_corte
    FROM dual
),

/* CTE 1: Arquivos EFD filtrados - apenas campos necessários para ranking */
ARQUIVOS_FILTRADOS AS (
    SELECT
        r.id AS reg_0000_id,
        r.dt_ini,
        r.cod_fin AS cod_fin_efd,
        r.data_entrega,
        ROW_NUMBER() OVER (
            PARTITION BY r.cnpj, r.dt_ini
            ORDER BY r.data_entrega DESC
        ) AS rn
    FROM sped.reg_0000 r, PARAMETROS p
    WHERE r.cnpj = p.cnpj_filtro
      AND r.data_entrega <= p.dt_corte
      AND r.dt_ini BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro
),

/* CTE 2: Registros C176 com apenas campos essenciais */
C176_BASE AS (
    SELECT
        c176.reg_c100_id,
        c176.reg_c170_id,
        c176.chave_nfe_ult,
        c176.num_item_ult_e,
        c176.vl_unit_bc_st,
        c176.vl_unit_icms_ult_e,
        c176.aliq_st_ult_e,
        c176.vl_unit_res,
        af.dt_ini,
        af.cod_fin_efd,
        af.data_entrega
    FROM sped.reg_c176 c176
    INNER JOIN ARQUIVOS_FILTRADOS af ON c176.reg_0000_id = af.reg_0000_id AND af.rn = 1
),

/* CTE 3: Dados C100/C170 - apenas campos utilizados */
C100_C170_DADOS AS (
    SELECT
        cb.reg_c100_id,
        cb.reg_c170_id,
        cb.chave_nfe_ult,
        cb.num_item_ult_e,
        cb.vl_unit_bc_st,
        cb.vl_unit_icms_ult_e,
        cb.aliq_st_ult_e,
        cb.vl_unit_res,
        cb.dt_ini,
        cb.cod_fin_efd,
        cb.data_entrega,
        c100.chv_nfe,
        c100.ind_oper,
        c170.num_item,
        c170.cod_item,
        c170.descr_compl,
        c170.qtd AS qtd_c170,
        c170.vl_icms AS vl_icms_c170,
        c170.cst_icms AS cst_icms_c170
    FROM C176_BASE cb
    INNER JOIN sped.reg_c100 c100 ON cb.reg_c100_id = c100.id
    INNER JOIN sped.reg_c170 c170 ON cb.reg_c100_id = c170.reg_c100_id AND cb.reg_c170_id = c170.id
),

/* CTE 4: Join com NFe saída - campos mínimos */
NFE_SAIDA AS (
    SELECT
        cd.reg_c100_id,
        cd.reg_c170_id,
        cd.chave_nfe_ult,
        cd.num_item_ult_e,
        cd.vl_unit_bc_st,
        cd.vl_unit_icms_ult_e,
        cd.aliq_st_ult_e,
        cd.vl_unit_res,
        cd.dt_ini,
        cd.cod_fin_efd,
        cd.data_entrega,
        cd.chv_nfe,
        cd.ind_oper,
        cd.num_item,
        cd.cod_item,
        cd.descr_compl,
        cd.qtd_c170,
        cd.vl_icms_c170,
        cd.cst_icms_c170,
        nfe.prod_qcom AS qtd_saida_nf,
        nfe.chave_acesso AS chave_nfe_saida,
        nfe.dhemi AS emissao_nf,
        nfe.nnf AS n_nf,
        nfe.co_destinatario AS cnpj_dest,
        nfe.xnome_dest AS destinatario,
        nfe.co_uf_dest AS uf,
        nfe.co_cfop AS cfop,
        nfe.prod_nitem AS n_item_nf,
        nfe.seq_nitem AS seq_n_item_nf,
        nfe.prod_xprod AS descr_produto_nf,
        nfe.prod_vprod AS valor_saida_nf,
        nfe.icms_vicms AS icms_saida_nf,
        nfe.icms_vicmsst AS icms_st_saida_nf,
        nfe.icms_cst AS cst_icms_nf
    FROM C100_C170_DADOS cd
    LEFT JOIN bi.fato_nfe_detalhe nfe
      ON cd.chv_nfe = nfe.chave_acesso
      AND LTRIM(cd.cod_item, '0') = LTRIM(nfe.prod_cprod, '0')
),

/* CTE 5: Join com NFe entrada + window functions */
NFE_COM_ENTRADA AS (
    SELECT
        ns.*,
        nfe_ent.prod_qcom AS qtd_entrada_nf,
        nfe_ent.prod_vprod AS valor_entrada_nf,
        GREATEST(0,
            ns.qtd_c170 - NVL(
                SUM(nfe_ent.prod_qcom) OVER (
                    PARTITION BY ns.chv_nfe, ns.num_item
                    ORDER BY ns.chave_nfe_ult, ns.num_item_ult_e
                    ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
                ), 0
            )
        ) AS qtd_a_ressarc_c170,
        GREATEST(0,
            ns.qtd_saida_nf - NVL(
                SUM(nfe_ent.prod_qcom) OVER (
                    PARTITION BY ns.chv_nfe, ns.num_item
                    ORDER BY ns.chave_nfe_ult, ns.num_item_ult_e
                    ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
                ), 0
            )
        ) AS qtd_a_ressarc_nf
    FROM NFE_SAIDA ns
    LEFT JOIN bi.fato_nfe_detalhe nfe_ent
      ON ns.chave_nfe_ult = nfe_ent.chave_acesso
      AND LTRIM(ns.cod_item, '0') = LTRIM(nfe_ent.prod_cprod, '0')
),

/* CTE 6: Calcula qtd_ressarc efetiva */
QTD_RESSARC AS (
    SELECT
        ne.*,
        LEAST(ne.qtd_a_ressarc_c170, NVL(ne.qtd_entrada_nf, ne.qtd_a_ressarc_c170)) AS qtd_ressarc_c170,
        LEAST(ne.qtd_a_ressarc_nf, NVL(ne.qtd_entrada_nf, ne.qtd_a_ressarc_nf)) AS qtd_ressarc_nf
    FROM NFE_COM_ENTRADA ne
)

/* SELECT FINAL */
SELECT
    TO_CHAR(qr.dt_ini, 'MM/YYYY') AS periodo_efd,
    qr.chv_nfe AS chave_nf_saida_c100,
    CASE qr.ind_oper WHEN '0' THEN '0 - Entrada' WHEN '1' THEN '1 - Saída' END AS ind_oper_desc,
    qr.num_item AS num_item_c170,
    qr.cod_item,
    qr.descr_compl,
    qr.qtd_c170 AS qtd_saida_c170,
    qr.qtd_a_ressarc_c170,
    qr.qtd_ressarc_c170,
    qr.qtd_a_ressarc_nf,
    qr.qtd_ressarc_nf,
    qr.qtd_entrada_nf,
    qr.valor_entrada_nf,
    qr.qtd_saida_nf,
    qr.chave_nfe_saida,
    qr.emissao_nf AS emissão_nf,
    qr.n_nf,
    qr.cnpj_dest,
    qr.destinatario,
    qr.uf,
    qr.cfop,
    qr.n_item_nf,
    qr.seq_n_item_nf,
    qr.descr_produto_nf,
    qr.valor_saida_nf,
    qr.icms_saida_nf,
    qr.icms_st_saida_nf,
    qr.cst_icms_c170,
    qr.cst_icms_nf,
    qr.chave_nfe_ult AS chv_ult_e,
    qr.num_item_ult_e AS n_item_ult_e,
    qr.vl_unit_bc_st AS vr_bc_st_ult_e,
    qr.vl_unit_icms_ult_e AS icms_ult_e,
    qr.aliq_st_ult_e,
    qr.vl_unit_res AS vr_un_ressarc,
    qr.qtd_ressarc_c170 * (qr.vl_unit_res) AS ressarc_st_c170,
    qr.qtd_ressarc_c170 * (qr.vl_unit_icms_ult_e) AS ressarc_prop_c170,
    qr.qtd_ressarc_c170 * (qr.vl_unit_res) + qr.qtd_ressarc_c170 * (qr.vl_unit_icms_ult_e) AS total_ressarc_c170,
    CASE
        WHEN qr.vl_icms_c170 > 0 THEN qr.qtd_ressarc_c170 * (qr.vl_unit_res + qr.vl_unit_icms_ult_e)
        ELSE qr.qtd_ressarc_c170 * qr.vl_unit_res
    END AS vr_total_ressarc_c170,
    qr.qtd_ressarc_nf * (qr.vl_unit_res) AS ressarc_st_nf,
    qr.qtd_ressarc_nf * (qr.vl_unit_icms_ult_e) AS ressarc_prop_nf,
    qtd_saida_nf*(vl_unit_res + vl_unit_icms_ult_e) AS ressarc_qtd_saída_c170,
    qr.qtd_ressarc_nf * (qr.vl_unit_res) + qr.qtd_ressarc_nf * (qr.vl_unit_icms_ult_e) AS total_ressarc_nf,
    CASE
        WHEN qr.icms_saida_nf > 0 THEN qr.qtd_ressarc_nf * (qr.vl_unit_res + qr.vl_unit_icms_ult_e)
        ELSE qr.qtd_ressarc_nf * qr.vl_unit_res
    END AS vr_total_ressarc_nf,
    /* Diferença entre ressarcimento C170 e NF */
    (CASE
        WHEN qr.vl_icms_c170 > 0 THEN qr.qtd_ressarc_c170 * (qr.vl_unit_res + qr.vl_unit_icms_ult_e)
        ELSE qr.qtd_ressarc_c170 * qr.vl_unit_res
    END) - (CASE
        WHEN qr.icms_saida_nf > 0 THEN qr.qtd_ressarc_nf * (qr.vl_unit_res + qr.vl_unit_icms_ult_e)
        ELSE qr.qtd_ressarc_nf * qr.vl_unit_res
    END) AS dif_ressarc,
    qr.cod_fin_efd,
    qr.data_entrega
FROM QTD_RESSARC qr
ORDER BY qr.emissao_nf, qr.n_nf, qr.n_item_nf, qr.chave_nfe_ult

---VERIFICAR CST
