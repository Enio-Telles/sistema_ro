/*
 * CONSULTA: Extração de Base ICMS ST e FCP ST via XML (CORRIGIDA)
 * Objetivo: Conciliar valores de ST (Própria e Retida) e Fundo de Combate à Pobreza.
 */

-- Define o ponto como separador decimal para leitura correta do XML
ALTER SESSION SET NLS_NUMERIC_CHARACTERS='.,';

WITH PARAMETROS AS (
    SELECT 
        :CNPJ AS cnpj_filtro,          
        COALESCE(TO_DATE(:DATA_INICIAL, 'DD/MM/YYYY'), TO_DATE('01/01/2006', 'DD/MM/YYYY')) AS data_inicial,
        COALESCE(TO_DATE(:DATA_FINAL, 'DD/MM/YYYY'), TRUNC(SYSDATE) + 1 - 1/86400) AS data_final
    FROM DUAL
),

LISTA_NFES AS (
    SELECT DISTINCT f.CHAVE_ACESSO
    FROM bi.fato_nfe_detalhe f
    CROSS JOIN PARAMETROS p
    WHERE 
        (
            (f.dhemi BETWEEN p.data_inicial AND p.data_final)
            OR 
            (f.dhsaient BETWEEN p.data_inicial AND p.data_final)
        )
        AND (f.co_destinatario = p.cnpj_filtro OR f.co_emitente = p.cnpj_filtro)
        AND f.INFPROT_CSTAT IN (100, 150)
)

SELECT
    x.chave_acesso,
    xml_item.prod_nitem,
    xml_item.prod_cprod,
    -- Campos de ICMS ST (Gerado na Nota)
    xml_item.icms_vBCST,
    xml_item.icms_vICMSST,
    -- Campos de ICMS ST (Retido Anteriormente)
    xml_item.icms_vICMSSubstituto,
    xml_item.icms_vICMSSTRet,
    -- Campos de Fundo de Combate à Pobreza (FCP ST)
    xml_item.icms_vBCFCPST,
    xml_item.icms_pFCPST,
    xml_item.icms_vFCPST
FROM bi.nfe_xml x
INNER JOIN LISTA_NFES l ON x.chave_acesso = l.chave_acesso
CROSS JOIN XMLTABLE(
    XMLNAMESPACES (DEFAULT 'http://www.portalfiscal.inf.br/nfe'),
    '//det' PASSING x.xml 
    COLUMNS
        Prod_nItem           NUMBER       PATH '@nItem',
        PROD_cProd           VARCHAR2(74) PATH 'prod/cProd',
        -- Extração de ICMS ST Ativada
        icms_vBCST           NUMBER       PATH 'imposto/ICMS//vBCST'           DEFAULT 0,
        icms_vICMSST         NUMBER       PATH 'imposto/ICMS//vICMSST'         DEFAULT 0,
        icms_vICMSSubstituto NUMBER       PATH 'imposto/ICMS//vICMSSubstituto' DEFAULT 0,
        icms_vICMSSTRet      NUMBER       PATH 'imposto/ICMS//vICMSSTRet'      DEFAULT 0,
        -- Extração de FCP ST
        icms_vBCFCPST        NUMBER       PATH 'imposto/ICMS//vBCFCPST'        DEFAULT 0,
        icms_pFCPST          NUMBER       PATH 'imposto/ICMS//pFCPST'          DEFAULT 0,
        icms_vFCPST          NUMBER       PATH 'imposto/ICMS//vFCPST'          DEFAULT 0
) xml_item
ORDER BY x.chave_acesso, xml_item.prod_nitem;