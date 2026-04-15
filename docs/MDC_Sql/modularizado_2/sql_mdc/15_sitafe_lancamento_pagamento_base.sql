/*
===============================================================================
MDC 15 - SITAFE / LANÇAMENTO / PAGAMENTO / MERCADORIA
-------------------------------------------------------------------------------
Objetivo
- Trazer a camada financeira do Fronteira: guia, situação, receita, produto
  estadual e crédito/debito por item.
- Base necessária para a trilha "fronteira_completo" e para análises de lastro.

Granularidade
- 1 linha por item de lançamento associado à nota.
===============================================================================
*/
SELECT
    nl.it_nu_identificacao_nf,
    nl.it_nu_guia_lancamento,
    nl.it_da_entrada,
    nl.it_co_comando,
    nl.it_nu_cnpj_cpf_destino_nf,
    nl.it_nu_identificacao_ndf,
    lanc.it_co_receita,
    lanc.it_va_principal_original,
    lanc.it_va_total_pgto_efetuado,
    lanc.it_co_situacao_lancamento,
    li.it_co_produto,
    li.it_vl_merc_item,
    li.it_vl_merc_bc_item,
    li.it_aliq_item,
    li.it_vl_tot_debito_item,
    li.it_vl_credito_rateio,
    li.it_vl_icms_recolher,
    merc.it_pc_aliquota_interna,
    merc.it_pc_aliquota_origem,
    merc.it_convenio,
    merc.it_pc_agregacao_interna,
    merc.it_in_pgto_saida,
    merc.it_boletim_pauta,
    merc.it_in_isento_icms,
    merc.it_passe_fiscal,
    merc.it_in_combustivel,
    merc.it_in_produto_st,
    merc.it_in_cest_st,
    merc.it_pc_interna,
    prod.it_no_produto
FROM sitafe.sitafe_nf_lancamento nl
LEFT JOIN sitafe.sitafe_lancamento lanc
       ON lanc.it_nu_guia_lancamento = nl.it_nu_guia_lancamento
LEFT JOIN sitafe.sitafe_lancamento_item li
       ON li.it_nu_identificacao_ndf = nl.it_nu_identificacao_ndf
LEFT JOIN sitafe.sitafe_mercadoria merc
       ON merc.it_co_sefin = li.it_co_produto
LEFT JOIN sitafe.sitafe_produto_sefin prod
       ON prod.it_co_sefin = li.it_co_produto
WHERE nl.it_nu_identificacao_nf = :IDENT_NF;
