-- MEIOS DE PAGAMENTO ELETRÔNICOS A PARTIR DE 10/2024 INCLUIR REG1500
SELECT 'REG1100' AS ORIGEM,
        M.CNPJ_CPF, 
        M.ID_REG0000,
        M.ID_MES_OPERACAO,
        D.NOME,
        D.CNPJ,
        M.NAT_OPER_DESCRICAO,
        M.NAT_OPER,
        SUM(M.VALOR) AS TOTAL_MP2

 FROM BI.MPG_F_DETALHE_OPERACAO M
 INNER JOIN DIMP.REG0000S D
             ON M.ID_REG0000 = D.ID AND M.CNPJ_DECLARANTE = D.CNPJ
 WHERE TRUNC(M.DT_OP, 'MM') = :DA_REFERENCIA
          AND M.FLAG_COMEX = '0'
          AND ((M.CNPJ_ADQUIRENTE = M.CNPJ_DECLARANTE) OR (M.CNPJ_ADQUIRENTE IS NULL))
          AND M.FLAG_CANCELADO = '0'
          AND M.NAT_OPER NOT IN ('3', '5', '8', '11')
          AND M.CNPJ_CPF = :CNPJ 
    GROUP BY 'REG1100',
        M.CNPJ_CPF, 
        M.ID_REG0000,
        M.ID_MES_OPERACAO,
        D.CNPJ,
        M.NAT_OPER_DESCRICAO,
        M.NAT_OPER,
        D.NOME

UNION

    SELECT 
        'REG1500' AS ORIGEM,
        F.CNPJ, 
        F.ID_REG0000,
        F.ID_MES_OPERACAO,
        D.NOME,
        D.CNPJ,
        CASE
        WHEN F.NAT_OPER = 6 THEN 'PIX'
        ELSE NULL
        END NAT_OPER_DESCRICAO,
        F.NAT_OPER,
        SUM(NVL(F.VALOR_LIQ,0)) AS TOTAL_MP3
    FROM BI.VW_MPG_REG1500_FISCONFORME F
    INNER JOIN DIMP.REG0000S D
             ON F.ID_REG0000 = D.ID AND F.CNPJ_DECLARANTE = D.CNPJ
    WHERE F.DA_REFERENCIA = :DA_REFERENCIA
    AND F.CNPJ = :CNPJ 
    AND F.IND_NAT_JUR = 0 -- comentar essa opção para identificar eventuais diferenças
    GROUP BY 
        'REG1500',
        F.CNPJ, 
        F.ID_REG0000,
        F.ID_MES_OPERACAO,
        D.CNPJ,
        CASE
        WHEN F.NAT_OPER = 6 THEN 'PIX'
        ELSE NULL 
        END,
        F.NAT_OPER,
        D.NOME;

