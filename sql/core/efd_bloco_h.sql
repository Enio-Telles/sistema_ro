-- efd_bloco_h.sql
-- grupo: core
-- dominio: Bloco H
-- objetivo: inventário bloco H detalhado
-- parametros esperados: cnpj, periodo_inicio, periodo_fim
-- observacao: base do estoque final declarado
-- status: template curado para implementação no novo projeto
-- regra: selecionar apenas colunas necessárias e preservar chaves físicas

/* :cnpj :periodo_inicio :periodo_fim */
WITH arquivos_validos AS (
    SELECT reg_0000_id, dt_ini
    FROM (
        SELECT r.id AS reg_0000_id,
               r.dt_ini,
               ROW_NUMBER() OVER (
                   PARTITION BY r.cnpj, r.dt_ini, NVL(r.dt_fin, r.dt_ini)
                   ORDER BY r.data_entrega DESC, r.id DESC
               ) rn
        FROM sped.reg_0000 r
        WHERE r.cnpj = REGEXP_REPLACE(TRIM(:cnpj), '[^0-9]', '')
          AND r.dt_ini BETWEEN TO_DATE(:periodo_inicio, 'YYYY-MM-DD')
                           AND ADD_MONTHS(TO_DATE(:periodo_fim, 'YYYY-MM-DD'), 2)
    )
    WHERE rn = 1
)
SELECT
    a.dt_ini AS efd_ref,
    TO_DATE(h005.dt_inv, 'DDMMYYYY') AS dt_inv,
    TO_DATE(h005.dt_inv, 'DDMMYYYY') AS dt_doc, /* alias nativo para o pipeline de estoques */
    h005.mot_inv,
    h010.id AS reg_h010_id,
    h010.cod_item,
    h010.unid,
    h010.qtd,
    h010.vl_item,
    h010.vl_unit,
    r0200.descr_item,
    r0200.cod_ncm,
    r0200.cest,
    h020.reg      AS reg_h020,
    h020.bc_icms  AS bc_icms_h020,
    h020.cst_icms AS cst_icms_h020,
    h020.vl_icms  AS vl_icms_h020
FROM sped.reg_h010 h010
JOIN arquivos_validos a
  ON a.reg_0000_id = h010.reg_0000_id
LEFT JOIN sped.reg_h005 h005
       ON h005.reg_0000_id = h010.reg_0000_id
LEFT JOIN sped.reg_h020 h020
       ON h020.reg_h010_id = h010.id
      AND h020.reg_0000_id = h010.reg_0000_id
LEFT JOIN sped.reg_0200 r0200
       ON r0200.reg_0000_id = h010.reg_0000_id
      AND r0200.cod_item    = h010.cod_item;
