/*
===============================================================================
MDC 24 - DIAGNÓSTICO DE NECESSIDADE DE CONVERSÃO DE UNIDADE
-------------------------------------------------------------------------------
Objetivo
- Identificar, nas trilhas de ressarcimento e de inventário / mudança de
  tributação, quando a comparação de quantidade exige conversão de unidade.

Pré-requisito
- As views do MDC 04, 06, 07 e 08 devem estar materializadas.

Saída esperada
- 1 linha por cenário auditável, com classificação:
  * SEM_CONVERSAO_NECESSARIA
  * CONVERSAO_OBRIGATORIA
  * CONVERSAO_PROVAVEL
  * INVESTIGAR_SEM_FATOR

Observação
- A query usa tolerância para detectar quando as quantidades “fecham” após
  aplicação do fator de conversão.
===============================================================================
*/
WITH params AS (
    SELECT 0.005 AS tolerancia FROM dual
),
produtos AS (
    SELECT * FROM mdc_efd_produtos
),
mov_itens AS (
    SELECT * FROM mdc_efd_c170
),
ressarc AS (
    SELECT * FROM mdc_efd_c176
),
inventario AS (
    SELECT * FROM mdc_efd_h
),
ressarc_base AS (
    SELECT
        'RESSARCIMENTO_C176' AS trilha,
        r.chave_saida        AS chave_referencia,
        r.cod_item,
        s.unid               AS unid_origem,
        p.unid_inv           AS unid_cadastral,
        p.unid_conv          AS unid_conv_0220,
        p.fat_conv,
        s.qtd                AS qtd_origem,
        r.quant_ult_e        AS qtd_destino,
        CASE WHEN NVL(TRIM(s.unid), '#') = NVL(TRIM(p.unid_inv), '#') THEN 0 ELSE 1 END AS flag_unidade_divergente,
        CASE WHEN p.fat_conv IS NOT NULL THEN 1 ELSE 0 END AS flag_tem_fator,
        CASE
            WHEN p.fat_conv IS NOT NULL
             AND r.quant_ult_e IS NOT NULL
             AND s.qtd IS NOT NULL
             AND ABS((s.qtd * p.fat_conv) - r.quant_ult_e) <= (SELECT tolerancia FROM params) * GREATEST(ABS(r.quant_ult_e), 1)
            THEN 1 ELSE 0 END AS fecha_multiplicando,
        CASE
            WHEN p.fat_conv IS NOT NULL
             AND p.fat_conv <> 0
             AND r.quant_ult_e IS NOT NULL
             AND s.qtd IS NOT NULL
             AND ABS((s.qtd / p.fat_conv) - r.quant_ult_e) <= (SELECT tolerancia FROM params) * GREATEST(ABS(r.quant_ult_e), 1)
            THEN 1 ELSE 0 END AS fecha_dividindo
    FROM ressarc r
    LEFT JOIN mov_itens s
           ON s.reg_c170_id = r.reg_c170_id
    LEFT JOIN produtos p
           ON p.reg_0000_id = s.reg_0000_id
          AND p.cod_item    = s.cod_item
),
ultima_entrada AS (
    SELECT *
    FROM (
        SELECT
            h.efd_ref,
            h.dt_inv,
            h.cod_item,
            h.unid         AS unid_inventario,
            h.qtd          AS qtd_inventario,
            h.vl_unit      AS vl_unit_inventario,
            e.chv_nfe      AS chave_entrada,
            e.dt_doc       AS dt_doc_entrada,
            e.unid         AS unid_entrada,
            e.qtd          AS qtd_entrada,
            e.vl_item,
            p.unid_inv     AS unid_cadastral,
            p.unid_conv    AS unid_conv_0220,
            p.fat_conv,
            ROW_NUMBER() OVER (
                PARTITION BY h.efd_ref, h.dt_inv, h.cod_item
                ORDER BY e.dt_doc DESC, e.chv_nfe DESC, e.num_item DESC
            ) AS rn
        FROM inventario h
        LEFT JOIN mov_itens e
               ON e.cod_item = h.cod_item
              AND e.ind_oper = '0'
              AND e.dt_doc  <= h.dt_inv
        LEFT JOIN produtos p
               ON p.reg_0000_id = h.reg_0000_id
              AND p.cod_item    = h.cod_item
    )
    WHERE rn = 1
),
inventario_base AS (
    SELECT
        'MUDANCA_TRIBUTACAO_H010_ULTIMA_ENTRADA' AS trilha,
        chave_entrada                            AS chave_referencia,
        cod_item,
        unid_inventario                          AS unid_origem,
        unid_cadastral,
        unid_conv_0220,
        fat_conv,
        qtd_inventario                           AS qtd_origem,
        qtd_entrada                              AS qtd_destino,
        CASE WHEN NVL(TRIM(unid_inventario), '#') = NVL(TRIM(unid_entrada), '#') THEN 0 ELSE 1 END AS flag_unidade_divergente,
        CASE WHEN fat_conv IS NOT NULL THEN 1 ELSE 0 END AS flag_tem_fator,
        CASE
            WHEN fat_conv IS NOT NULL
             AND qtd_entrada IS NOT NULL
             AND qtd_inventario IS NOT NULL
             AND ABS((qtd_inventario * fat_conv) - qtd_entrada) <= (SELECT tolerancia FROM params) * GREATEST(ABS(qtd_entrada), 1)
            THEN 1 ELSE 0 END AS fecha_multiplicando,
        CASE
            WHEN fat_conv IS NOT NULL
             AND fat_conv <> 0
             AND qtd_entrada IS NOT NULL
             AND qtd_inventario IS NOT NULL
             AND ABS((qtd_inventario / fat_conv) - qtd_entrada) <= (SELECT tolerancia FROM params) * GREATEST(ABS(qtd_entrada), 1)
            THEN 1 ELSE 0 END AS fecha_dividindo
    FROM ultima_entrada
),
base_union AS (
    SELECT * FROM ressarc_base
    UNION ALL
    SELECT * FROM inventario_base
)
SELECT
    b.trilha,
    b.chave_referencia,
    b.cod_item,
    b.unid_origem,
    b.unid_cadastral,
    b.unid_conv_0220,
    b.fat_conv,
    b.qtd_origem,
    b.qtd_destino,
    CASE
        WHEN NVL(b.flag_unidade_divergente, 0) = 0
         AND NVL(b.flag_tem_fator, 0) = 0
        THEN 'SEM_CONVERSAO_NECESSARIA'
        WHEN NVL(b.flag_unidade_divergente, 0) = 1
         AND (NVL(b.fecha_multiplicando, 0) = 1 OR NVL(b.fecha_dividindo, 0) = 1)
        THEN 'CONVERSAO_OBRIGATORIA'
        WHEN NVL(b.flag_unidade_divergente, 0) = 1
         AND NVL(b.flag_tem_fator, 0) = 1
        THEN 'CONVERSAO_OBRIGATORIA'
        WHEN NVL(b.flag_unidade_divergente, 0) = 0
         AND NVL(b.flag_tem_fator, 0) = 1
        THEN 'CONVERSAO_PROVAVEL'
        WHEN NVL(b.flag_unidade_divergente, 0) = 1
         AND NVL(b.flag_tem_fator, 0) = 0
        THEN 'INVESTIGAR_SEM_FATOR'
        ELSE 'INVESTIGAR_SEM_FATOR'
    END AS status_conversao,
    CASE
        WHEN NVL(b.flag_unidade_divergente, 0) = 0
         AND NVL(b.flag_tem_fator, 0) = 0
        THEN 'Mesma unidade e sem 0220 relevante.'
        WHEN NVL(b.flag_unidade_divergente, 0) = 1
         AND NVL(b.fecha_multiplicando, 0) = 1
        THEN 'Quantidade fecha multiplicando pelo fator de conversão.'
        WHEN NVL(b.flag_unidade_divergente, 0) = 1
         AND NVL(b.fecha_dividindo, 0) = 1
        THEN 'Quantidade fecha dividindo pelo fator de conversão.'
        WHEN NVL(b.flag_unidade_divergente, 0) = 1
         AND NVL(b.flag_tem_fator, 0) = 1
        THEN 'Unidades divergem e há 0220 cadastrado para o item.'
        WHEN NVL(b.flag_unidade_divergente, 0) = 0
         AND NVL(b.flag_tem_fator, 0) = 1
        THEN 'Há 0220 para o item; verificar se outras fontes usam unidade distinta.'
        WHEN NVL(b.flag_unidade_divergente, 0) = 1
         AND NVL(b.flag_tem_fator, 0) = 0
        THEN 'Unidades divergem, mas não foi localizado fator 0220.'
        ELSE 'Verificação manual necessária.'
    END AS justificativa
FROM base_union b
ORDER BY b.trilha, b.cod_item, b.chave_referencia;
