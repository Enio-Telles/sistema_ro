/*
===============================================================================
MÓDULO 05 - ITENS CANDIDATOS DA NOTA DE ENTRADA
-------------------------------------------------------------------------------
Objetivo
- Abrir todos os itens da nota de entrada informada em CHV_NFE_ULT_E.
- Trazer metadados do item no SPED e no cadastro 0200.

Granularidade
- 1 linha por item candidato da nota de entrada.

Leitura de negócio
- Este módulo não decide qual item é o correto.
- Ele apenas monta o universo de candidatos sobre o qual o score será aplicado.
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
    SELECT DISTINCT c176.chave_nfe_ult AS chave_nfe_ultima_entrada
    FROM sped.reg_c176 c176
    JOIN ARQUIVOS_VALIDOS arq
      ON c176.reg_0000_id = arq.reg_0000_id
    WHERE c176.chave_nfe_ult IS NOT NULL
),
PRODUTOS_ULTIMA_EFD AS (
    SELECT
        r0200.reg_0000_id,
        r0200.cod_item,
        MAX(r0200.cod_barra) AS cod_barra,
        MAX(r0200.descr_item) AS descr_item,
        MAX(r0200.cod_ncm) AS cod_ncm,
        MAX(r0200.cest) AS cest
    FROM sped.reg_0200 r0200
    JOIN ARQUIVOS_ULTIMA_EFD_PERIODO arq
      ON r0200.reg_0000_id = arq.reg_0000_id
    GROUP BY r0200.reg_0000_id, r0200.cod_item
),
ITENS_ENTRADA_SPED_BASE AS (
    SELECT
        c100_in.chv_nfe,
        c100_in.reg_0000_id,
        c170_in.cod_item,
        c170_in.num_item AS num_item_ult_entr_candidato,
        c170_in.descr_compl AS descr_compl_entrada_sped,
        c170_in.qtd AS qtd_item_entrada_sped,
        p_in.cod_barra AS cod_barra_entrada_sped,
        p_in.descr_item AS descr_item_entrada_sped,
        p_in.cod_ncm AS cod_ncm_entrada_sped,
        p_in.cest AS cest_entrada_sped
    FROM SAIDAS_RESSARCIMENTO ce
    JOIN sped.reg_c100 c100_in
      ON c100_in.chv_nfe = ce.chave_nfe_ultima_entrada
    JOIN ARQUIVOS_ULTIMA_EFD_PERIODO arq_ref
      ON c100_in.reg_0000_id = arq_ref.reg_0000_id
    JOIN sped.reg_c170 c170_in
      ON c170_in.reg_c100_id = c100_in.id
     AND c170_in.reg_0000_id = c100_in.reg_0000_id
    LEFT JOIN PRODUTOS_ULTIMA_EFD p_in
      ON p_in.reg_0000_id = c170_in.reg_0000_id
     AND p_in.cod_item = c170_in.cod_item
)
SELECT *
FROM ITENS_ENTRADA_SPED_BASE
ORDER BY chv_nfe, num_item_ult_entr_candidato;
