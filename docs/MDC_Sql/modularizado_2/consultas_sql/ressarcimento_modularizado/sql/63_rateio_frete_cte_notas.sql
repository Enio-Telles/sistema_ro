/*
===============================================================================
MÓDULO 63 - RATEIO DE FRETE CTE -> NOTA
-------------------------------------------------------------------------------
Objetivo
- Localizar os CTe vinculados às NF-e analisadas.
- Repartir o frete total e o ICMS do frete entre as notas do conjunto.

Leitura crítica
- Trata-se de metodologia operacional de rateio, não de comando literal da
  IN 22/2018.
===============================================================================
*/

WITH chaves_alvo AS (
    SELECT chave_acesso
    FROM tabela_chaves_alvo
),
cte_vinculado AS (
    SELECT
        c.chave_acesso AS chave_nfe,
        cte_itens.it_nu_chave_cte AS chave_cte
    FROM chaves_alvo c
    JOIN sitafe.sitafe_cte_itens cte_itens
      ON c.chave_acesso = cte_itens.it_nu_chave_nfe
),
rateio_nf AS (
    SELECT
        cte_itens.it_nu_chave_cte,
        cte_itens.it_nu_chave_nfe,
        cte.it_tp_frete,
        cte.it_va_total_frete AS total_frete,
        cte.it_va_valor_icms  AS icms_frete,
        cte_itens.it_nu_doc,
        cte_itens.it_inf_tipo,
        ( NVL(nfe.tot_vprod,0)
        + NVL(nfe.tot_vfrete,0)
        + NVL(nfe.tot_vseg,0)
        + NVL(nfe.tot_voutro,0)
        - NVL(nfe.tot_vdesc,0)
        + NVL(nfe.tot_vipi,0)
        + NVL(nfe.tot_vst,0)) AS bc_rateio_fob,
        SUM(
            NVL(nfe.tot_vprod,0)
          + NVL(nfe.tot_vfrete,0)
          + NVL(nfe.tot_vseg,0)
          + NVL(nfe.tot_voutro,0)
          - NVL(nfe.tot_vdesc,0)
          + NVL(nfe.tot_vipi,0)
          + NVL(nfe.tot_vst,0)
        ) OVER (PARTITION BY cte_itens.it_nu_chave_cte) AS total_nf_cte,
        ROUND(
            (
                NVL(nfe.tot_vprod,0)
              + NVL(nfe.tot_vfrete,0)
              + NVL(nfe.tot_vseg,0)
              + NVL(nfe.tot_voutro,0)
              - NVL(nfe.tot_vdesc,0)
              + NVL(nfe.tot_vipi,0)
              + NVL(nfe.tot_vst,0)
            ) / NULLIF(
                SUM(
                    NVL(nfe.tot_vprod,0)
                  + NVL(nfe.tot_vfrete,0)
                  + NVL(nfe.tot_vseg,0)
                  + NVL(nfe.tot_voutro,0)
                  - NVL(nfe.tot_vdesc,0)
                  + NVL(nfe.tot_vipi,0)
                  + NVL(nfe.tot_vst,0)
                ) OVER (PARTITION BY cte_itens.it_nu_chave_cte), 0
            ),
            5
        ) AS perc_nf_no_cte
    FROM sitafe.sitafe_cte_itens cte_itens
    LEFT JOIN bi.fato_nfe_detalhe nfe
      ON nfe.chave_acesso = cte_itens.it_nu_chave_nfe
    LEFT JOIN sitafe.sitafe_cte cte
      ON cte.it_nu_chave_acesso = cte_itens.it_nu_chave_cte
    WHERE cte_itens.it_nu_chave_cte IN (SELECT chave_cte FROM cte_vinculado)
      AND nfe.seq_nitem = 1
      AND SUBSTR(cte.it_nu_cnpj_tomador, 1, 8) = SUBSTR(nfe.co_destinatario, 1, 8)
)
SELECT
    r.*,
    ROUND(r.total_frete * r.perc_nf_no_cte, 3) AS rateio_frete_nf,
    ROUND(r.icms_frete  * r.perc_nf_no_cte, 3) AS rateio_icms_frete_nf
FROM rateio_nf r
ORDER BY r.it_nu_chave_cte, r.it_nu_chave_nfe;
