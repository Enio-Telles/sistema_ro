/*
===============================================================================
MDC 13 - XML NFE / CAMPOS EXTRAS NÃO NATIVOS DA FATO
-------------------------------------------------------------------------------
Objetivo
- Extrair do XML bruto campos que não estão integralmente disponíveis na fato.
- Base crítica para as trilhas de ressarcimento pós-2022 e até-2022.

Granularidade
- 1 linha por item XML.
===============================================================================
*/
SELECT
    x.chave_acesso,
    xml_item.prod_nitem,
    xml_item.prod_cProd,
    xml_item.icms_vICMSSubstituto,
    xml_item.icms_vICMSSTRet
FROM bi.nfe_xml x
CROSS JOIN XMLTABLE(
    XMLNAMESPACES (DEFAULT 'http://www.portalfiscal.inf.br/nfe'),
    '//det' PASSING x.xml
    COLUMNS
        prod_nitem           NUMBER       PATH '@nItem',
        prod_cProd           VARCHAR2(74) PATH 'prod/cProd',
        icms_vICMSSubstituto NUMBER       PATH 'imposto/ICMS//vICMSSubstituto' DEFAULT 0,
        icms_vICMSSTRet      NUMBER       PATH 'imposto/ICMS//vICMSSTRet'      DEFAULT 0
) xml_item
WHERE x.chave_acesso = :CHAVE_ACESSO;
