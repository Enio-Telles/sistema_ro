with www as (SELECT 1 ddd,
'84654326000394' cnpj,
'01/01/2022' data1,
'31/08/2023' data2,
'' cod_filtro  -- DEIXE VAZIO para trazer TODOS os códigos OU informe um código específico (ex: '99004730')
                                                from dual)

--TRATAMENTOS
-- traz somente CFOP VAF
-- não traz as entradas próprias - pois são preponderantemente são devoluções de consumidor final não contribuinte
-- traz somente C170 quando: o CFOP for de VAF; o CFOP for iniciado por 1, 2 ou 3 e o CFOP não for de devolução
-- pula as notas de entradas com valores vazios e informa quantas foram puladas
-- traz as unidades de medida somente das notas que compuseram o calculo
-- verificação de duplicatas COD + CHAVE_ACESSO

,cfop_vaf as (SELECT 1 ddd,
'' TODOS_CFOP        -- NIVEL 1: INLCUIR TODOS OS CFOPs (escreva 'SIM')  /  DEIXAR SOMENTE CFOP COM VAF (pode deixar vazio ou escrever diferente de 'SIM')
                                                                                                                                                        from dual)

,CFOP_AJ as (
    SELECT co_cfop, in_vaf,
        case when TODOS_CFOP = 'SIM' then 'X'
            when CO_CFOP in ('' ) AND in_vaf IS NULL then 'X'   --  NIVEL 2: INLCUIR CFOPs INDIVIDUALMENTE ou deixar vazio
            when CO_CFOP in ('' ) AND in_vaf = 'X'   then ''     -- NIVEL 2: EXCLUIR CFOPs INDIVIDUALMENTE ou deixar vazio
            else in_vaf
        end in_vaf_aj
    FROM bi.dm_cfop
    JOIN cfop_vaf ON cfop_vaf.ddd = 1
)

,estoque_final as (
    SELECT  -- ESTOQUE FINAL
        replace(replace(replace(LTRIM(h010.cod_item, '0'), ' ',''), '.', ''),'-','') AS COD,
        r0200.DESCR_ITEM,
        h010.UNID,
        H010.VL_UNIT,
        H010.VL_ITEM,
        h010.qtd QTDE
    FROM sped.reg_h010 h010
    LEFT JOIN sped.reg_0000 r0000 ON h010.REG_0000_ID = r0000.id
    JOIN sped.reg_0200 r0200 ON h010.cod_item = r0200.COD_ITEM AND r0200.REG_0000_ID = h010.REG_0000_ID
    INNER JOIN BI.DM_EFD_ARQUIVO_VALIDO ARQV ON h010.REG_0000_ID = ARQV.REG_0000_ID
    JOIN www ON www.ddd = 1
    WHERE r0000.cnpj = www.cnpj
        AND r0000.dt_ini = to_date('31/12'||'/'||SUBSTR(data2, 7,4), 'dd/mm/yyyy') + 32
        AND (www.cod_filtro IS NULL OR www.cod_filtro = '' OR replace(replace(replace(LTRIM(h010.cod_item, '0'), ' ',''), '.', ''),'-','') = www.cod_filtro)
)

,estoque_rept_cod as (
    SELECT
        ef.COD,
        COUNT(ef.COD) REPT_COD,
        LISTAGG(DISTINCT ef.UNID, ', ') WITHIN GROUP (ORDER BY ef.UNID) UNID
    FROM estoque_final ef
    GROUP BY ef.COD
)

,estoque_ajustado as (
    SELECT
        ef.COD,
        rc.REPT_COD,
        ef.DESCR_ITEM,
        rc.UNID,
        ef.VL_UNIT,
        ef.VL_ITEM,
        ef.QTDE
    FROM estoque_final ef
    JOIN estoque_rept_cod rc ON rc.cod = ef.cod
)

,NSU AS (
    SELECT NSU, CHAVE_ACESSO
    FROM bi.fato_nfe_detalhe
    JOIN www ON www.ddd = 1
    WHERE (co_emitente = cnpj OR co_destinatario = cnpj)
        AND dhemi BETWEEN CAST(www.data1 AS DATE) - 120 AND data2
        AND INFPROT_CSTAT IN ('100','150')
        AND SEQ_NITEM = 1
)

