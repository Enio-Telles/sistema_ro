/*
===============================================================================
MÓDULO 07 - CANDIDATO ESCOLHIDO
-------------------------------------------------------------------------------
Objetivo
- Escolher o item vencedor da nota de entrada.
- Medir confiança do vínculo.
- Registrar quando o vínculo é determinístico, conflituoso ou ambíguo.

Granularidade
- 1 linha por item de saída com um único item de entrada escolhido.

Relevância
- Este módulo é o coração da explicabilidade do vínculo.
- Se ele estiver errado, o cálculo monetário poderá estar certo aritmeticamente,
  mas errado juridicamente por estar ancorado na entrada errada.
===============================================================================
*/

WITH candidatos AS (
    -- Este módulo assume como upstream a SQL:
    -- 06_score_candidatos_vinculo.sql
    SELECT *
    FROM (
        /* Substitua este bloco pelo conteúdo materializado do módulo 06 */
        SELECT * FROM score_candidatos_vinculo
    )
),
candidatos_flag AS (
    SELECT
        c.*,
        MAX(c.ind_match_cod_item) OVER (
            PARTITION BY c.chave_saida, c.num_item_saida, c.cod_item_saida, c.chave_nfe_ultima_entrada
        ) AS existe_match_cod_item
    FROM candidatos c
),
ranking_final AS (
    SELECT
        c.*,
        ROW_NUMBER() OVER (
            PARTITION BY c.chave_saida, c.num_item_saida, c.cod_item_saida, c.chave_nfe_ultima_entrada
            ORDER BY
                CASE
                    WHEN c.ind_match_cod_item = 1
                     AND c.ind_conflito_ncm = 0
                     AND c.ind_conflito_cest = 0
                    THEN 1 ELSE 0 END DESC,
                c.score_vinculo_entrada DESC,
                c.ind_match_cod_item DESC,
                c.ind_match_num_item_doc DESC,
                c.diff_qtd_vinculo ASC,
                c.num_item_ult_entr ASC
        ) AS rn,
        LEAD(c.score_vinculo_entrada) OVER (
            PARTITION BY c.chave_saida, c.num_item_saida, c.cod_item_saida, c.chave_nfe_ultima_entrada
            ORDER BY
                CASE
                    WHEN c.ind_match_cod_item = 1
                     AND c.ind_conflito_ncm = 0
                     AND c.ind_conflito_cest = 0
                    THEN 1 ELSE 0 END DESC,
                c.score_vinculo_entrada DESC,
                c.ind_match_cod_item DESC,
                c.ind_match_num_item_doc DESC,
                c.diff_qtd_vinculo ASC,
                c.num_item_ult_entr ASC
        ) AS score_segundo_colocado
    FROM candidatos_flag c
)
SELECT
    r.*,
    r.score_vinculo_entrada - NVL(r.score_segundo_colocado, 0) AS gap_top2,
    CASE
        WHEN r.ind_match_cod_item = 1
         AND r.ind_conflito_ncm = 0
         AND r.ind_conflito_cest = 0
        THEN 'VINCULO DETERMINISTICO POR COD_ITEM'
        WHEN r.ind_match_cod_item = 1
         AND (r.ind_conflito_ncm = 1 OR r.ind_conflito_cest = 1)
        THEN 'VINCULO POR COD_ITEM COM CONFLITO'
        WHEN r.existe_match_cod_item = 0
        THEN 'VINCULO POR CRITERIOS ALTERNATIVOS'
        ELSE 'VINCULO POR SCORE'
    END AS regra_vinculo_entrada,
    CASE
        WHEN r.score_vinculo_entrada - NVL(r.score_segundo_colocado, 0) < 8
        THEN 'EMPATE TECNICO OU CANDIDATO AMBIGUO'
        ELSE 'CANDIDATO DISTINTO'
    END AS status_gap_vinculo
FROM ranking_final r
WHERE r.rn = 1;
