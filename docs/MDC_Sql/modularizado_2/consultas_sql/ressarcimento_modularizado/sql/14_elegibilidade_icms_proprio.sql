/*
===============================================================================
MÓDULO 14 - ELEGIBILIDADE JURÍDICA DO ICMS PRÓPRIO
-------------------------------------------------------------------------------
Objetivo
- Separar o valor documental do ICMS próprio do valor juridicamente elegível.
- Impedir que a visão final trate automaticamente como apropriável tudo o que
  aparece reconstruído no XML ou informado no C176.

Granularidade
- 1 linha por item de saída analisado.

Premissa jurídica
- O valor do ICMS próprio somente deve ser apropriado quando a hipótese legal
  permitir esse crédito.
- Este módulo foi desenhado para ser PARAMETRIZÁVEL.
- Não foi hardcoded um mapa fechado de `cod_mot_res`, porque isso precisa ser
  validado contra a política jurídica adotada pelo projeto.

Como usar
1. Preencher a CTE `matriz_elegibilidade` com as hipóteses válidas.
2. Opcionalmente enriquecer a base com CFOP/CST/CSOSN/natureza da saída.
3. Substituir a coluna documental por esta coluna elegível na reconciliação do
   Bloco E e nos relatórios finais.
===============================================================================
*/

WITH base_final AS (
    SELECT *
    FROM base_final_ressarcimento
),

/*
Matriz de elegibilidade jurídica.

Sugestão de governança:
- mover esta matriz para tabela física versionada;
- manter aprovação da área tributária;
- registrar vigência da interpretação.

Campos:
- cod_mot_res: código do motivo de ressarcimento informado no C176;
- hipotese_juridica: descrição controlada da hipótese;
- ind_permite_icms_proprio: S/N;
- exige_validacao_adicional: S/N;
- observacao_tributaria: racional normativo ou orientação interna.
*/
matriz_elegibilidade AS (
    SELECT
        CAST(NULL AS VARCHAR2(10))  AS cod_mot_res,
        CAST(NULL AS VARCHAR2(200)) AS hipotese_juridica,
        CAST(NULL AS VARCHAR2(1))   AS ind_permite_icms_proprio,
        CAST(NULL AS VARCHAR2(1))   AS exige_validacao_adicional,
        CAST(NULL AS VARCHAR2(400)) AS observacao_tributaria
    FROM dual
    WHERE 1 = 0

    /*
    Exemplos ilustrativos para ativar quando a área tributária validar:

    UNION ALL
    SELECT 'XX', 'HIPOTESE COM CREDITO PROPRIO PERMITIDO', 'S', 'N',
           'Preencher fundamento normativo validado'
    FROM dual

    UNION ALL
    SELECT 'YY', 'HIPOTESE COM VEDACAO DE ICMS PROPRIO', 'N', 'N',
           'Preencher fundamento normativo validado'
    FROM dual
    */
),

base_juridica AS (
    SELECT
        b.*,
        m.hipotese_juridica,
        m.ind_permite_icms_proprio,
        m.exige_validacao_adicional,
        m.observacao_tributaria,
        CASE
            WHEN b.cod_mot_res IS NULL THEN 'SEM COD_MOT_RES'
            WHEN m.cod_mot_res IS NULL THEN 'PENDENTE PARAMETRIZACAO JURIDICA'
            WHEN m.ind_permite_icms_proprio = 'S'
             AND NVL(m.exige_validacao_adicional, 'N') = 'N'
            THEN 'ICMS PROPRIO PERMITIDO'
            WHEN m.ind_permite_icms_proprio = 'S'
             AND NVL(m.exige_validacao_adicional, 'N') = 'S'
            THEN 'PERMITIDO SUJEITO A VALIDACAO ADICIONAL'
            WHEN m.ind_permite_icms_proprio = 'N'
            THEN 'ICMS PROPRIO VEDADO'
            ELSE 'STATUS NAO CLASSIFICADO'
        END AS status_elegibilidade_icms_proprio,
        CASE
            WHEN m.ind_permite_icms_proprio = 'S'
             AND NVL(m.exige_validacao_adicional, 'N') = 'N'
            THEN NVL(b.ressarc_icms_proprio_considerado, 0)
            WHEN m.ind_permite_icms_proprio = 'N'
            THEN 0
            ELSE NULL
        END AS ressarc_icms_proprio_juridicamente_elegivel,
        CASE
            WHEN m.ind_permite_icms_proprio = 'S'
             AND NVL(m.exige_validacao_adicional, 'N') = 'N'
            THEN NVL(b.ressarc_st_considerado, 0) + NVL(b.ressarc_icms_proprio_considerado, 0)
            WHEN m.ind_permite_icms_proprio = 'N'
            THEN NVL(b.ressarc_st_considerado, 0)
            ELSE NULL
        END AS ressarc_total_juridicamente_sugerido,
        CASE
            WHEN m.ind_permite_icms_proprio = 'S'
             AND NVL(m.exige_validacao_adicional, 'N') = 'N'
            THEN 0
            WHEN m.ind_permite_icms_proprio = 'N'
            THEN NVL(b.ressarc_icms_proprio_considerado, 0)
            ELSE NULL
        END AS vl_icms_proprio_potencialmente_glosavel
    FROM base_final b
    LEFT JOIN matriz_elegibilidade m
      ON m.cod_mot_res = b.cod_mot_res
)
SELECT *
FROM base_juridica
ORDER BY
    comp_efd,
    dt_emissao_saida,
    chave_saida,
    num_item_saida,
    num_item_ult_entr;
