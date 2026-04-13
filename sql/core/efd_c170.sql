-- Core SQL template: EFD C170
-- Objetivo: extrair itens da EFD preservando chaves físicas e campos fiscais mínimos.

SELECT
    r170.id AS reg_c170_id,
    r170.arquivo_id,
    r170.efd_resumo_id,
    r170.dt_doc,
    r170.dt_e_s,
    r170.chave_acesso,
    r170.num_doc,
    r170.num_item,
    r170.codigo_produto,
    r170.descricao_produto,
    r170.qtd,
    r170.unid,
    r170.vl_item,
    r170.cfop,
    r170.cst_icms,
    r170.vl_bc_icms,
    r170.aliq_icms,
    r170.vl_icms,
    r170.vl_bc_icms_st,
    r170.vl_icms_st
FROM efd_regc170 r170
WHERE r170.dt_doc BETWEEN :periodo_inicio AND :periodo_fim
  AND EXISTS (
      SELECT 1
      FROM efd_reg0000 r0000
      WHERE r0000.arquivo_id = r170.arquivo_id
        AND regexp_replace(r0000.cnpj, '[^0-9]', '') = :cnpj
  );