,ENTRADAS AS (
    SELECT  -- entradas de terceiros na EFD
        NVL(NSU.NSU, 0) NSU,
        c100.chv_nfe CHAVE_ACESSO,
        replace(replace(replace(LTRIM(c170.cod_item, '0'), ' ',''), '.', ''),'-','') AS COD,
        upper(r0200.descr_item) descricao,
        UNID,
        substr(c170.CFOP, 1, 4) CFOP,
        IN_VAF_AJ,
        (VL_ITEM - VL_DESC) VALOR,
        QTD,
        CASE WHEN VL_ITEM = 0 THEN 0 ELSE QTD END QTDE_AJ,
        1 AS CONTAR_NF,
        CASE WHEN VL_ITEM = 0 THEN 0 ELSE 1 END CONTAR_NF_AJ
    FROM sped.reg_c170 c170
    LEFT JOIN (SELECT id, chv_nfe FROM sped.reg_c100) c100 ON c170.REG_C100_ID = c100.id
    LEFT JOIN sped.reg_0000 r0000 ON c170.REG_0000_ID = r0000.id
    LEFT JOIN sped.reg_0200 r0200 ON (c170.cod_item = r0200.cod_item AND r0200.REG_0000_ID = r0000.id)
    INNER JOIN BI.DM_EFD_ARQUIVO_VALIDO ARQV ON c170.REG_0000_ID = ARQV.REG_0000_ID
    LEFT JOIN (SELECT CO_CFOP, nvl(IN_VAF_AJ, '-') IN_VAF_AJ FROM CFOP_AJ) CFOP ON substr(CFOP.CO_CFOP, 1, 4) = substr(c170.CFOP, 1, 4)
    LEFT JOIN NSU ON NSU.CHAVE_ACESSO = c100.chv_nfe
    JOIN www ON www.ddd = 1
    WHERE r0000.cnpj = www.cnpj
        AND substr(CFOP, 1, 1) IN ('1','2','3')
        AND r0000.dt_ini BETWEEN www.data1 AND www.data2
        AND (SUBSTR(c170.CFOP, 2,3) NOT BETWEEN '200' AND '249'
            OR SUBSTR(c170.CFOP, 2,3) NOT IN ('410','411','412','413','503','506','553','555','556','660','661','662','918','919'))
        AND (www.cod_filtro IS NULL OR www.cod_filtro = '' OR replace(replace(replace(LTRIM(c170.cod_item, '0'), ' ',''), '.', ''),'-','') = www.cod_filtro)
)

,QTDE_ACUM_ULTIMAS_NF AS (
    SELECT
        ET.COD,
        ET.NSU,
        ET.CHAVE_ACESSO,
        ET.QTD QTDE_NF,
        ET.QTDE_AJ QTDE_NF_AJ,
        ET.VALOR,
        AJ.QTDE QTDE_EF,
        ET.UNID UNID_NF,
        CONTAR_NF,
        CONTAR_NF_AJ,
        CFOP,
        SUM(ET.QTD) OVER (PARTITION BY ET.COD ORDER BY ET.NSU DESC) AS QTDE_ACUM_ULTIMAS_NF,
        SUM(ET.QTD) OVER (PARTITION BY ET.COD ORDER BY ET.NSU DESC) - ET.QTD AS QTDE_ANTERIOR,
        SUM(ET.QTDE_AJ) OVER (PARTITION BY ET.COD ORDER BY ET.NSU DESC) AS QTDE_ACUM_ULTIMAS_NF_AJ,
        SUM(ET.QTDE_AJ) OVER (PARTITION BY ET.COD ORDER BY ET.NSU DESC) - ET.QTDE_AJ AS QTDE_ANTERIOR_AJ
    FROM ENTRADAS ET
    JOIN estoque_ajustado AJ ON AJ.COD = ET.COD
)

,BASE_PEPS AS (
    SELECT
        COD,
        NSU,
        CHAVE_ACESSO,
        QTDE_NF,
        QTDE_NF_AJ,
        VALOR,
        QTDE_EF,
        NVL2(NULLIF(CONTAR_NF_AJ, 0), UNID_NF, NULL) UNID_NF,
        CONTAR_NF,
        CONTAR_NF_AJ,
        (CONTAR_NF - CONTAR_NF_AJ) NF_ZERO_VALOR,
        NVL2(NULLIF(CONTAR_NF_AJ, 0), CFOP, NULL) CFOP,
        QTDE_ACUM_ULTIMAS_NF,
        QTDE_ANTERIOR,
        QTDE_ACUM_ULTIMAS_NF_AJ,
        QTDE_ANTERIOR_AJ,
        -- Identificação de duplicatas por COD + CHAVE_ACESSO
        ROW_NUMBER() OVER (PARTITION BY COD, CHAVE_ACESSO ORDER BY NSU DESC) AS RN_DUPLICATA,
        COUNT(*) OVER (PARTITION BY COD, CHAVE_ACESSO) AS TOTAL_DUPLICATAS
    FROM QTDE_ACUM_ULTIMAS_NF
    WHERE (QTDE_ACUM_ULTIMAS_NF_AJ <= QTDE_EF OR QTDE_ANTERIOR_AJ < QTDE_EF)
        AND QTDE_ANTERIOR_AJ < QTDE_EF
)

