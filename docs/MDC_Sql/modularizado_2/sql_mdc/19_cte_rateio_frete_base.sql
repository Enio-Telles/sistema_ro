/*
===============================================================================
MDC 19 - CT-E / RATEIO DE FRETE PARA NF-E
-------------------------------------------------------------------------------
Objetivo
- Reunir a base mínima da trilha histórica pré-2022 que rateia frete e ICMS de
  frete do CT-e sobre a NF-e.
- Serve também para perícia de composição de custo em ressarcimento.

Granularidade
- 1 linha por vínculo CT-e x NF-e, com valor total do conhecimento.
===============================================================================
*/
SELECT
    ctei.it_nu_chave_cte,
    ctei.it_nu_chave_nfe,
    ctei.it_nu_doc,
    ctei.it_inf_tipo,
    cte.it_tp_frete,
    cte.it_va_total_frete,
    cte.it_va_valor_icms,
    nf.chave_acesso,
    nf.prod_nitem,
    nf.tot_vprod,
    nf.tot_vfrete,
    nf.tot_vseg,
    nf.tot_voutro,
    nf.tot_vdesc,
    nf.tot_vipi,
    nf.tot_vst,
    nf.prod_vprod,
    nf.prod_vfrete,
    nf.prod_vseg,
    nf.prod_voutro,
    nf.prod_vdesc,
    nf.ipi_vipi,
    nf.icms_vicmsst,
    nf.co_destinatario
FROM sitafe.sitafe_cte_itens ctei
LEFT JOIN sitafe.sitafe_cte cte
       ON cte.it_nu_chave_acesso = ctei.it_nu_chave_cte
LEFT JOIN bi.fato_nfe_detalhe nf
       ON nf.chave_acesso = ctei.it_nu_chave_nfe
WHERE (:CHAVE_ACESSO IS NULL OR ctei.it_nu_chave_nfe = :CHAVE_ACESSO)
  AND nf.seq_nitem = '1';
