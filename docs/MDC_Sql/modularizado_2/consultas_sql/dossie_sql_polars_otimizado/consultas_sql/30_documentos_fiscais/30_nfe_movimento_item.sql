-- Objetivo: base singular de itens de NF/NFC-e com classificação de entrada e saída
-- Binds esperados: :CO_CNPJ_CPF

SELECT
    'NFE' AS origem_doc,
    d.chave_acesso,
    d.prod_nitem,
    d.dhemi,
    d.co_tp_nf,
    d.co_cfop,
    d.co_emitente,
    d.co_destinatario,
    d.co_uf_emit,
    d.co_uf_dest,
    d.co_cad_icms_emit,
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
    (d.prod_vprod + d.prod_vfrete + d.prod_vseg + d.prod_voutro - d.prod_vdesc) AS valor_item,
    d.infprot_cstat,
    CASE
        WHEN d.co_emitente     = :CO_CNPJ_CPF AND d.co_tp_nf = 1 THEN 'SAIDA'
        WHEN d.co_destinatario = :CO_CNPJ_CPF AND d.co_tp_nf = 0 THEN 'SAIDA'
        WHEN d.co_destinatario = :CO_CNPJ_CPF AND d.co_tp_nf = 1 THEN 'ENTRADA'
        WHEN d.co_emitente     = :CO_CNPJ_CPF AND d.co_tp_nf = 0 THEN 'ENTRADA'
        ELSE 'NAO_CLASSIFICADO'
    END AS direcao
FROM bi.fato_nfe_detalhe d
WHERE (d.co_emitente = :CO_CNPJ_CPF OR d.co_destinatario = :CO_CNPJ_CPF)
  AND d.infprot_cstat IN ('100','150')

UNION ALL

SELECT
    'NFCE' AS origem_doc,
    d.chave_acesso,
    d.prod_nitem,
    d.dhemi,
    d.co_tp_nf,
    d.co_cfop,
    d.co_emitente,
    d.co_destinatario,
    d.co_uf_emit,
    d.co_uf_dest,
    d.co_cad_icms_emit,
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
    (d.prod_vprod + d.prod_vfrete + d.prod_vseg + d.prod_voutro - d.prod_vdesc) AS valor_item,
    d.infprot_cstat,
    CASE
        WHEN d.co_emitente     = :CO_CNPJ_CPF AND d.co_tp_nf = 1 THEN 'SAIDA'
        WHEN d.co_destinatario = :CO_CNPJ_CPF AND d.co_tp_nf = 0 THEN 'SAIDA'
        WHEN d.co_destinatario = :CO_CNPJ_CPF AND d.co_tp_nf = 1 THEN 'ENTRADA'
        WHEN d.co_emitente     = :CO_CNPJ_CPF AND d.co_tp_nf = 0 THEN 'ENTRADA'
        ELSE 'NAO_CLASSIFICADO'
    END AS direcao
FROM bi.fato_nfce_detalhe d
WHERE (d.co_emitente = :CO_CNPJ_CPF OR d.co_destinatario = :CO_CNPJ_CPF)
  AND d.infprot_cstat IN ('100','150');
