/*
===============================================================================
MUDANÇA DE TRIBUTAÇÃO ST - MÓDULO 23
ENTRADAS ESCRITURADAS (C100 + C170)
-------------------------------------------------------------------------------
Objetivo:
- abrir as entradas do item em base documental limpa;
- fornecer a trilha da última entrada anterior ao inventário.

Observação:
- este módulo ainda não distingue, por si só, compra com ST, antecipação ou
  regime normal. Ele é prova documental de entrada, não classificação jurídica.
===============================================================================
*/
WITH arquivos_validos AS (
    SELECT * FROM ARQUIVOS_RANKING WHERE rn = 1
),
nsu_documental AS (
    SELECT * FROM nsu_documental_base
)
SELECT
    NVL(nd.nsu, 0) AS nsu,
    c100.chv_nfe AS chave_acesso,
    nd.co_uf_emit,
    nd.co_uf_dest,
    REPLACE(REPLACE(REPLACE(LTRIM(c170.cod_item, '0'), ' ', ''), '.', ''), '-', '') AS cod_item_normalizado,
    c170.cod_item,
    c100.dt_doc,
    c170.unid,
    c170.cfop,
    (c170.vl_item - NVL(c170.vl_desc, 0)) AS vl_total_item,
    c170.qtd,
    CASE
        WHEN c170.qtd > 0 THEN (c170.vl_item - NVL(c170.vl_desc, 0)) / c170.qtd
        ELSE 0
    END AS vl_unit_entrada
FROM sped.reg_c170 c170
JOIN sped.reg_c100 c100
  ON c170.reg_c100_id = c100.id
 AND c170.reg_0000_id = c100.reg_0000_id
JOIN arquivos_validos av
  ON c170.reg_0000_id = av.reg_0000_id
LEFT JOIN nsu_documental nd
  ON nd.chave_acesso = c100.chv_nfe
WHERE SUBSTR(c170.cfop, 1, 1) IN ('1', '2', '3')
  AND c100.ind_oper = '0'
  AND c100.cod_sit = '00'
  AND (:cod_item IS NULL OR REPLACE(REPLACE(REPLACE(LTRIM(c170.cod_item, '0'), ' ', ''), '.', ''), '-', '') = :cod_item);
