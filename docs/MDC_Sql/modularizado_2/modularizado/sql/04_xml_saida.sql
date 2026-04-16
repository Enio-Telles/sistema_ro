/*
===============================================================================
MÓDULO 04 - XML DE SAÍDA
-------------------------------------------------------------------------------
Objetivo
- Trazer o item do XML da saída para comparar quantidade e posição documental.

Granularidade
- 1 linha por chave de saída + item_xml_padrao.

Utilidade
- Este módulo não calcula valor.
- Ele funciona como prova auxiliar para alinhamento entre item do SPED e item do XML.
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
        c100.chv_nfe AS chave_saida
    FROM sped.reg_c176 c176
    JOIN ARQUIVOS_VALIDOS arq
      ON c176.reg_0000_id = arq.reg_0000_id
    JOIN sped.reg_c100 c100
      ON c176.reg_c100_id = c100.id
     AND c100.reg_0000_id = arq.reg_0000_id
),
CHAVES_SAIDA AS (
    SELECT DISTINCT chave_saida AS chave_acesso
    FROM SAIDAS_RESSARCIMENTO
    WHERE chave_saida IS NOT NULL
),
XML_SAIDA_BASE AS (
    SELECT
        nfe_sai.chave_acesso,
        nfe_sai.seq_nitem,
        nfe_sai.prod_nitem,
        COALESCE(nfe_sai.prod_nitem, nfe_sai.seq_nitem) AS item_xml_padrao,
        nfe_sai.prod_qcom AS qcom_saida,
        ROW_NUMBER() OVER (
            PARTITION BY nfe_sai.chave_acesso, COALESCE(nfe_sai.prod_nitem, nfe_sai.seq_nitem)
            ORDER BY NVL(nfe_sai.prod_nitem, -1) DESC, NVL(nfe_sai.seq_nitem, -1) DESC
        ) AS rn
    FROM bi.fato_nfe_detalhe nfe_sai
    JOIN CHAVES_SAIDA cs
      ON nfe_sai.chave_acesso = cs.chave_acesso
),
XML_SAIDA AS (
    SELECT
        chave_acesso,
        seq_nitem,
        prod_nitem,
        item_xml_padrao,
        qcom_saida
    FROM XML_SAIDA_BASE
    WHERE rn = 1
)
SELECT *
FROM XML_SAIDA
ORDER BY chave_acesso, item_xml_padrao;
