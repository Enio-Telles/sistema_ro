/*
===============================================================================
MÓDULO 41 - CHAVES DE ENTRADA E EXTRAÇÃO DIRETA DO XML
-------------------------------------------------------------------------------
Objetivo
- Isolar as chaves de entrada efetivamente utilizadas no C176.
- Extrair campos não confiáveis ou não disponíveis em fato_nfe_detalhe, como
  vICMSSubstituto, direto do XML bruto por XMLTABLE.
===============================================================================
*/

ALTER SESSION SET NLS_NUMERIC_CHARACTERS='.,';

WITH arquivos_validos AS (
    SELECT * FROM arquivos_validos_fronteira
),
CHAVES_ENTRADA_FILTRADAS AS (
    SELECT DISTINCT c176_sub.chave_nfe_ult AS chave_nfe_ult
    FROM sped.reg_c176 c176_sub
    INNER JOIN arquivos_validos arq_sub
        ON c176_sub.reg_0000_id = arq_sub.reg_0000_id
),
XML_EXTRAIDO AS (
    SELECT
        x.chave_acesso,
        xml_item.prod_nitem,
        xml_item.icms_vICMSSubstituto
    FROM bi.nfe_xml x
    INNER JOIN CHAVES_ENTRADA_FILTRADAS cef
        ON x.chave_acesso = cef.chave_nfe_ult
    CROSS JOIN XMLTABLE(
        XMLNAMESPACES (DEFAULT 'http://www.portalfiscal.inf.br/nfe'),
        '//det' PASSING x.xml
        COLUMNS
            prod_nitem           NUMBER PATH '@nItem',
            icms_vICMSSubstituto NUMBER PATH 'imposto/ICMS//vICMSSubstituto' DEFAULT 0
    ) xml_item
)
SELECT *
FROM XML_EXTRAIDO
ORDER BY chave_acesso, prod_nitem;