-- tab=NFE
-- FILTRAR NFE's EMITIDAS POR CONTRIBUINTES DE RONDÔNIA NO PERÍODO PESQUISADO. APENAS NFE DE SAÍDAS E NÃO CANCELADAS

     SELECT
        d.CO_EMITENTE AS CNPJ,
        d.co_destinatario AS CNPJ_d,
        D.CO_TP_NF AS TIPO_NF,
        d.CHAVE_ACESSO,  
        d.DHEMI AS DATA_EMISSAO,
        d.NNF AS NUMERO_NF,
        d.IDE_CO_MOD AS MODELO,  
        d.IDE_SERIE AS SERIE,  
        d.PROD_XPROD,
         D.PROD_VPROD,
         D.PROD_VFRETE,   
         D.PROD_VSEG,
          D.PROD_VOUTRO,
          D.PROD_VDESC,
        SUM(D.PROD_VPROD + D.PROD_VFRETE + D.PROD_VSEG + D.PROD_VOUTRO - D.PROD_VDESC) AS TOTAL_NF,                                                                       
        d.CO_CFOP AS  CFOP,
        D.ICMS_CSOSN AS  CSOSN, 
        D.ICMS_CST,
        C.CO_TIPO_TRIBUTACAO_SN,
        C.ATIV_SIMPLES AS COD_ATIVIDADE,
        D.PROD_NCM
    FROM
        BI.FATO_NFE_DETALHE D,  BI.DM_CFOP C
    WHERE       
        D.CO_CFOP = C.CO_CFOP AND
        D.DHEMI BETWEEN  :DA_REFERENCIA  AND :DATA_FINAL   AND
        D.CO_TP_NF = '1'  AND     
       d.INFPROT_CSTAT IN ('100','150') AND      
        --c.CO_TIPO_TRIBUTACAO_SN in ('1', '3', '5', '83', '84') and
        D.CO_EMITENTE  = :CNPJ AND
        D.CO_UF_EMIT = 'RO'      
 
  GROUP BY  
        d.CO_EMITENTE,
        d.co_destinatario,
        D.CO_TP_NF,
        d.CHAVE_ACESSO,  
        d.DHEMI,
        d.NNF,
        d.IDE_CO_MOD,  
        d.IDE_SERIE,     
        d.PROD_XPROD,
         D.PROD_VPROD,
         D.PROD_VFRETE,   
         D.PROD_VSEG,
          D.PROD_VOUTRO,
          D.PROD_VDESC,                                                                   
        d.CO_CFOP,
        C.CO_TIPO_TRIBUTACAO_SN,
        D.ICMS_CSOSN,
        C.ATIV_SIMPLES,
        d.icms_cst,
        D.PROD_NCM
       
    
 UNION

-- FILTRAR NFCE's EMITIDAS POR CONTRIBUINTES DE RONDÔNIA NO PERÍODO PESQUISADO. APENAS NFE DE SAÍDAS E NÃO CANCELADAS

     SELECT
        d.CO_EMITENTE AS CNPJ,
        d.co_destinatario AS CNPJ_d,
        D.CO_TP_NF AS TIPO_NF,
        d.CHAVE_ACESSO,  
        d.DHEMI AS DATA_EMISSAO,
        d.NNF AS NUMERO_NF,
        d.IDE_CO_MOD AS MODELO,  
        d.IDE_SERIE AS SERIE,     
        d.PROD_XPROD,
           D.PROD_VPROD,
         D.PROD_VFRETE,   
         D.PROD_VSEG,
          D.PROD_VOUTRO,
          D.PROD_VDESC,
        SUM(D.PROD_VPROD + D.PROD_VFRETE + D.PROD_VSEG + D.PROD_VOUTRO - D.PROD_VDESC) AS TOTAL_NF,                                                                       
        d.CO_CFOP AS  CFOP,       
        D.ICMS_CSOSN AS  CSOSN,  
        d.icms_cst,
        C.CO_TIPO_TRIBUTACAO_SN,
        C.ATIV_SIMPLES AS COD_ATIVIDADE,
        D.PROD_NCM
    FROM
        BI.FATO_NFCE_DETALHE D,  BI.DM_CFOP C
    WHERE       
        D.CO_CFOP = C.CO_CFOP AND
        D.DHEMI BETWEEN :DA_REFERENCIA AND :DATA_FINAL   AND
        D.CO_TP_NF = '1'  AND                                 
        --c.CO_TIPO_TRIBUTACAO_SN in ('1', '3', '5', '83', '84') and
       d.INFPROT_CSTAT IN ('100','150') AND      
        D.CO_EMITENTE  = :CNPJ AND
        D.CO_UF_EMIT = 'RO'     

 GROUP BY  
        d.CO_EMITENTE,
        d.co_destinatario,
        D.CO_TP_NF,
        d.CHAVE_ACESSO,  
        d.DHEMI,
        d.NNF,
        d.IDE_CO_MOD,  
        d.IDE_SERIE,
        d.PROD_XPROD,     
         D.PROD_VPROD,
         D.PROD_VFRETE,   
         D.PROD_VSEG,
          D.PROD_VOUTRO,
          D.PROD_VDESC,                                                                
        d.CO_CFOP,    
        C.CO_TIPO_TRIBUTACAO_SN,
        D.ICMS_CSOSN,
        C.ATIV_SIMPLES,
        d.icms_cst,
        D.PROD_NCM;    
        
