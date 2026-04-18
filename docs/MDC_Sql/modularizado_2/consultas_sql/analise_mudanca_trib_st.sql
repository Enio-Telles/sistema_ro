WITH PARAMETROS AS (
    SELECT
        :CNPJ                                   AS cnpj_filtro,
        TO_DATE(:data_inicial, 'DD/MM/YYYY')    AS dt_ini_filtro,
        -- Se :data_final for nulo, usa a data atual (SYSDATE) antes de adicionar os 2 meses
        ADD_MONTHS(
            TO_DATE(NVL(:data_final, TO_CHAR(SYSDATE, 'DD/MM/YYYY')), 'DD/MM/YYYY'),
            2
        )                                       AS dt_fim_filtro,
        NULLIF(:cod_item, '')                   AS cod_filtro,
        NVL(TO_DATE(:data_limite_processamento, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_corte,
        TO_DATE(NULLIF(:data_inventario, ''), 'DD/MM/YYYY') AS dt_inv_especifica
    FROM dual
),

-- Ranking para pegar apenas a versão mais recente do arquivo SPED (trata retificações)
ARQUIVOS_RANKING AS (
    SELECT
        r.id AS reg_0000_id,
        r.cnpj,
        r.dt_ini,
        p.cod_filtro,
        p.dt_inv_especifica,
        ROW_NUMBER() OVER (
            PARTITION BY r.cnpj, r.dt_ini
            ORDER BY r.data_entrega DESC
        ) AS rn
    FROM sped.reg_0000 r
    JOIN PARAMETROS p ON r.cnpj = p.cnpj_filtro
    WHERE
        r.data_entrega <= p.dt_corte
        AND r.dt_ini BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro
),

-- Extrai dados do inventário (H005 + H010 + 0200)
estoque AS (
    SELECT
        TO_DATE(h005.dt_inv, 'DDMMYYYY') AS dt_inv,
        h005.mot_inv,
        REPLACE(REPLACE(REPLACE(LTRIM(h010.cod_item, '0'), ' ', ''), '.', ''), '-', '') AS cod,
        h010.cod_item AS cod_original,
        r0200.descr_item,
        h010.unid,
        h010.vl_unit AS vl_unit_inventario,
        h010.vl_item AS vl_total_inventario,
        h010.qtd AS qtde_inventario,
        arq.dt_ini AS data_arquivo_sped
    FROM sped.reg_h010 h010
    INNER JOIN ARQUIVOS_RANKING arq ON h010.reg_0000_id = arq.reg_0000_id
    INNER JOIN sped.reg_0200 r0200 ON h010.cod_item = r0200.cod_item
                                   AND h010.reg_0000_id = r0200.reg_0000_id
    LEFT JOIN sped.reg_h005 h005 ON h005.reg_0000_id = h010.reg_0000_id
    WHERE
        arq.rn = 1 -- Apenas versão mais recente do SPED
        AND (
            arq.cod_filtro IS NULL
            OR REPLACE(REPLACE(REPLACE(LTRIM(h010.cod_item, '0'), ' ', ''), '.', ''), '-', '') = arq.cod_filtro
        )
        AND (
            arq.dt_inv_especifica IS NULL
            OR TO_DATE(h005.dt_inv, 'DDMMYYYY') = arq.dt_inv_especifica
        )
),

-- CTE Auxiliar para buscar NSU (mantida conforme original)
NSU AS (
    SELECT NSU, CHAVE_ACESSO
    FROM bi.fato_nfe_detalhe
    JOIN PARAMETROS p ON 1=1
    WHERE (co_emitente = p.cnpj_filtro OR co_destinatario = p.cnpj_filtro)
      AND dhemi BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro
      AND INFPROT_CSTAT IN ('100','150')
      AND SEQ_NITEM = 1
),

-- ENTRADAS (C170 + C100)
-- Importante: Adicionada a Data do Documento (dt_doc) para comparação temporal
ENTRADAS AS (
    SELECT
        NVL(NSU.NSU, 0) AS NSU,
        c100.chv_nfe AS CHAVE_ACESSO,
        -- Normaliza o código do item para bater com o inventário
        replace(replace(replace(LTRIM(c170.cod_item, '0'), ' ',''), '.', ''),'-','') AS COD,
        c100.dt_doc, -- Data de Emissão (Crucial para achar a última entrada)
        c170.unid,
        c170.cfop,
        (c170.vl_item - NVL(c170.vl_desc,0)) AS valor_total_item,
        c170.qtd,
        -- Cálculo do Custo Unitário na Entrada
        CASE WHEN c170.qtd > 0
             THEN (c170.vl_item - NVL(c170.vl_desc,0)) / c170.qtd
             ELSE 0
        END AS vl_unit_entrada
    FROM sped.reg_c170 c170
    INNER JOIN sped.reg_c100 c100 ON c170.REG_C100_ID = c100.id
    -- Join com ARQUIVOS_RANKING para garantir que estamos olhando entradas de arquivos válidos
    INNER JOIN ARQUIVOS_RANKING arq ON c170.REG_0000_ID = arq.reg_0000_id AND arq.rn = 1
    LEFT JOIN NSU ON NSU.CHAVE_ACESSO = c100.chv_nfe
    JOIN PARAMETROS p ON 1=1
    WHERE
        substr(c170.CFOP, 1, 1) IN ('1','2','3') -- Apenas Entradas
        AND c100.ind_oper = '0' -- 0 = Entrada
        AND c100.cod_sit = '00' -- Documento regular
        AND (p.cod_filtro IS NULL OR replace(replace(replace(LTRIM(c170.cod_item, '0'), ' ',''), '.', ''),'-','') = p.cod_filtro)
),

-- Ranking das entradas relativo ao inventário
-- Aqui cruzamos o Estoque com as Entradas e pegamos a última entrada ANTES da data do inventário
RANKING_ENTRADAS AS (
    SELECT
        est.cod,
        est.dt_inv,
        ent.dt_doc AS data_ultima_compra,
        ent.vl_unit_entrada,
        ent.chave_acesso,
        ent.cfop,
        ROW_NUMBER() OVER (
            PARTITION BY est.cod, est.dt_inv
            ORDER BY ent.dt_doc DESC, ent.nsu DESC
        ) as rn
    FROM estoque est
    INNER JOIN ENTRADAS ent ON est.cod = ent.cod
    WHERE ent.dt_doc <= est.dt_inv -- Filtra entradas futuras (posteriores ao inventário)
)

-- Select Final: Junta o Estoque com a Última Entrada calculada
SELECT
    e.dt_inv AS data_inventario,
    e.cod AS codigo_item,
    e.descr_item,
    e.unid AS unidade_inventario,
    e.qtde_inventario,
    e.vl_unit_inventario,
    e.vl_total_inventario,
    -- Dados da Última Entrada encontrada
    ue.data_ultima_compra,
    ue.vl_unit_entrada AS vl_unit_ultima_entrada,
    ue.cfop AS cfop_ultima_entrada,
    ue.chave_acesso AS chave_nfe_ultima_entrada,
    -- Comparativo (Diferença)
    (e.vl_unit_inventario - NVL(ue.vl_unit_entrada, 0)) AS diff_valor_unitario
FROM estoque e
LEFT JOIN RANKING_ENTRADAS ue
    ON e.cod = ue.cod
    AND e.dt_inv = ue.dt_inv
    AND ue.rn = 1 -- Pega apenas a TOP 1 entrada (a mais recente)
ORDER BY e.dt_inv DESC, e.cod
