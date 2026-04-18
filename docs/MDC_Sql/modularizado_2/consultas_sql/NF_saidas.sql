-- tab=NFE
-- FILTRAR NFE's EMITIDAS POR CONTRIBUINTES DE RONDÔNIA NO PERÍODO PESQUISADO. APENAS NFE DE SAÍDAS E NÃO CANCELADAS

     SELECT
        d.CO_EMITENTE AS cnpj_emitente,
        d.co_destinatario AS cnpj_destinatario,
        D.CO_TP_NF AS TIPO_NF,
        d.nsu,
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
        d.nsu,
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
        d.nsu,
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
        d.nsu,
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
