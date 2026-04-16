alter session set nls_numeric_characters='.,'    ;   -- para que os valor do portalfiscal sejam mostrados  --- FAZER BATAER ESSA NOTA '42221100851124000180550030001553781572278304'

WITH
TAB_AUX_CLASSIFICACAO   AS (
                                        SELECT 
                                            IT_CO_SEFIN,
                                            TO_DATE(IT_DA_INICIO, 'YYYYMMDD') IT_DA_INICIO,
                                            CASE
                                            WHEN TRIM (IT_DA_FINAL) IS NULL THEN SYSDATE ELSE TO_DATE(IT_DA_FINAL, 'YYYYMMDD') END IT_DA_FINAL ,
                                            IT_PC_INTERNA, 
                                            IT_IN_ST, 
                                            IT_PC_MVA, 
                                            IT_IN_MVA_AJUSTADO, 
                                            IT_IN_CONVENIO, 
                                            IT_IN_ISENTO_ICMS, 
                                            IT_IN_REDUCAO, 
                                            IT_PC_REDUCAO, 
                                            IT_IN_PGTO_SAIDA, 
                                            IT_IN_COMBUSTIVEL, 
                                            IT_IN_REDUCAO_CREDITO, 
                                            IT_UF_AC, IT_UF_AL, IT_UF_AM, IT_UF_AP, IT_UF_BA, IT_UF_CE, IT_UF_DF, IT_UF_ES, IT_UF_GO, IT_UF_MA, IT_UF_MG, IT_UF_MS, IT_UF_MT, IT_UF_PA, IT_UF_PB, IT_UF_PE, IT_UF_PI, IT_UF_PR, IT_UF_RJ, IT_UF_RN, IT_UF_RR, IT_UF_RS, IT_UF_SC, IT_UF_SE, IT_UF_SP, IT_UF_TO, 
                                            IT_IN_PMPF
                                        
                                        
                                        FROM sitafe.sitafe_produto_sefin_aux  a

),

