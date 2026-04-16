/* ============================================================================
   104_resultado_final_fronteira_completo.sql
   ----------------------------------------------------------------------------
   Objetivo:
   - produzir a visão final item a item da conciliação NFe x SITAFE/Fronteira;
   - traduzir a situação do lançamento;
   - destacar sinais mínimos de auditoria.

   Dependência lógica:
   - 103_cruzamento_nfe_sitafe_fronteira_completo.sql
============================================================================ */

WITH base AS (
    SELECT * FROM cruzamento_nfe_sitafe_fronteira_completo
)
SELECT
    b.chave_acesso,
    b.nota,
    b.cnpj_emit,
    b.nome_emit,
    b.uf_emitente,
    b.emissao,
    b.entrada,
    b.comando,
    b.prod_nitem,
    b.prod_xprod,
    b.co_cfop,
    b.ncm,
    b.prod_ucom,
    b.prod_qcom,
    b.prod_vuncom,
    b.prod_vprod,
    b.prod_vfrete,
    b.prod_vdesc,
    b.prod_voutro,
    b.prod_vseg,
    b.total_produto,
    b.icms_vbc,
    b.icms_picms,
    b.icms_vicms,
    b.icms_vbcst,
    b.icms_vicmsst,
    b.receita,
    b.guia,
    b.valor_devido,
    b.valor_pago,
    CASE
        WHEN b.it_co_situacao_lancamento IN ('00','03') THEN 'PAGO'
        WHEN b.it_co_situacao_lancamento = '28' THEN 'BAIXA DE ACORDO'
        WHEN b.it_co_situacao_lancamento = '68' THEN 'SUSPENSO'
        WHEN b.it_co_situacao_lancamento = '13' THEN 'CORRECAO PAGAMENTO'
        WHEN b.it_co_situacao_lancamento = '02' THEN 'PAGO A MENOR'
        WHEN b.it_co_situacao_lancamento = '05' THEN 'PARCELADO'
        WHEN b.it_co_situacao_lancamento = '08' THEN 'INSCRITO EM DA'
        WHEN b.it_co_situacao_lancamento = '10' THEN 'BAIXA PROVISORIA'
        WHEN b.it_co_situacao_lancamento = '14' THEN 'LANCAMENTO EXCLUIDO'
        WHEN b.it_co_situacao_lancamento = '32' THEN 'COMPENSACAO'
        WHEN b.it_co_situacao_lancamento = '38' THEN 'LIQUIDACAO DESVINCULADA'
        WHEN b.it_co_situacao_lancamento = '46' THEN 'SUSPENSAO JUDICIAL'
        WHEN b.it_co_situacao_lancamento = '50' THEN 'LANCAMENTO INDEVIDO'
        WHEN b.it_co_situacao_lancamento IS NULL THEN 'SEM SITUACAO'
        ELSE 'VERIFICAR'
    END AS situacao_lancamento,
    (NVL(b.valor_devido,0) - NVL(b.valor_pago,0)) AS saldo_aberto,
    CASE
        WHEN b.valor_devido IS NULL THEN 'NOTA SEM LANCAMENTO FINANCEIRO'
        WHEN NVL(b.valor_pago,0) >= NVL(b.valor_devido,0) THEN 'QUITADO OU SUPERIOR'
        WHEN NVL(b.valor_pago,0) > 0 THEN 'PAGAMENTO PARCIAL'
        ELSE 'SEM PAGAMENTO LOCALIZADO'
    END AS status_pagamento,
    b.co_sefin,
    b.nome_co_sefin,
    b.vl_merc,
    b.vl_bc_merc,
    b.aliq,
    b.vl_tot_deb,
    b.vl_tot_cred,
    b.vl_icms,
    b.it_pc_aliquota_interna,
    b.it_pc_aliquota_origem,
    b.it_convenio,
    b.it_pc_agregacao_interna,
    b.it_in_pgto_saida,
    b.it_boletim_pauta,
    b.it_in_isento_icms,
    b.it_passe_fiscal,
    b.it_in_combustivel,
    b.it_in_produto_st,
    b.it_in_cest_st,
    b.it_pc_interna
FROM base b
ORDER BY b.emissao, b.cnpj_emit, b.nota, TO_NUMBER(b.prod_nitem);