-- TAB=PGDAS    
    SELECT
        *
    FROM
        BI.FATO_PGDAS_ESTABELECIMENTO PE     
                                                                   
    WHERE                                                      
        PE.PA BETWEEN  :DA_REFERENCIA  AND :DATA_FINAL   AND
        PE.CNPJ = :CNPJ /*AND
        PE.TIPO_ATIVIDADE IN ('01', '02', '03', '04', '05', '06')*/ ;
                                                      
       
       -- tab = DEVOLUÇÕES
      SELECT
        d.CO_EMITENTE AS CNPJ,   
        D.CO_TP_NF AS TIPO_NF,
        d.CHAVE_ACESSO,  
        d.DHEMI AS DATA_EMISSAO,
        d.NNF AS NUMERO_NF,
        d.IDE_CO_MOD AS MODELO,  
        d.IDE_SERIE AS SERIE,    
        SUM(D.PROD_VPROD + D.PROD_VFRETE + D.PROD_VSEG + D.PROD_VOUTRO - D.PROD_VDESC) AS TOTAL_NF,                                                                       
        d.CO_CFOP AS  CFOP,
        D.ICMS_CSOSN AS  CSOSN,  
        C.CO_TIPO_TRIBUTACAO_SN,
        C.ATIV_SIMPLES AS COD_ATIVIDADE,
        D.PROD_NCM
    FROM
        BI.FATO_NFE_DETALHE D,  BI.DM_CFOP C
    WHERE       
        D.CO_CFOP = C.CO_CFOP AND
        D.DHEMI BETWEEN  :DA_REFERENCIA  AND :DATA_FINAL   AND      
        (C.DEV_FAT_INT_SIMPLES = 'X' OR C.DEV_FAT_EXT_SIMPLES = 'X') AND
        D.CO_TP_NF = '0'  AND     
        d.INFPROT_CSTAT IN ('100','150') AND      
        --c.CO_TIPO_TRIBUTACAO_SN in ('1', '2', '3', '5', '6') and
        D.CO_EMITENTE  = :CNPJ AND
        D.CO_UF_EMIT = 'RO'      
 
  GROUP BY  
        d.CO_EMITENTE,   
        D.CO_TP_NF,
        d.CHAVE_ACESSO,  
        d.DHEMI,
        d.NNF,
        d.IDE_CO_MOD,  
        d.IDE_SERIE,                                      
        d.CO_CFOP,
        C.CO_TIPO_TRIBUTACAO_SN,
        D.ICMS_CSOSN,
        C.ATIV_SIMPLES,
        D.PROD_NCM
        
  UNION    
        
          SELECT
        d.CO_EMITENTE AS CNPJ,   
        D.CO_TP_NF AS TIPO_NF,
        d.CHAVE_ACESSO,  
        d.DHEMI AS DATA_EMISSAO,
        d.NNF AS NUMERO_NF,
        d.IDE_CO_MOD AS MODELO,  
        d.IDE_SERIE AS SERIE,    
        SUM(D.PROD_VPROD + D.PROD_VFRETE + D.PROD_VSEG + D.PROD_VOUTRO - D.PROD_VDESC) AS TOTAL_NF,                                                                       
        d.CO_CFOP AS  CFOP,
        D.ICMS_CSOSN AS  CSOSN,  
        C.CO_TIPO_TRIBUTACAO_SN,
        C.ATIV_SIMPLES AS COD_ATIVIDADE,
        D.PROD_NCM
    FROM
        BI.FATO_NFE_DETALHE D,  BI.DM_CFOP C
    WHERE       
        D.CO_CFOP = C.CO_CFOP AND
        D.DHEMI BETWEEN  :DA_REFERENCIA  AND :DATA_FINAL   AND  
        --C.DEV_ENT_SIMPLES = 'X' AND
        C.DEV_ENT_SIMPLES = 'X' AND
        D.CO_TP_NF = '1'  AND     
        d.INFPROT_CSTAT IN ('100','150') AND      
        --c.CO_TIPO_TRIBUTACAO_SN in ('1', '2', '3', '5', '6') and
        D.CO_DESTINATARIO  = :CNPJ AND
        D.CO_UF_EMIT = 'RO'      
 
  GROUP BY  
        d.CO_EMITENTE,   
        D.CO_TP_NF,
        d.CHAVE_ACESSO,  
        d.DHEMI,
        d.NNF,
        d.IDE_CO_MOD,  
        d.IDE_SERIE,                           
        d.CO_CFOP,
        C.CO_TIPO_TRIBUTACAO_SN,
        D.ICMS_CSOSN,
        C.ATIV_SIMPLES,
        D.PROD_NCM;
        
