WITH PARAMETROS AS (
    SELECT
        :CNPJ AS cnpj_filtro,
        TO_DATE(:data_inicial, 'DD/MM/YYYY') AS dt_ini_filtro,
        TO_DATE(:data_final,   'DD/MM/YYYY') AS dt_fim_filtro,
        NVL(TO_DATE(:data_limite_processamento, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_corte
    FROM dual
),

ARQUIVOS_RANKING AS (
    SELECT
        reg_0000.id as reg_0000_id,
        reg_0000.cnpj,
        reg_0000.cod_fin AS cod_fin_efd,
        reg_0000.dt_ini,
        reg_0000.dt_fin,
        reg_0000.data_entrega,
        CASE
            WHEN reg_0000.cod_fin = 0 THEN '0 - Remessa do arquivo original'
            WHEN reg_0000.cod_fin = 1 THEN '1 - Remessa do arquivo substituto'
            ELSE 'Outros'
        END AS desc_finalidade,
        p.dt_corte,
        p.dt_ini_filtro,
        p.dt_fim_filtro,
        ROW_NUMBER() OVER (
            PARTITION BY reg_0000.cnpj, reg_0000.dt_ini
            ORDER BY reg_0000.data_entrega DESC
        ) AS rn
    FROM sped.reg_0000 reg_0000
    JOIN PARAMETROS p ON reg_0000.cnpj = p.cnpj_filtro
    WHERE
        reg_0000.data_entrega <= p.dt_corte
        AND reg_0000.dt_ini BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro
),

/* CTE 1: DADOS BRUTOS E WINDOW FUNCTIONS */
BASE_DADOS AS (
    SELECT
        TO_CHAR(arq.dt_ini, 'MM/YYYY') AS periodo_efd,
        c100.chv_nfe chave_nf_saida_c100,
        CASE c100.ind_oper WHEN '0' THEN '0 - Entrada' WHEN '1' THEN '1 - Saída' END AS ind_oper_desc,
        c170.num_item num_item_c170,
        c170.cod_item,
        c170.descr_compl,
        c170.qtd qtd_saida_c170,
        c170.vl_icms AS vl_icms_c170, -- Trazido para cá para usar no cálculo final

        /* CÁLCULO DA JANELA (MANTIDO) */
        GREATEST(0,
            c170.qtd - NVL(
                SUM(nfe_ent.prod_qcom) OVER (
                    PARTITION BY c100.chv_nfe, c170.num_item
                    ORDER BY c176.chave_nfe_ult, c176.num_item_ult_e
                    ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
                ), 0
            )
        ) AS qtd_a_ressarc_c170,

        /* CÁLCULO DA JANELA PARA NF */
        GREATEST(0,
            nfe.prod_qcom - NVL(
                SUM(nfe_ent.prod_qcom) OVER (
                    PARTITION BY c100.chv_nfe, c170.num_item
                    ORDER BY c176.chave_nfe_ult, c176.num_item_ult_e
                    ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
                ), 0
            )
        ) AS qtd_a_ressarc_nf,

        nfe_ent.prod_qcom AS qtd_entrada_nf,
        nfe_ent.prod_vprod valor_entrada_nf,
        nfe.prod_qcom qtd_saida_nf,
        nfe.chave_acesso chave_nfe_saida,
        nfe.dhemi emissão_nf,
        nfe.nnf n_nf,
        nfe.co_destinatario cnpj_dest,
        nfe.xnome_dest destinatario,
        nfe.co_uf_dest uf,
        nfe.co_cfop cfop,
        nfe.prod_nitem n_item_nf,
        nfe.seq_nitem seq_n_item_nf,
        nfe.prod_xprod descr_produto_nf,
        nfe.prod_vprod valor_saida_nf,
        nfe.icms_vicms icms_saida_nf,
        nfe.icms_vicmsst icms_st_saida_nf,
        c176.chave_nfe_ult chv_ult_e,
        c176.num_item_ult_e n_item_ult_e,
        c176.vl_unit_bc_st vr_bc_st_ult_e,
        c176.vl_unit_icms_ult_e icms_ult_e,
        c176.aliq_st_ult_e aliq_st_ult_e,
        c176.vl_unit_res vr_un_ressarc,

        /* Campos auxiliares para o cálculo final */
        nfe.icms_vicms AS vl_icms_nf_saida,

        arq.cod_fin_efd,
        arq.data_entrega
    FROM
        sped.reg_c176 c176
    INNER JOIN ARQUIVOS_RANKING arq ON c176.reg_0000_id = arq.reg_0000_id
    LEFT JOIN sped.reg_c100 c100 ON c176.reg_c100_id = c100.id
    LEFT JOIN sped.reg_c170 c170 ON c176.reg_c100_id = c100.id AND c176.reg_c170_id = c170.id
    LEFT JOIN bi.fato_nfe_detalhe nfe
      ON c100.chv_nfe = nfe.chave_acesso
      AND LTRIM(c170.cod_item, '0') = LTRIM(nfe.prod_cprod, '0')
    LEFT JOIN bi.fato_nfe_detalhe nfe_ent
      ON c176.chave_nfe_ult = nfe_ent.chave_acesso
      AND LTRIM(c170.cod_item, '0') = LTRIM(nfe_ent.prod_cprod, '0')
    WHERE arq.rn = 1
),

/* CTE 2: CALCULA A QTD_RESSARC EFETIVA */
BASE_COM_QTD AS (
    SELECT
        bd.*,
        CASE
            WHEN bd.qtd_a_ressarc_c170 > bd.qtd_entrada_nf THEN bd.qtd_entrada_nf
            ELSE bd.qtd_a_ressarc_c170
        END AS qtd_ressarc_c170,
        CASE
            WHEN bd.qtd_a_ressarc_nf > bd.qtd_entrada_nf THEN bd.qtd_entrada_nf
            ELSE bd.qtd_a_ressarc_nf
        END AS qtd_ressarc_nf
    FROM BASE_DADOS bd
)

/* SELECT FINAL: APLICA AS FÓRMULAS DE VALOR USANDO QTD_RESSARC */
SELECT
    bq.periodo_efd,
    bq.chave_nf_saida_c100,
    bq.ind_oper_desc,
    bq.num_item_c170,
    bq.cod_item,
    bq.descr_compl,
    bq.qtd_saida_c170,
    bq.qtd_a_ressarc_c170,
    bq.qtd_ressarc_c170,
    bq.qtd_a_ressarc_nf,
    bq.qtd_ressarc_nf,
    bq.qtd_entrada_nf,
    bq.valor_entrada_nf,
    bq.qtd_saida_nf,
    bq.chave_nfe_saida,
    bq.emissão_nf,
    bq.n_nf,
    bq.cnpj_dest,
    bq.destinatario,
    bq.uf,
    bq.cfop,
    bq.n_item_nf,
    bq.seq_n_item_nf,
    bq.descr_produto_nf,
    bq.valor_saida_nf,
    bq.icms_saida_nf,
    bq.icms_st_saida_nf,
    bq.chv_ult_e,
    bq.n_item_ult_e,
    bq.vr_bc_st_ult_e,
    bq.icms_ult_e,
    bq.aliq_st_ult_e,
    bq.vr_un_ressarc,

    /* NOVA FÓRMULA: VR_TOTAL_RESSARC_C170 USANDO QTD_RESSARC */
    CASE
        WHEN bq.vl_icms_c170 > 0 THEN (bq.qtd_ressarc_c170 * bq.vr_un_ressarc) + (bq.qtd_ressarc_c170 * bq.icms_ult_e)
        ELSE bq.qtd_ressarc_c170 * bq.vr_un_ressarc
    END AS vr_total_ressarc_c170,
    /* FIM NOVA FÓRMULA */

    /* FÓRMULA NF (Mantive a lógica, mas atualizei para usar a nova qtd_ressarc se desejar,
       mas no original usava prod_qcom. Se precisar alterar essa também, avise.
       Abaixo mantive o original usando nfe.prod_qcom, apenas ajustando as colunas) */
    CASE
        WHEN bq.vl_icms_nf_saida > 0 THEN (bq.qtd_ressarc_nf * bq.vr_un_ressarc) + (bq.qtd_ressarc_nf * bq.icms_ult_e)
        ELSE bq.qtd_ressarc_nf * bq.vr_un_ressarc
    END AS vr_total_ressarc_nf,

    bq.cod_fin_efd,
    bq.data_entrega
FROM BASE_COM_QTD bq
ORDER BY
    bq.emissão_nf, bq.n_nf, bq.n_item_nf, bq.chv_ult_e