,BASE_PEPS_DEDUPLICATED AS (
    SELECT
        COD, NSU, CHAVE_ACESSO, QTDE_NF, QTDE_NF_AJ, VALOR, QTDE_EF,
        UNID_NF, CONTAR_NF, CONTAR_NF_AJ, NF_ZERO_VALOR, CFOP,
        QTDE_ACUM_ULTIMAS_NF, QTDE_ANTERIOR, QTDE_ACUM_ULTIMAS_NF_AJ, QTDE_ANTERIOR_AJ,
        CASE WHEN TOTAL_DUPLICATAS > 1 THEN TOTAL_DUPLICATAS - 1 ELSE 0 END AS QTD_DUPLICATAS_REMOVIDAS
    FROM BASE_PEPS
    WHERE RN_DUPLICATA = 1  -- Mantém apenas o primeiro registro de cada combinação COD + CHAVE_ACESSO
)

,VERIFICACAO_DUPLICATAS AS (
    SELECT
        COD,
        CHAVE_ACESSO,
        (COUNT(*) - 1) AS QTD_DUPLICATAS_CHAVE
    FROM BASE_PEPS
    WHERE TOTAL_DUPLICATAS > 1
    GROUP BY COD, CHAVE_ACESSO
    HAVING COUNT(*) > 1
)

,DUPLICATAS_POR_COD AS (
    SELECT
        COD,
        SUM(QTD_DUPLICATAS_CHAVE) AS TOTAL_DUPLICATAS,
        LISTAGG(CHAVE_ACESSO || ' (' || QTD_DUPLICATAS_CHAVE || 'x)', '; ')
            WITHIN GROUP (ORDER BY CHAVE_ACESSO) AS DETALHES_DUPLICATAS
    FROM VERIFICACAO_DUPLICATAS
    GROUP BY COD
)

,VL_UNIT_PEPS AS (
    SELECT
        bp.COD,
        ROUND(SUM(bp.VALOR) / REPLACE(SUM(bp.QTDE_NF_AJ), 0, 1), 2) V_UNIT_PEPS,
        MAX(bp.QTDE_ACUM_ULTIMAS_NF_AJ) || ' volume(s) (' ||
            LISTAGG(DISTINCT bp.UNID_NF, ', ') WITHIN GROUP (ORDER BY bp.UNID_NF) || '); apuração em ' ||
            SUM(bp.CONTAR_NF) || ' últimos registros de entrada' ||
            NVL2(NULLIF(SUM(bp.NF_ZERO_VALOR), 0), '; ' || SUM(bp.NF_ZERO_VALOR) || ' registro(s) com valor de entrada ZERADOS', NULL) ||
            NVL2(MAX(dc.TOTAL_DUPLICATAS), '; ?? DUPLICATAS: ' || MAX(dc.TOTAL_DUPLICATAS) || ' registro(s) duplicado(s) - Chaves: ' || MAX(dc.DETALHES_DUPLICATAS), NULL)
        APURACAO,
        LISTAGG(DISTINCT bp.CFOP, ', ') WITHIN GROUP (ORDER BY bp.CFOP) CFOP
    FROM BASE_PEPS_DEDUPLICATED bp
    LEFT JOIN DUPLICATAS_POR_COD dc ON dc.COD = bp.COD
    GROUP BY bp.COD
)

,BASE_COMANDO_FINAL AS (
    SELECT
        ef.COD,
        ef.REPT_COD,
        ef.DESCR_ITEM,
        ef.UNID,
        ef.QTDE,
        ef.VL_ITEM,
        ef.VL_UNIT VL_UNIT_EST,
        nvl(V_UNIT_PEPS, 0) V_UNIT_PEPS,
        ef.VL_UNIT * ef.QTDE VL_UNIT_X_QTDE,
        nvl(V_UNIT_PEPS, 0) * ef.QTDE VL_UNIT_PEPS_X_QTDE,
        (ef.VL_UNIT * ef.QTDE - nvl(V_UNIT_PEPS, 0) * ef.QTDE) DIF,
        peps.APURACAO,
        peps.CFOP
    FROM estoque_ajustado ef
    JOIN VL_UNIT_PEPS peps ON peps.COD = ef.COD
)

SELECT
    COD,
    REPT_COD,
    DESCR_ITEM,
    UNID,
    QTDE,
    TO_CHAR(VL_ITEM, 'FM999G999G999G990D00') VL_TOTAL_E,
    TO_CHAR(VL_UNIT_EST, 'FM999G999G999G990D00') VL_UNIT_EST,
    TO_CHAR(V_UNIT_PEPS, 'FM999G999G999G990D00') V_UNIT_PEPS,
    TO_CHAR(VL_UNIT_X_QTDE, 'FM999G999G999G990D00') VL_UNIT_X_QTDE,
    TO_CHAR(VL_UNIT_PEPS_X_QTDE, 'FM999G999G999G990D00') VL_UNIT_PEPS_X_QTDE,
    TO_CHAR(DIF, 'FM999G999G999G990D00') DIFER,
    APURACAO,
    CFOP
FROM BASE_COMANDO_FINAL
ORDER BY COD
