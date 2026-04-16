/*
===============================================================================
CONSULTA BÁSICA COMPARTILHADA 02
BASE CADASTRAL DE PRODUTOS (REG_0200)
-------------------------------------------------------------------------------
Objetivo:
- expor descrição, GTIN, NCM e CEST do cadastro de itens da EFD;
- servir tanto ao vínculo do C176 quanto ao inventário de mudança de tributação.
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
    r0200.reg_0000_id,
    r0200.cod_item,
    REPLACE(REPLACE(REPLACE(LTRIM(r0200.cod_item, '0'), ' ', ''), '.', ''), '-', '') AS cod_item_normalizado,
    r0200.descr_item,
    r0200.cod_barra,
    r0200.cod_ncm,
    r0200.cest,
    av.dt_ini AS periodo_efd
FROM sped.reg_0200 r0200
JOIN arquivos_validos av
  ON av.reg_0000_id = r0200.reg_0000_id;
