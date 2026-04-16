/*
===============================================================================
MÓDULO 61 - EXTRAÇÃO DIRETA DO XML (PORTAL FISCAL) PRÉ-2022
-------------------------------------------------------------------------------
Objetivo
- Ler o XML bruto em CLOB e extrair campos que nem sempre estão presentes
  de forma confiável na fato estruturada.
- Preservar a lógica histórica da query original para vICMSSubstituto e
  vICMSSTRet.

Observação técnica
- Requer sessão com NLS_NUMERIC_CHARACTERS='.,'.
===============================================================================
*/

ALTER SESSION SET NLS_NUMERIC_CHARACTERS='.,';

WITH chaves_alvo AS (
    SELECT chave_acesso
    FROM tabela_chaves_alvo
)
SELECT
    x.chave_acesso,
    xml_item.prod_nitem,
    xml_item.prod_cprod,
    xml_item.icms_vicmssubstituto,
    xml_item.icms_vicmsstret
FROM bi.nfe_xml x
JOIN chaves_alvo c
  ON x.chave_acesso = c.chave_acesso
CROSS JOIN XMLTABLE(
    XMLNAMESPACES (DEFAULT 'http://www.portalfiscal.inf.br/nfe'),
    '//det' PASSING x.xml
    COLUMNS
        prod_nitem NUMBER       PATH '@nItem',
        prod_cprod VARCHAR2(74) PATH 'prod/cProd',
        icms_vicmssubstituto NUMBER PATH 'imposto/ICMS//vICMSSubstituto' DEFAULT 0,
        icms_vicmsstret      NUMBER PATH 'imposto/ICMS//vICMSSTRet'      DEFAULT 0
) xml_item
ORDER BY x.chave_acesso, xml_item.prod_nitem;
