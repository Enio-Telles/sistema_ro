/* ============================================================================
   102_base_sitafe_item_mercadoria_fronteira_completo.sql
   ----------------------------------------------------------------------------
   Objetivo:
   - abrir o item fiscal do SITAFE por chave;
   - trazer o item do lançamento;
   - trazer a classificação estadual da mercadoria;
   - trazer a descrição do produto Sefin.

   Dependência lógica:
   - 101_base_sitafe_nota_lancamento_fronteira_completo.sql
============================================================================ */

WITH base_lancamento AS (
    SELECT * FROM base_sitafe_nota_lancamento_fronteira_completo
)
SELECT
    b.chave_acesso,
    b.it_nu_identificacao_ndf,
    i.it_nu_item AS prod_nitem,
    i.it_no_produto AS prod_xprod,
    i.it_co_cfop AS co_cfop,
    i.it_co_ncm AS ncm,
    i.it_un_comercial AS prod_ucom,
    i.it_qt_comercial AS prod_qcom,
    i.it_va_unitario_com AS prod_vuncom,
    i.it_va_produto AS prod_vprod,
    i.it_va_frete AS prod_vfrete,
    i.it_va_desconto AS prod_vdesc,
    i.it_va_outro AS prod_voutro,
    i.it_va_seguro AS prod_vseg,
    i.it_va_bc AS icms_vbc,
    i.it_pc_icms AS icms_picms,
    i.it_va_icms AS icms_vicms,
    i.it_va_bc_st AS icms_vbcst,
    i.it_va_icms_st AS icms_vicmsst,
    li.it_co_produto AS co_sefin,
    ps.it_no_produto AS nome_co_sefin,
    li.it_vl_merc_item AS vl_merc,
    li.it_vl_merc_bc_item AS vl_bc_merc,
    li.it_aliq_item AS aliq,
    li.it_vl_tot_debito_item AS vl_tot_deb,
    li.it_vl_credito_rateio AS vl_tot_cred,
    li.it_vl_icms_recolher AS vl_icms,
    m.it_pc_aliquota_interna,
    m.it_pc_aliquota_origem,
    m.it_convenio,
    m.it_pc_agregacao_interna,
    m.it_in_pgto_saida,
    m.it_boletim_pauta,
    m.it_in_isento_icms,
    m.it_passe_fiscal,
    m.it_in_combustivel,
    m.it_in_produto_st,
    m.it_in_cest_st,
    m.it_pc_interna
FROM base_lancamento b
JOIN sitafe.sitafe_nfe_item i
  ON i.it_nu_chave_acesso = b.chave_acesso
JOIN sitafe.sitafe_lancamento_item li
  ON li.it_nu_identificacao_ndf = b.it_nu_identificacao_ndf
 AND li.it_co_produto = i.it_co_sefin
JOIN sitafe.sitafe_mercadoria m
  ON m.it_co_sefin = li.it_co_produto
LEFT JOIN sitafe.sitafe_produto_sefin ps
  ON ps.it_co_sefin = li.it_co_produto;
