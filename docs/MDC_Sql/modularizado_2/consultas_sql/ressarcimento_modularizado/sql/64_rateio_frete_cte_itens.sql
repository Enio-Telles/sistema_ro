/*
===============================================================================
MÓDULO 64 - RATEIO DE FRETE DA NOTA PARA O ITEM
-------------------------------------------------------------------------------
Objetivo
- Distribuir para os itens o frete e o ICMS do frete já rateados na nota.
===============================================================================
*/

WITH rateio_nf AS (
    SELECT * FROM rateio_frete_cte_notas
)
SELECT
    rn.it_nu_chave_cte,
    nf.chave_acesso,
    nf.prod_nitem,
    NVL(nf.tot_vprod,0)
      + NVL(nf.tot_vfrete,0)
      + NVL(nf.tot_vseg,0)
      + NVL(nf.tot_voutro,0)
      - NVL(nf.tot_vdesc,0)
      + NVL(nf.tot_vipi,0)
      + NVL(nf.tot_vst,0) AS vl_nota,
    NVL(nf.prod_vprod,0)
      + NVL(nf.prod_vfrete,0)
      + NVL(nf.prod_vseg,0)
      + NVL(nf.prod_voutro,0)
      - NVL(nf.prod_vdesc,0)
      + NVL(nf.ipi_vipi,0)
      + NVL(nf.icms_vicmsst,0) AS vl_item,
    rn.rateio_frete_nf,
    rn.rateio_icms_frete_nf,
    ROUND(
        (
            NVL(nf.prod_vprod,0)
          + NVL(nf.prod_vfrete,0)
          + NVL(nf.prod_vseg,0)
          + NVL(nf.prod_voutro,0)
          - NVL(nf.prod_vdesc,0)
          + NVL(nf.ipi_vipi,0)
          + NVL(nf.icms_vicmsst,0)
        ) / NULLIF(
            NVL(nf.tot_vprod,0)
          + NVL(nf.tot_vfrete,0)
          + NVL(nf.tot_vseg,0)
          + NVL(nf.tot_voutro,0)
          - NVL(nf.tot_vdesc,0)
          + NVL(nf.tot_vipi,0)
          + NVL(nf.tot_vst,0), 0
        ) * rn.rateio_frete_nf,
        4
    ) AS rateio_frete_nf_item,
    ROUND(
        (
            NVL(nf.prod_vprod,0)
          + NVL(nf.prod_vfrete,0)
          + NVL(nf.prod_vseg,0)
          + NVL(nf.prod_voutro,0)
          - NVL(nf.prod_vdesc,0)
          + NVL(nf.ipi_vipi,0)
          + NVL(nf.icms_vicmsst,0)
        ) / NULLIF(
            NVL(nf.tot_vprod,0)
          + NVL(nf.tot_vfrete,0)
          + NVL(nf.tot_vseg,0)
          + NVL(nf.tot_voutro,0)
          - NVL(nf.tot_vdesc,0)
          + NVL(nf.tot_vipi,0)
          + NVL(nf.tot_vst,0), 0
        ) * rn.rateio_icms_frete_nf,
        4
    ) AS rateio_icms_frete_nf_item
FROM rateio_nf rn
JOIN bi.fato_nfe_detalhe nf
  ON rn.it_nu_chave_nfe = nf.chave_acesso
ORDER BY rn.it_nu_chave_cte, nf.chave_acesso, nf.prod_nitem;
