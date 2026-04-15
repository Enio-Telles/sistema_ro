/*
===============================================================================
MÓDULO 03 - XML DE ENTRADA + FRONTEIRA
-------------------------------------------------------------------------------
Objetivo
- Buscar o item do XML da nota de entrada referenciada no C176.
- Enriquecer com cálculo do Fronteira por item.

Granularidade
- 1 linha por chave de entrada + item_xml_padrao.

Filtro de negócio relevante
- O XML de entrada é filtrado para:
  * operação interestadual,
  * destino RO,
  * emitente fora de RO.

Leitura crítica
- Esse filtro faz sentido para muitas operações de antecipação com encerramento de
  fase, mas não cobre necessariamente todo o universo de ressarcimento.
===============================================================================
*/

WITH
PARAMETROS AS (
    SELECT
        :CNPJ AS cnpj_filtro,
        NVL(TO_DATE(:data_inicial, 'DD/MM/YYYY'), TO_DATE('01/01/1900', 'DD/MM/YYYY')) AS dt_ini_filtro,
        NVL(TO_DATE(:data_final, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_fim_filtro,
        NVL(TO_DATE(:data_limite_processamento, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_corte
    FROM dual
),
ARQUIVOS_ULTIMA_EFD_PERIODO AS (
    SELECT *
    FROM (
        SELECT
            r.id AS reg_0000_id,
            r.cnpj,
            r.cod_fin AS cod_fin_efd,
            r.dt_ini,
            r.dt_fin,
            r.data_entrega,
            ROW_NUMBER() OVER (
                PARTITION BY r.cnpj, r.dt_ini, NVL(r.dt_fin, r.dt_ini)
                ORDER BY r.data_entrega DESC, r.id DESC
            ) AS rn
        FROM sped.reg_0000 r
        JOIN PARAMETROS p
          ON r.cnpj = p.cnpj_filtro
        WHERE r.data_entrega <= p.dt_corte
    )
    WHERE rn = 1
),
ARQUIVOS_VALIDOS AS (
    SELECT
        a.reg_0000_id,
        a.cnpj,
        a.cod_fin_efd,
        a.dt_ini,
        a.dt_fin,
        a.data_entrega
    FROM ARQUIVOS_ULTIMA_EFD_PERIODO a
    JOIN PARAMETROS p
      ON a.dt_ini BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro
),
SAIDAS_RESSARCIMENTO AS (
    SELECT
        c176.reg_0000_id,
        c100.chv_nfe AS chave_saida,
        c170.num_item AS num_item_saida,
        c170.cod_item,
        c176.chave_nfe_ult AS chave_nfe_ultima_entrada
    FROM sped.reg_c176 c176
    JOIN ARQUIVOS_VALIDOS arq
      ON c176.reg_0000_id = arq.reg_0000_id
    JOIN sped.reg_c100 c100
      ON c176.reg_c100_id = c100.id
     AND c100.reg_0000_id = arq.reg_0000_id
    JOIN sped.reg_c170 c170
      ON c176.reg_c170_id = c170.id
     AND c170.reg_0000_id = arq.reg_0000_id
),
CHAVES_ENTRADA AS (
    SELECT DISTINCT chave_nfe_ultima_entrada AS chave_acesso
    FROM SAIDAS_RESSARCIMENTO
    WHERE chave_nfe_ultima_entrada IS NOT NULL
),
XML_ENTRADA_BASE AS (
    SELECT
        nfe_ent.chave_acesso,
        nfe_ent.seq_nitem,
        nfe_ent.prod_nitem,
        COALESCE(nfe_ent.prod_nitem, nfe_ent.seq_nitem) AS item_xml_padrao,
        nfe_ent.prod_xprod AS xml_descricao_item_entrada,
        nfe_ent.prod_ncm AS xml_ncm_entrada,
        nfe_ent.prod_cest AS xml_cest_entrada,
        nfe_ent.prod_qcom AS qcom_entrada,
        nfe_ent.prod_vprod,
        nfe_ent.prod_vfrete,
        nfe_ent.prod_vseg,
        nfe_ent.prod_voutro,
        nfe_ent.prod_vdesc,
        nfe_ent.ipi_vipi,
        nfe_ent.icms_vicms AS xml_icms_vicms_total_entrada,
        nfe_ent.icms_picms AS aliq_inter_entrada,
        calc_front.it_co_rotina_calculo,
        calc_front.it_vl_icms AS vl_icms_fronteira,
        ROW_NUMBER() OVER (
            PARTITION BY nfe_ent.chave_acesso, COALESCE(nfe_ent.prod_nitem, nfe_ent.seq_nitem)
            ORDER BY NVL(nfe_ent.prod_nitem, -1) DESC, NVL(nfe_ent.seq_nitem, -1) DESC
        ) AS rn
    FROM bi.fato_nfe_detalhe nfe_ent
    JOIN CHAVES_ENTRADA ce
      ON nfe_ent.chave_acesso = ce.chave_acesso
    LEFT JOIN sitafe.sitafe_nfe_calculo_item calc_front
      ON calc_front.it_nu_chave_acesso = nfe_ent.chave_acesso
     AND calc_front.it_nu_item = COALESCE(nfe_ent.prod_nitem, nfe_ent.seq_nitem)
    WHERE nfe_ent.co_iddest = 2
      AND nfe_ent.co_uf_dest = 'RO'
      AND nfe_ent.co_uf_emit <> 'RO'
),
XML_ENTRADA AS (
    SELECT
        chave_acesso,
        seq_nitem,
        prod_nitem,
        item_xml_padrao,
        xml_descricao_item_entrada,
        xml_ncm_entrada,
        xml_cest_entrada,
        qcom_entrada,
        prod_vprod,
        prod_vfrete,
        prod_vseg,
        prod_voutro,
        prod_vdesc,
        ipi_vipi,
        xml_icms_vicms_total_entrada,
        aliq_inter_entrada,
        it_co_rotina_calculo,
        vl_icms_fronteira
    FROM XML_ENTRADA_BASE
    WHERE rn = 1
)
SELECT *
FROM XML_ENTRADA
ORDER BY chave_acesso, item_xml_padrao;
