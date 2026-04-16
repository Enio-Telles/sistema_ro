/*
===============================================================================
MDC 10 - APURAÇÃO EFD (E110 / E210)
-------------------------------------------------------------------------------
Objetivo
- Consolidar a apuração periódica do ICMS próprio e do ICMS-ST.
- Base para relatórios EFD Master, fechamento com ressarcimento e confronto com
  ajustes.

Granularidade
- 1 linha por período + registro de apuração.
===============================================================================
*/
SELECT
    t.co_cnpj_cpf_declarante,
    t.da_referencia,
    t.registro,
    t.uf_st,
    t.vl_tot_debitos,
    t.vl_aj_debitos,
    t.vl_tot_aj_debitos,
    t.vl_estornos_cred,
    t.vl_tot_creditos,
    t.vl_aj_creditos,
    t.vl_tot_aj_creditos,
    t.vl_estornos_deb,
    t.vl_sld_credor_ant,
    t.vl_sld_apurado,
    t.vl_tot_ded,
    t.vl_recolher,
    t.vl_sld_credor_transportar,
    t.vl_deb_esp
FROM bi.fato_efd_sumarizada t
WHERE t.co_cnpj_cpf_declarante = REGEXP_REPLACE(TRIM(:CNPJ_CPF), '[^0-9]', '')
  AND t.da_referencia BETWEEN TO_DATE(:DATA_INICIAL, 'DD/MM/YYYY')
                           AND TO_DATE(:DATA_FINAL, 'DD/MM/YYYY')
  AND (
       t.registro = 'E110'
       OR (t.registro = 'E210' AND NVL(t.uf_st, 'RO') = 'RO')
  );
