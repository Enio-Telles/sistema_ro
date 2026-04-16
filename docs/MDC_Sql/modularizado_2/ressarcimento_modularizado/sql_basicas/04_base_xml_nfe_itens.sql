/*
===============================================================================
CONSULTA BÁSICA COMPARTILHADA 04
BASE XML / BI ITEM A ITEM
-------------------------------------------------------------------------------
Objetivo:
- disponibilizar uma camada XML comum para cruzamento documental;
- não acoplar aqui a regra tributária específica de cada abordagem.
===============================================================================
*/
SELECT
    nfe.chave_acesso,
    nfe.nsu,
    nfe.seq_nitem,
    nfe.prod_nitem,
    COALESCE(nfe.prod_nitem, nfe.seq_nitem) AS item_xml_padrao,
    nfe.co_emitente,
    nfe.co_destinatario,
    nfe.co_uf_emit,
    nfe.co_uf_dest,
    nfe.dhemi,
    nfe.infprot_cstat,
    nfe.prod_cprod,
    nfe.prod_xprod,
    nfe.prod_ncm,
    nfe.prod_cest,
    nfe.prod_qcom,
    nfe.prod_vprod,
    nfe.prod_vdesc,
    nfe.icms_vicms,
    nfe.icms_picms
FROM bi.fato_nfe_detalhe nfe
WHERE (nfe.co_emitente = :CNPJ OR nfe.co_destinatario = :CNPJ)
  AND nfe.dhemi BETWEEN TO_DATE(:data_inicial, 'DD/MM/YYYY')
                    AND TO_DATE(NVL(:data_final, TO_CHAR(SYSDATE, 'DD/MM/YYYY')), 'DD/MM/YYYY')
  AND nfe.infprot_cstat IN ('100', '150');
