alter session set nls_numeric_characters='.,'    ;   -- para que os valor do portalfiscal sejam mostrados

WITH

chaves  as (
                select chave_acesso chaves from bi.fato_nfe_detalhe
                where 
                seq_nitem = 1 
                and chave_acesso  in (

'13230204565289000570550020023342071013529415',
'11220884640580000171550010003096581225371220',
'11250103376298000208550010001013231000345597'


)),
portalfiscal as (
                        select a.chave_acesso, 
                                b.*
                        
                        from bi.nfe_xml a,      xmltable( xmlnamespaces (default 'http://www.portalfiscal.inf.br/nfe'),'//det' passing a.xml 
                                                columns
                                                Prod_nItem             number   path '@nItem'       ,
                                                PROD_cProd    varchar2(74)  path 'prod/cProd'       ,
                                                icms_vICMSSubstituto   number    PATH 'imposto/ICMS//vICMSSubstituto' default 0,  
                                                icms_vICMSSTRet   number    PATH 'imposto/ICMS//vICMSSTRet' default 0  
                                                
                                                ) b     
                                                
                                                                                                                         
                        where a.chave_acesso in (select chaves from chaves)
)


SELECT
  nf.CHAVE_ACESSO                                  AS CHAVE_ACESSO,
  nf.prod_nitem                                    AS N_ITEM,
  nf.seq_nitem  AS SEQ_ITEM,
  nf.PROD_CPROD                                    AS CPROD,
  nf.PROD_XPROD                                    AS DESCRICAO,
  nf.PROD_UCOM                                     AS UNID,
  nf.PROD_QCOM                                     AS QTDE,
  nf.PROD_NCM                                      AS NCM,
  nf.PROD_CEST                                     AS CEST,
  NVL(d.it_co_rotina_calculo, 'sem calculo')       AS FRONTEIRA,  
  d.it_vl_icms                                     AS CALC_FRONTEIRA,
  nf.ICMS_VICMSST                                  AS ICMS_ST_NF,  
  nf.ICMS_VICMS                                    AS ICMS_PROP_NF,
  p.icms_vICMSSubstituto                           AS ICMS_VICMS_SUBSTITUTO,  
  p.icms_vICMSSTRet                                AS ICMS_VICMS_ST_RET


  

FROM bi.fato_nfe_detalhe nf  
LEFT JOIN sitafe.sitafe_nfe_calculo_item d  ON  d.it_nu_chave_acesso = nf.chave_acesso  AND   d.it_nu_item = nf.prod_nitem
LEFT JOIN portalfiscal p ON p.chave_acesso = nf.chave_acesso  AND   p.Prod_nItem = nf.prod_nitem

WHERE nf.CHAVE_ACESSO  in (select chaves from chaves)