-- tab = nfe_nfce_sumarizada 

  SELECT
                
        S.CO_EMITENTE,
        S.CO_MOD,
        s.icms_csosn,
        s.icms_cst,
        s.co_cfop,
        SUM(S.PROD_VPROD + S.PROD_VFRETE + S.PROD_VSEG + S.PROD_VOUTRO - S.PROD_VDESC) AS SAIDAS_NF
   
    FROM
        BI.fato_nfe_nfce_sum_diario S
        --BI.FATO_NFE_NFCE_SUMARIZADA S
            INNER JOIN BI.DM_CFOP CF
                ON S.CO_CFOP = CF.CO_CFOP
            INNER JOIN BI.DM_TIPO_TRIBUTACAO_SN T
                ON T.CO_TIPO_TRIBUTACAO  = (CASE
                                                WHEN CF.CO_TIPO_TRIBUTACAO_SN in('1','83') AND (S.ICMS_CSOSN NOT IN ('103', '203', '900', '300', '400', '500') OR S.ICMS_CST NOT IN ('30', '40', '41', '50', '51', '60', '90'))THEN 1   
                                                WHEN CF.CO_TIPO_TRIBUTACAO_SN in('1','83') AND (S.ICMS_CSOSN IN ('103', '203') OR S.ICMS_CST IN ('40')) THEN 2
                                                WHEN CF.CO_TIPO_TRIBUTACAO_SN = '3' OR (CF.CO_TIPO_TRIBUTACAO_SN = '1' AND S.ICMS_CSOSN = '300' OR S.ICMS_CST = '30') THEN 3  
                                                WHEN CF.CO_TIPO_TRIBUTACAO_SN in('5','84') OR S.ICMS_CSOSN = '500' OR S.ICMS_CST = '60' THEN 5   
                                                WHEN CF.CO_TIPO_TRIBUTACAO_SN in('1','83','84') AND (S.ICMS_CSOSN IN ('900') OR S.ICMS_CST IN ('50', '51', '90')) THEN 6 
                                            END)
                
    WHERE
        S.CO_EMITENTE = :CNPJ AND--'41827604000193'
        --S.DA_REFERENCIA = :DA_REFERENCIA AND
        S.DHEMI BETWEEN :DA_REFERENCIA AND :DATA_FINAL   AND 
        --CF.CO_TIPO_TRIBUTACAO_SN IN (1, 3, 5, '83', '84') AND--IN ('1', '3', '5', '4', '5', '6') AND
        S.CO_FINNFE <> 3
        --CF.CO_CFOP NOT IN (SELECT SU.CO_CFOP FROM  BI.FATO_NFE_NFCE_SUMARIZADA SU WHERE SU.ICMS_CSOSN = '400' AND SU.CO_CFOP = '5949'AND SU.CO_EMITENTE = R.CO_CNPJ_CPF)  AND
        
    GROUP BY
        S.CO_EMITENTE,
        S.CO_MOD,
        s.icms_csosn,
        s.icms_cst,
        s.co_cfop;