chaves  as (
                select chave_acesso chaves from bi.fato_nfe_detalhe
                where 
                seq_nitem = 1 
                and chave_acesso  in (

'13220204565289000570550020018445691279488535' -- nf com frete: 13220204565289000570550020018448021990816152 (1 item) - 13220204565289000570550020018445691279488535 (+ de 1 item)


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
),
CREDITO_CALCULADO   as (
                SELECT    
                        CHAVE_ACESSO,
                        PROD_NITEM,
                        ROUND (
                          CASE 
                            WHEN ICMS_ORIG IN ('1', '2', '3', '8') THEN 0.04
                            ELSE (select ALIQ from qvw.tbl_aliq_ufs uf where nf.CO_UF_EMIT = uf.UF) END * 
                          (PROD_VPROD + PROD_VFRETE + PROD_VSEG - PROD_VDESC + PROD_VOUTRO),2) CRED_CALC  
                          
                FROM bi.fato_nfe_detalhe nf 
                WHERE nf.CHAVE_ACESSO  in (select chaves from chaves)
),

RATEIO_FRETE_ETAPA_A    AS (   -- TRAZER OS CTE´S
                            SELECT
                                chaves,
                                cte_itens.it_nu_chave_cte chaves_cte  
                    
                FROM   chaves     
                join  sitafe.sitafe_cte_itens cte_itens     on  chaves.chaves = cte_itens.IT_NU_CHAVE_NFE

),
RATEIO_FRETE_ETAPA_B    AS   (  -- traz o percentual de cada nota no conjunto de notas dos cte´s
                        select 
                            IT_NU_CHAVE_CTE, 
                            IT_NU_CHAVE_NFE, 
                            cte.IT_TP_FRETE TP_FRETE,  
                            cte.IT_VA_TOTAL_FRETE TOTAL_FRETE,
                            cte.IT_VA_VALOR_ICMS ICMS_FRETE,                            
                            cte_itens.it_nu_doc nu_doc,
                            cte_itens.it_inf_tipo tipo_doc,
                            (nfe.TOT_VPROD + nfe.TOT_VFRETE + nfe.TOT_VSEG +  nfe.TOT_VOUTRO - nfe.TOT_VDESC + TOT_VIPI + TOT_VST) BC_RATEIO_FOB,
                            sum (nfe.TOT_VPROD + nfe.TOT_VFRETE + nfe.TOT_VSEG +  nfe.TOT_VOUTRO - nfe.TOT_VDESC + TOT_VIPI + TOT_VST) over() total_nf,
                            round ((nfe.TOT_VPROD + nfe.TOT_VFRETE + nfe.TOT_VSEG +  nfe.TOT_VOUTRO - nfe.TOT_VDESC + TOT_VIPI + TOT_VST) /
                            sum (nfe.TOT_VPROD + nfe.TOT_VFRETE + nfe.TOT_VSEG +  nfe.TOT_VOUTRO - nfe.TOT_VDESC + TOT_VIPI + TOT_VST) over(),5) perc
                           
                            
                        from sitafe.sitafe_cte_itens cte_itens 
                        left join   bi.fato_nfe_detalhe  nfe       on  nfe.chave_acesso = cte_itens.it_nu_chave_nfe
                        left join   sitafe.sitafe_cte    cte       on  cte.IT_NU_CHAVE_ACESSO =  cte_itens.it_nu_chave_cte                               

                        where 
                            IT_NU_CHAVE_CTE in  (select chaves_cte from RATEIO_FRETE_ETAPA_A)
                            and nfe.seq_nitem = '1' 
                            --and IT_NU_CNPJ_DESTINATARIO = nfe.co_destinatario
                            and substr (IT_NU_CNPJ_TOMADOR,1,8) = substr(nfe.co_destinatario,1,8)
                            
),


RATEIO_FRETE_ETAPA_C   AS     (  -- distribui o frete e icms_frete para os itens das notas 
                            select 
                                IT_NU_CHAVE_CTE, 
                                nf.chave_acesso,  
                                nf.prod_nitem,
                                nf.TOT_VPROD + nf.TOT_VFRETE + nf.TOT_VSEG +  nf.TOT_VOUTRO - nf.TOT_VDESC + nf.TOT_VIPI + nf.TOT_VST vl_nota,
                                nf.PROD_VPROD  + nf.PROD_VFRETE + nf.PROD_VSEG  + nf.PROD_VOUTRO - nf.PROD_VDESC + nf.IPI_VIPI + nf.ICMS_VICMSST vl_item,                                
                                ROUND (TOTAL_FRETE*PERC ,3) RATEIO_FRETE_NF , 
                                ROUND (ICMS_FRETE*PERC, 3) RATEIO_ICMS_FRET_NF,
                                ROUND ((nf.PROD_VPROD  + nf.PROD_VFRETE + nf.PROD_VSEG  + nf.PROD_VOUTRO - nf.PROD_VDESC + nf.IPI_VIPI + nf.ICMS_VICMSST) /
                                        (nf.TOT_VPROD + nf.TOT_VFRETE + nf.TOT_VSEG +  nf.TOT_VOUTRO - nf.TOT_VDESC + nf.TOT_VIPI + nf.TOT_VST)*TOTAL_FRETE*PERC, 4) RATEIO_FRETE_NF_ITEM,
                                ROUND ((nf.PROD_VPROD  + nf.PROD_VFRETE + nf.PROD_VSEG  + nf.PROD_VOUTRO - nf.PROD_VDESC + nf.IPI_VIPI + nf.ICMS_VICMSST) /
                                        (nf.TOT_VPROD + nf.TOT_VFRETE + nf.TOT_VSEG +  nf.TOT_VOUTRO - nf.TOT_VDESC + nf.TOT_VIPI + nf.TOT_VST)*ICMS_FRETE*PERC, 4) RATEIO_ICMS_FRET_NF_ITEM
                                
                                
                            from RATEIO_FRETE_ETAPA_B c
                            join bi.fato_nfe_detalhe nf on c.IT_NU_CHAVE_NFE = nf.chave_acesso
)             
                               

SELECT
          nf.CHAVE_ACESSO                                  AS CHAVE_ACESSO,
          nf.prod_nitem                                    AS N_ITEM,
          nf.seq_nitem                                    AS SEQ_ITEM,
          
        CASE 
            WHEN IT_IN_ST = 'S' THEN
                  CASE 
                    WHEN CO_CRT IN ('1', '4' ) THEN  -- EMITENTE DO SIMPLES
                                        ROUND (((IT_VA_PRODUTO + IT_VA_FRETE + IT_VA_SEGURO - IT_VA_DESCONTO + IT_VA_OUTRO + IT_VA_IPI_ITEM + NVL(C.RATEIO_FRETE_NF_ITEM,0))*(100+A.IT_PC_MVA)/100*A.IT_PC_INTERNA/100 - CRED_CALC ) -NVL(C.RATEIO_ICMS_FRET_NF_ITEM,0) , 2)  -- BASE SIMPLES PARA SIMPLES
                                        
                    ELSE  -- REGIME NORMAL
                        CASE    WHEN A.IT_IN_MVA_AJUSTADO = 'S' THEN  
                                        ROUND ( (((IT_VA_PRODUTO + IT_VA_FRETE + IT_VA_SEGURO - IT_VA_DESCONTO + IT_VA_OUTRO - nf.ICMS_VICMS)/(1-A.IT_PC_INTERNA/100))+IT_VA_IPI_ITEM + NVL(C.RATEIO_FRETE_NF_ITEM,0))*  (100+A.IT_PC_MVA)/100*A.IT_PC_INTERNA/100 -  LEAST(nf.ICMS_VICMS, CRED_CALC) -NVL(C.RATEIO_ICMS_FRET_NF_ITEM,0),2)   --BASE DUPLA PARA NORMAL                                       
                                ELSE    
                                        ROUND((((IT_VA_PRODUTO + IT_VA_FRETE + IT_VA_SEGURO - IT_VA_DESCONTO + IT_VA_OUTRO + IT_VA_IPI_ITEM + NVL(C.RATEIO_FRETE_NF_ITEM,0))*  (100+A.IT_PC_MVA)/100*A.IT_PC_INTERNA)/100) - LEAST(nf.ICMS_VICMS, CRED_CALC) - NVL(C.RATEIO_ICMS_FRET_NF_ITEM,0) ,2)  -- -- BASE SIMPLES PARA NORMAL
                        END
                  END 
            ELSE NULL
          END CALC_ST,
          nf.PROD_CPROD                                    AS CPROD,
          nf.PROD_XPROD                                    AS DESCRICAO,
          nf.PROD_UCOM                                     AS UNID,
          nf.PROD_QCOM                                     AS QTDE,
          nf.PROD_NCM                                      AS NCM,
          nf.PROD_CEST                                     AS CEST,                  
          '| >>>>>'                                        as "| CAMPOS_XML",
          nf.ICMS_VICMS                                    AS ICMS_PROP_NF,
          p.icms_vICMSSubstituto                           AS ICMS_VICMS_SUBSTITUTO,   
          nf.ICMS_VICMSST                                  AS ICMS_ST_NF,  
          p.icms_vICMSSTRet                                AS ICMS_VICMS_ST_RET,  
          
              '| >>>>>'                                    as "| MEM_CALC_ST", 
            case  WHEN CO_CRT IN ('1', '4' ) THEN 'SIMPLES'
            ELSE 'NORMAL'
            END REGIME_EMIT,
          CASE 
            WHEN IT_IN_ST = 'N' THEN 'NAO_ST' 
            WHEN CO_CRT IN ('1', '4' ) THEN 'BASE_SIMPLES'
            WHEN IT_IN_MVA_AJUSTADO = 'N' THEN 'BASE_SIMPLES'
            ELSE 'BASE_DUPLA' 
          END MOD_BC, 
          D.IT_CO_SEFIN, 
            A.IT_PC_MVA,             
            A.IT_IN_ISENTO_ICMS, 
            A.IT_IN_REDUCAO, 
            A.IT_PC_REDUCAO,
            A.IT_PC_INTERNA,
                d.IT_PC_ICMS, 
                A.IT_IN_PMPF, 
                d.IT_VA_IPI_ITEM,
                ROUND (NVL(C.RATEIO_FRETE_NF_ITEM,0),2) RATEIO_FRETE_NF_ITEM,
                ROUND (NVL(C.RATEIO_ICMS_FRET_NF_ITEM,0),2) RATEIO_ICMS_FRET_NF_ITEM,
                IT_NU_CHAVE_CTE
      

FROM bi.fato_nfe_detalhe nf  
LEFT JOIN   sitafe.sitafe_nfe_item  D ON  NF.CHAVE_ACESSO = D.IT_NU_CHAVE_ACESSO  AND    D.IT_NU_ITEM = nf.prod_nitem
LEFT JOIN TAB_AUX_CLASSIFICACAO A ON A.IT_CO_SEFIN = D.IT_CO_SEFIN AND DHEMI >= IT_DA_INICIO AND DHEMI <= IT_DA_FINAL 
LEFT JOIN portalfiscal p ON p.chave_acesso = nf.chave_acesso  AND   p.Prod_nItem = nf.prod_nitem
JOIN CREDITO_CALCULADO CC ON NF.CHAVE_ACESSO = CC.CHAVE_ACESSO  AND    CC.prod_nitem = nf.prod_nitem
LEFT JOIN RATEIO_FRETE_ETAPA_C C ON  NF.CHAVE_ACESSO = C.CHAVE_ACESSO  AND    c.prod_nitem =nf.prod_nitem 

WHERE 
    nf.CHAVE_ACESSO  in (select chaves from chaves)
    
    







