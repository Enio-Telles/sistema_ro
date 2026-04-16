/* ============================================================================
   103_cruzamento_nfe_sitafe_fronteira_completo.sql
   ----------------------------------------------------------------------------
   Objetivo:
   - unir a origem documental do BI ao bloco SITAFE nota/lançamento/item;
   - calcular campos derivados mínimos para a leitura gerencial.

   Dependências lógicas:
   - 101_base_sitafe_nota_lancamento_fronteira_completo.sql
   - 102_base_sitafe_item_mercadoria_fronteira_completo.sql
============================================================================ */

WITH lanc AS (
    SELECT * FROM base_sitafe_nota_lancamento_fronteira_completo
),
item AS (
    SELECT * FROM base_sitafe_item_mercadoria_fronteira_completo
)
SELECT
    lanc.chave_acesso,
    lanc.nota,
    lanc.cnpj_emit,
    lanc.nome_emit,
    lanc.uf_emitente,
    lanc.emissao,
    TO_DATE(lanc.it_da_entrada, 'YYYYMMDD') AS entrada,
    lanc.it_co_comando AS comando,
    item.prod_nitem,
    item.prod_xprod,
    item.co_cfop,
    item.ncm,
    item.prod_ucom,
    item.prod_qcom,
    item.prod_vuncom,
    item.prod_vprod,
    item.prod_vfrete,
    item.prod_vdesc,
    item.prod_voutro,
    item.prod_vseg,
    (item.prod_vprod + item.prod_vfrete - item.prod_vdesc + item.prod_voutro + item.prod_vseg) AS total_produto,
    item.icms_vbc,
    item.icms_picms,
    item.icms_vicms,
    item.icms_vbcst,
    item.icms_vicmsst,
    lanc.it_co_receita AS receita,
    lanc.it_nu_guia_lancamento AS guia,
    lanc.it_va_principal_original AS valor_devido,
    CASE
        WHEN lanc.it_co_receita IS NULL THEN 0
        ELSE lanc.it_va_total_pgto_efetuado
    END AS valor_pago,
    lanc.it_co_situacao_lancamento,
    item.co_sefin,
    item.nome_co_sefin,
    item.vl_merc,
    item.vl_bc_merc,
    item.aliq,
    item.vl_tot_deb,
    item.vl_tot_cred,
    item.vl_icms,
    item.it_pc_aliquota_interna,
    item.it_pc_aliquota_origem,
    item.it_convenio,
    item.it_pc_agregacao_interna,
    item.it_in_pgto_saida,
    item.it_boletim_pauta,
    item.it_in_isento_icms,
    item.it_passe_fiscal,
    item.it_in_combustivel,
    item.it_in_produto_st,
    item.it_in_cest_st,
    item.it_pc_interna
FROM lanc
JOIN item
  ON item.chave_acesso = lanc.chave_acesso
 AND item.it_nu_identificacao_ndf = lanc.it_nu_identificacao_ndf;
