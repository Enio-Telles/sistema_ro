-- Core SQL template: Bloco H / inventário

SELECT
    h.id AS bloco_h_id,
    h.arquivo_id,
    h.dt_inv,
    h.cod_item,
    h.unid,
    h.qtd,
    h.vl_unit,
    h.vl_item,
    h.ind_prop,
    h.cod_part,
    h.txt_compl
FROM efd_bloco_h h
WHERE EXISTS (
    SELECT 1
    FROM efd_reg0000 r0000
    WHERE r0000.arquivo_id = h.arquivo_id
      AND regexp_replace(r0000.cnpj, '[^0-9]', '') = :cnpj
)
  AND h.dt_inv BETWEEN :periodo_inicio AND :periodo_fim;
