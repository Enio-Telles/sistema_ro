/*
===============================================================================
MDC 07 - RESSARCIMENTO DECLARADO (C176)
-------------------------------------------------------------------------------
Objetivo
- Consolidar a declaração do ressarcimento item a item.
- Esta é a base mínima comum das trilhas V4, pós-2022 e dos relatórios ligados
  a ressarcimento/apuração ST.

Granularidade
- 1 linha por item de saída com C176.
===============================================================================
*/
WITH arquivos_validos AS (
    SELECT reg_0000_id, dt_ini, cod_fin
    FROM (
        SELECT r.id AS reg_0000_id,
               r.dt_ini,
               r.cod_fin,
               ROW_NUMBER() OVER (
                   PARTITION BY r.cnpj, r.dt_ini, NVL(r.dt_fin, r.dt_ini)
                   ORDER BY r.data_entrega DESC, r.id DESC
               ) rn
        FROM sped.reg_0000 r
        WHERE r.cnpj = REGEXP_REPLACE(TRIM(:CNPJ_CPF), '[^0-9]', '')
          AND r.dt_ini BETWEEN TO_DATE(:DATA_INICIAL, 'DD/MM/YYYY')
                           AND TO_DATE(:DATA_FINAL, 'DD/MM/YYYY')
    )
    WHERE rn = 1
)
SELECT
    a.dt_ini         AS efd_ref,
    a.cod_fin        AS cod_fin_efd,
    c176.reg_0000_id,
    c100.id          AS reg_c100_id,
    c170.id          AS reg_c170_id,
    c100.chv_nfe     AS chave_saida,
    c100.num_doc     AS num_nf_saida,
    c100.dt_doc,
    c170.num_item    AS num_item_saida,
    c170.cod_item,
    c170.cfop,
    c170.qtd         AS qtd_saida,
    c176.cod_mot_res,
    c176.chave_nfe_ult,
    c176.dt_ult_e,
    c176.quant_ult_e,
    c176.vl_unit_ult_e,
    c176.vl_unit_icms_ult_e,
    c176.vl_unit_res
FROM sped.reg_c176 c176
JOIN arquivos_validos a ON a.reg_0000_id = c176.reg_0000_id
JOIN sped.reg_c100 c100 ON c100.id = c176.reg_c100_id
JOIN sped.reg_c170 c170 ON c170.id = c176.reg_c170_id;
