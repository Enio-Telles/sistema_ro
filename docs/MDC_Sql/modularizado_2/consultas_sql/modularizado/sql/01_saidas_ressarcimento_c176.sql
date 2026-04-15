/*
===============================================================================
MÓDULO 01 - SAÍDAS COM RESSARCIMENTO (C176)
-------------------------------------------------------------------------------
Objetivo
- Isolar a base de itens de saída que já possuem detalhamento em C176.

Granularidade
- 1 linha por item de saída escriturado em C176.

Por que este módulo existe
- O C176 é o ponto de partida documental do ressarcimento.
- A rotina não "descobre" ressarcimento sozinha; ela audita o que foi declarado.

Risco fiscal
- Se o C176 estiver errado, a análise precisa apontar a inconsistência, e não
  simplesmente reproduzi-la.
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
        arq.reg_0000_id,
        arq.dt_ini AS comp_efd,
        arq.cod_fin_efd,
        c100.chv_nfe AS chave_saida,
        c100.num_doc AS num_nf_saida,
        c100.dt_doc,
        c170.num_item AS num_item_saida,
        c170.cod_item,
        c170.descr_compl AS descricao_item,
        c170.qtd AS qtd_saida_sped,
        c170.vl_item AS vl_total_item_saida,
        c170.vl_icms,
        c176.cod_mot_res,
        c176.chave_nfe_ult AS chave_nfe_ultima_entrada,
        c176.dt_ult_e,
        c176.vl_unit_ult_e AS vl_unit_bc_st_entrada,
        c176.vl_unit_icms_ult_e AS vl_unit_icms_proprio_entrada,
        c176.vl_unit_res AS vl_unit_ressarcimento_st
    FROM sped.reg_c176 c176
    JOIN ARQUIVOS_VALIDOS arq
      ON c176.reg_0000_id = arq.reg_0000_id
    JOIN sped.reg_c100 c100
      ON c176.reg_c100_id = c100.id
     AND c100.reg_0000_id = arq.reg_0000_id
    JOIN sped.reg_c170 c170
      ON c176.reg_c170_id = c170.id
     AND c170.reg_0000_id = arq.reg_0000_id
)
SELECT *
FROM SAIDAS_RESSARCIMENTO
ORDER BY comp_efd, chave_saida, num_item_saida;
