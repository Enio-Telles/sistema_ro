/*
===============================================================================
CONSULTA BÁSICA COMPARTILHADA 03
ABERTURA DOCUMENTAL MÍNIMA DE ITENS (C100/C170)
-------------------------------------------------------------------------------
Objetivo:
- disponibilizar uma base única de documentos item a item;
- ser consumida tanto pela lógica do C176 quanto pela trilha de inventário.
===============================================================================
*/
WITH arquivos_validos AS (
    SELECT * FROM (
        SELECT
            r.id AS reg_0000_id,
            r.cnpj,
            r.dt_ini,
            ROW_NUMBER() OVER (
                PARTITION BY r.cnpj, r.dt_ini, NVL(r.dt_fin, r.dt_ini)
                ORDER BY r.data_entrega DESC, r.id DESC
            ) AS rn
        FROM sped.reg_0000 r
        WHERE r.cnpj = :CNPJ
          AND r.data_entrega <= NVL(TO_DATE(:data_limite_processamento, 'DD/MM/YYYY'), TRUNC(SYSDATE))
    )
    WHERE rn = 1
)
SELECT
    c100.reg_0000_id,
    c100.id AS reg_c100_id,
    c170.id AS reg_c170_id,
    c100.ind_oper,
    c100.cod_sit,
    c100.chv_nfe,
    c100.num_doc,
    c100.dt_doc,
    c170.num_item,
    c170.cod_item,
    REPLACE(REPLACE(REPLACE(LTRIM(c170.cod_item, '0'), ' ', ''), '.', ''), '-', '') AS cod_item_normalizado,
    c170.cfop,
    c170.unid,
    c170.qtd,
    c170.vl_item,
    c170.vl_desc,
    (c170.vl_item - NVL(c170.vl_desc, 0)) AS vl_item_liquido,
    CASE
        WHEN NVL(c170.qtd, 0) <> 0 THEN (c170.vl_item - NVL(c170.vl_desc, 0)) / c170.qtd
        ELSE NULL
    END AS vl_unit_liquido
FROM sped.reg_c100 c100
JOIN sped.reg_c170 c170
  ON c170.reg_c100_id = c100.id
 AND c170.reg_0000_id = c100.reg_0000_id
JOIN arquivos_validos av
  ON av.reg_0000_id = c100.reg_0000_id;
