WITH PARAMETROS AS (
    SELECT 
        :CNPJ AS cnpj_filtro,
        NVL(TO_DATE(:data_inicial, 'DD/MM/YYYY'), TO_DATE('01/01/1900', 'DD/MM/YYYY')) AS dt_ini_filtro,
        NVL(TO_DATE(:data_final,   'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_fim_filtro,
        NVL(TO_DATE(:data_limite_processamento, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_corte
    FROM dual
),

ARQUIVOS_RANKING AS (
    /* Garante a utilização da última retificação do arquivo EFD */
    SELECT
        reg_0000.id AS reg_0000_id,
        reg_0000.cnpj,
        reg_0000.dt_ini,
        ROW_NUMBER() OVER (
            PARTITION BY reg_0000.cnpj, reg_0000.dt_ini 
            ORDER BY reg_0000.data_entrega DESC, reg_0000.id DESC
        ) AS rn       
    FROM sped.reg_0000 reg_0000
    JOIN PARAMETROS p ON reg_0000.cnpj = p.cnpj_filtro
    WHERE reg_0000.data_entrega <= p.dt_corte
      AND reg_0000.dt_ini BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro
),

BASE_NOTAS_FISCAIS AS (
    /* Consolidação de NF-e e NFC-e para comparação com o SPED */
    SELECT 
        CHAVE_ACESSO, 
        PROD_NITEM, 
        PROD_VPROD AS vl_item_doc,
        ICMS_VBC   AS vl_bc_icms_doc,
        ICMS_VICMS AS vl_icms_doc,
        'NFE'      AS origem_doc
    FROM bi.fato_nfe_detalhe
    WHERE co_emitente = (SELECT cnpj_filtro FROM PARAMETROS)
    
    UNION ALL
    
    SELECT 
        CHAVE_ACESSO, 
        PROD_NITEM, 
        PROD_VPROD AS vl_item_doc,
        ICMS_VBC   AS vl_bc_icms_doc,
        ICMS_VICMS AS vl_icms_doc,
        'NFCE'     AS origem_doc
    FROM bi.fato_nfce_detalhe
    WHERE co_emitente = (SELECT cnpj_filtro FROM PARAMETROS)
)

SELECT
    TO_CHAR(arq.dt_ini, 'MM/YYYY')                                   AS periodo_efd,
    c100.chv_nfe                                                     AS chave_saida_sped,
    c170.num_item                                                    AS item_sped,
    c170.cfop                                                        AS cfop_saida,
    
    -------------------------------------------------------------------------
    -- AUDITORIA (i): MOTIVO DE RESSARCIMENTO
    -------------------------------------------------------------------------
    CASE 
        WHEN SUBSTR(c170.cfop, 1, 1) = '6' THEN 'SIM - Operação Interestadual'
        WHEN c170.cfop IN ('5.927', '5.928') THEN 'SIM - Baixa de Estoque (Perda/Roubo)'
        WHEN c170.cfop LIKE '%.401' OR c170.cfop LIKE '%.403' THEN 'VERIFICAR - Retorno/Devolução'
        ELSE 'ATENÇÃO - CFOP Interno (Validar Regra Estadual)'
    END                                                              AS auditoria_motivo_saida,

    -------------------------------------------------------------------------
    -- COMPARAÇÃO SPED VS DOCUMENTO ELETRÔNICO (NF-e/NFC-e)
    -------------------------------------------------------------------------
    nf.origem_doc                                                    AS doc_digital_tipo,
    c170.vl_item                                                     AS vl_item_sped,
    nf.vl_item_doc                                                   AS vl_item_nf,
    CASE 
        WHEN nf.CHAVE_ACESSO IS NULL THEN 'ERRO: NF não encontrada no banco de notas'
        WHEN c170.vl_item <> nf.vl_item_doc THEN 'DIVERGENTE: Valor Item'
        ELSE 'OK'
    END                                                              AS auditoria_item_vs_nf,

    -------------------------------------------------------------------------
    -- RASTREABILIDADE DA ENTRADA (REGISTRO C176)
    -------------------------------------------------------------------------
    c176.chave_nfe_ult                                               AS chave_entrada_referenciada,
    CASE 
        WHEN c176.dt_ult_e IS NOT NULL AND REGEXP_LIKE(c176.dt_ult_e, '^\d{8}$')
        THEN TO_DATE(c176.dt_ult_e, 'DDMMYYYY')
        ELSE NULL
    END                                                              AS dt_entrada_referenciada,

    -------------------------------------------------------------------------
    -- VALIDAÇÕES DE CRONOLOGIA E VALORES UNITÁRIOS
    -------------------------------------------------------------------------
    CASE 
        WHEN TO_DATE(c100.dt_doc, 'DDMMYYYY') < TO_DATE(c176.dt_ult_e, 'DDMMYYYY') 
        THEN 'ERRO: Saída antes da Entrada'
        ELSE 'OK'
    END                                                              AS auditoria_cronologia,

    c176.vl_unit_res                                                 AS vl_unit_ressarcimento,
    (NVL(c170.qtd, 0) * NVL(c176.vl_unit_res, 0))                    AS total_ressarcimento_st,
    
    CASE 
        WHEN c176.vl_unit_res > c176.vl_unit_ult_e THEN 'ALERTA: Ressarcimento > Base BC ST'
        ELSE 'OK'
    END                                                              AS auditoria_valor_unitario

FROM sped.reg_c176 c176
INNER JOIN ARQUIVOS_RANKING arq ON c176.reg_0000_id = arq.reg_0000_id
INNER JOIN sped.reg_c100 c100   ON c176.reg_c100_id = c100.id
INNER JOIN sped.reg_c170 c170   ON c176.reg_c170_id = c170.id
-- Cruzamento com a base de Notas Fiscais Eletrônicas
LEFT JOIN BASE_NOTAS_FISCAIS nf 
    ON  c100.chv_nfe = nf.CHAVE_ACESSO 
    AND CAST(c170.num_item AS NUMBER) = nf.PROD_NITEM
WHERE arq.rn = 1
ORDER BY arq.dt_ini, c100.dt_doc, c170.num_item;