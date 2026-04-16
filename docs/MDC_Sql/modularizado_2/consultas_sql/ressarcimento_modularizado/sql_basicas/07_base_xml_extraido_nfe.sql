/*
===============================================================================
CONSULTA BÁSICA 07 - EXTRAÇÃO DIRETA DE CAMPOS DO XML DA NF-E
-------------------------------------------------------------------------------
Objetivo
- Extrair campos do XML bruto que nem sempre estão estruturados de forma
  suficiente em fato_nfe_detalhe.
- Exemplo principal: vICMSSubstituto por item.
===============================================================================
*/

ALTER SESSION SET NLS_NUMERIC_CHARACTERS='.,';

SELECT x.chave_acesso,
       xml_item.prod_nitem,
       xml_item.icms_vICMSSubstituto
FROM bi.nfe_xml x
CROSS JOIN XMLTABLE(
    XMLNAMESPACES (DEFAULT 'http://www.portalfiscal.inf.br/nfe'),
    '//det' PASSING x.xml
    COLUMNS
        prod_nitem           NUMBER PATH '@nItem',
        icms_vICMSSubstituto NUMBER PATH 'imposto/ICMS//vICMSSubstituto' DEFAULT 0
) xml_item
WHERE x.chave_acesso = :chave_acesso
ORDER BY x.chave_acesso, xml_item.prod_nitem;
