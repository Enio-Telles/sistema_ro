-- Core SQL template: EFD REG 0200
-- Objetivo: cadastro de produto com descrição, NCM e unidade base.

SELECT
    r0200.id AS reg_0200_id,
    r0200.arquivo_id,
    r0200.cod_item,
    r0200.descr_item,
    r0200.cod_barra,
    r0200.cod_ncm,
    r0200.cod_gen,
    r0200.cod_lst,
    r0200.aliq_icms,
    r0200.unid_inv,
    r0200.cest,
    r0200.dt_ini,
    r0200.dt_fim
FROM efd_reg0200 r0200
WHERE EXISTS (
    SELECT 1
    FROM efd_reg0000 r0000
    WHERE r0000.arquivo_id = r0200.arquivo_id
      AND regexp_replace(r0000.cnpj, '[^0-9]', '') = :cnpj
);
