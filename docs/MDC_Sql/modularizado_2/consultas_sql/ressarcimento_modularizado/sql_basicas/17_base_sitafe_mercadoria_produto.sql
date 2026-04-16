/* ============================================================================
   sql_basicas/17_base_sitafe_mercadoria_produto.sql
   ----------------------------------------------------------------------------
   Objetivo:
   - consolidar o item fiscal do SITAFE com o item do lançamento,
     a mercadoria/classificação estadual e a descrição do produto Sefin.

   Uso recomendado:
   - trilhas que precisem abrir o detalhe do Fronteira por item;
   - comparação entre item documental da NF-e e produto estadual do SITAFE.

   Observação:
   - o vínculo principal ocorre por co_sefin;
   - validar vigência e granularidade local antes de usar em produção.
============================================================================ */

WITH item_sitafe AS (
    SELECT
        it.it_nu_chave_acesso AS chave_acesso,
        it.it_nu_item,
        it.it_no_produto,
        it.it_co_cfop,
        it.it_co_ncm,
        it.it_un_comercial,
        it.it_qt_comercial,
        it.it_va_unitario_com,
        it.it_va_produto,
        it.it_va_frete,
        it.it_va_desconto,
        it.it_va_outro,
        it.it_va_seguro,
        it.it_va_bc,
        it.it_pc_icms,
        it.it_va_icms,
        it.it_va_bc_st,
        it.it_va_icms_st,
        it.it_co_sefin
    FROM sitafe.sitafe_nfe_item it
),
lanc_item AS (
    SELECT
        li.it_nu_identificacao_ndf,
        li.it_co_produto,
        li.it_vl_merc_item,
        li.it_vl_merc_bc_item,
        li.it_aliq_item,
        li.it_vl_tot_debito_item,
        li.it_vl_credito_rateio,
        li.it_vl_icms_recolher
    FROM sitafe.sitafe_lancamento_item li
),
mercadoria AS (
    SELECT
        m.it_co_sefin,
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
    FROM sitafe.sitafe_mercadoria m
),
produto_sefin AS (
    SELECT
        p.it_co_sefin,
        p.it_no_produto
    FROM sitafe.sitafe_produto_sefin p
)
SELECT
    i.chave_acesso,
    i.it_nu_item,
    i.it_no_produto,
    i.it_co_cfop,
    i.it_co_ncm,
    i.it_un_comercial,
    i.it_qt_comercial,
    i.it_va_unitario_com,
    i.it_va_produto,
    i.it_va_frete,
    i.it_va_desconto,
    i.it_va_outro,
    i.it_va_seguro,
    i.it_va_bc,
    i.it_pc_icms,
    i.it_va_icms,
    i.it_va_bc_st,
    i.it_va_icms_st,
    i.it_co_sefin,
    li.it_nu_identificacao_ndf,
    li.it_vl_merc_item,
    li.it_vl_merc_bc_item,
    li.it_aliq_item,
    li.it_vl_tot_debito_item,
    li.it_vl_credito_rateio,
    li.it_vl_icms_recolher,
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
    m.it_pc_interna,
    ps.it_no_produto AS nome_produto_sefin
FROM item_sitafe i
LEFT JOIN mercadoria m
  ON m.it_co_sefin = i.it_co_sefin
LEFT JOIN produto_sefin ps
  ON ps.it_co_sefin = i.it_co_sefin
LEFT JOIN lanc_item li
  ON li.it_co_produto = i.it_co_sefin;
