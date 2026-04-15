/*
===============================================================================
MDC 14 - SITAFE / NOTA / ITEM / CÁLCULO DE FRONTEIRA
-------------------------------------------------------------------------------
Objetivo
- Unificar a camada documental e itemizada do Fronteira.
- Base comum do dossiê Fronteira, da trilha pós-2022 e da conciliação completa.

Granularidade
- 1 linha por item da nota no SITAFE, com cálculo se existir.
===============================================================================
*/
SELECT
    nf.it_nu_comando,
    nf.it_nu_identificacao_nf,
    nf.it_nu_identificao_nf_e AS chave_acesso,
    nf.it_da_entrada,
    nf.it_nu_cnpj_emitente_nf,
    nf.it_nucnpj_cpf_destino_nf,
    nf.it_co_uf_origem,
    nf.it_co_uf_destino,
    nf.it_va_bc_icms,
    nf.it_va_icms,
    nf.it_va_bc_icms_st,
    nf.it_va_icms_st,
    nf.it_va_nf,
    item.it_nu_item,
    item.it_no_produto,
    item.it_co_cfop,
    item.it_co_ncm,
    item.it_un_comercial,
    item.it_qt_comercial,
    item.it_va_unitario_com,
    item.it_va_produto,
    item.it_va_frete,
    item.it_va_desconto,
    item.it_va_outro,
    item.it_va_seguro,
    item.it_va_bc,
    item.it_pc_icms,
    item.it_va_icms,
    item.it_va_bc_st,
    item.it_va_icms_st,
    item.it_co_sefin,
    calc.it_co_rotina_calculo,
    calc.it_co_sefin AS calc_co_sefin,
    calc.it_vl_icms AS calc_vl_icms
FROM sitafe.sitafe_nota_fiscal nf
LEFT JOIN sitafe.sitafe_nfe_item item
       ON item.it_nu_chave_acesso = nf.it_nu_identificao_nf_e
LEFT JOIN sitafe.sitafe_nfe_calculo_item calc
       ON calc.it_nu_chave_acesso = item.it_nu_chave_acesso
      AND calc.it_nu_item         = item.it_nu_item
WHERE (
        nf.it_nu_identificao_nf_e = :CHAVE_ACESSO
     OR nf.it_nu_comando          = :NU_COMANDO
      )
  AND (
        :CNPJ_CPF IS NULL
        OR nf.it_nucnpj_cpf_destino_nf = REGEXP_REPLACE(TRIM(:CNPJ_CPF), '[^0-9]', '')
        OR nf.it_nu_cnpj_emitente_nf   = REGEXP_REPLACE(TRIM(:CNPJ_CPF), '[^0-9]', '')
      );
