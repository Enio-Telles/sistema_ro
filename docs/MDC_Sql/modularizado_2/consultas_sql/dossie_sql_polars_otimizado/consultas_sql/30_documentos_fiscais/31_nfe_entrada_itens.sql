-- Objetivo: itens documentais classificados como entrada
-- Binds esperados: :CO_CNPJ_CPF

SELECT
    d.chave_acesso,
    d.prod_nitem,
    d.dhemi,
    d.co_cfop,
    d.co_emitente,
    d.co_destinatario,
    d.prod_cprod,
    d.prod_xprod,
    d.prod_ncm,
    d.prod_qcom,
    d.prod_vuncom,
    d.prod_vprod,
    d.prod_vfrete,
    d.prod_vseg,
    d.prod_vdesc,
    d.prod_voutro,
    (d.prod_vprod + d.prod_vfrete + d.prod_vseg + d.prod_voutro - d.prod_vdesc) AS valor_item
FROM bi.fato_nfe_detalhe d
WHERE (
       (d.co_destinatario = :CO_CNPJ_CPF AND d.co_tp_nf = 1)
    OR (d.co_emitente     = :CO_CNPJ_CPF AND d.co_tp_nf = 0)
)
  AND d.infprot_cstat IN ('100','150')
ORDER BY d.dhemi DESC, d.chave_acesso, d.prod_nitem;
