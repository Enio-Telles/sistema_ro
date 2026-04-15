/*
===============================================================================
MÓDULO 13 - RECONCILIAÇÃO COM O BLOCO E (E111 / E210 / E220)
-------------------------------------------------------------------------------
Objetivo
- Fechar a análise item a item com a apuração mensal da EFD.
- Comparar o total apurado na malha analítica com os ajustes informados no
  Bloco E.

Granularidade
- 1 linha por período EFD, tipo de valor reconciliado e código de ajuste.

Premissas
- Este módulo parte da visão `base_final_ressarcimento` gerada no módulo 10.
- Ele pode ser executado mesmo sem o módulo 14.
- Quando o módulo 14 estiver disponível e parametrizado, recomenda-se trocar a
  coluna de ICMS próprio documental pela coluna juridicamente elegível.

Atenção
- Os códigos de ajuste abaixo devem ser validados e parametrizados conforme a
  norma vigente, o ambiente do cliente e a data de apuração.
- Em alguns ambientes, os nomes físicos de E111, E210 e E220 podem variar.
===============================================================================
*/

WITH
base_final AS (
    SELECT *
    FROM base_final_ressarcimento
),

/*
Tabela paramétrica mínima de códigos de ajuste.
Preencha, ajuste ou externalize esta CTE para tabela física de governança.

Campos:
- tipo_valor: o que a malha item a item está conciliando;
- bloco_destino: onde se espera encontrar o ajuste na EFD;
- cod_ajuste: código do ajuste;
- dt_ini_vig / dt_fim_vig: janela de vigência do código;
- observacao: documentação operacional.
*/
param_codigos_ajuste AS (
    SELECT 'RESSARC_ST' AS tipo_valor,
           'E111'       AS bloco_destino,
           'RO020022'   AS cod_ajuste,
           DATE '1900-01-01' AS dt_ini_vig,
           DATE '2024-12-31' AS dt_fim_vig,
           'Exemplo legado para ressarcimento/compensacao ST em conta grafica' AS observacao
    FROM dual
    UNION ALL
    SELECT 'ICMS_PROPRIO', 'E111', 'RO020023', DATE '1900-01-01', DATE '2024-12-31',
           'Exemplo legado para credito da operacao propria, quando permitido'
    FROM dual
    UNION ALL
    SELECT 'RESSARC_ST', 'E111', 'RO020047', DATE '2025-01-01', NULL,
           'Exemplo posterior a alteracao de codigos de ajuste - validar na governanca local'
    FROM dual
    UNION ALL
    SELECT 'ICMS_PROPRIO', 'E111', 'RO020049', DATE '2025-01-01', NULL,
           'Exemplo posterior a alteracao de codigos de ajuste - validar na governanca local'
    FROM dual
),

/*
Resumo do resultado analítico por período.
Se o projeto passar a usar o módulo 14, substitua:
- total_icms_proprio_documental
por
- total_icms_proprio_juridicamente_elegivel
*/
base_periodizada AS (
    SELECT
        b.reg_0000_id,
        b.comp_efd,
        MIN(b.dt_emissao_saida) AS dt_primeira_saida,
        MAX(b.dt_emissao_saida) AS dt_ultima_saida,
        COUNT(*) AS qtd_linhas_item,
        SUM(NVL(b.ressarc_st_considerado, 0)) AS total_ressarc_st_considerado,
        SUM(NVL(b.ressarc_icms_proprio_considerado, 0)) AS total_icms_proprio_documental,
        SUM(NVL(b.dif_st_considerada, 0)) AS total_dif_st_considerada,
        SUM(NVL(b.dif_icms_prop_considerada, 0)) AS total_dif_icms_prop_considerada
    FROM base_final b
    GROUP BY
        b.reg_0000_id,
        b.comp_efd
),

base_periodizada_explodida AS (
    SELECT
        p.reg_0000_id,
        p.comp_efd,
        p.qtd_linhas_item,
        p.dt_primeira_saida,
        p.dt_ultima_saida,
        'RESSARC_ST' AS tipo_valor,
        p.total_ressarc_st_considerado AS vl_malha_analitica,
        p.total_dif_st_considerada AS vl_diferenca_itemizada
    FROM base_periodizada p

    UNION ALL

    SELECT
        p.reg_0000_id,
        p.comp_efd,
        p.qtd_linhas_item,
        p.dt_primeira_saida,
        p.dt_ultima_saida,
        'ICMS_PROPRIO' AS tipo_valor,
        p.total_icms_proprio_documental AS vl_malha_analitica,
        p.total_dif_icms_prop_considerada AS vl_diferenca_itemizada
    FROM base_periodizada p
),

e111_raw AS (
    SELECT
        e111.reg_0000_id,
        e111.cod_aj_apur,
        e111.vl_aj_apur
    FROM sped.reg_e111 e111
),

e111_agregado AS (
    SELECT
        a.reg_0000_id,
        a.comp_efd,
        p.tipo_valor,
        p.bloco_destino,
        p.cod_ajuste,
        SUM(NVL(e.vl_aj_apur, 0)) AS vl_bloco_e,
        LISTAGG(DISTINCT p.cod_ajuste, ', ') WITHIN GROUP (ORDER BY p.cod_ajuste) AS codigos_conciliados
    FROM base_periodizada_explodida a
    JOIN param_codigos_ajuste p
      ON p.bloco_destino = 'E111'
     AND p.tipo_valor = a.tipo_valor
     AND a.comp_efd >= p.dt_ini_vig
     AND (p.dt_fim_vig IS NULL OR a.comp_efd <= p.dt_fim_vig)
    LEFT JOIN e111_raw e
      ON e.reg_0000_id = a.reg_0000_id
     AND e.cod_aj_apur = p.cod_ajuste
    GROUP BY
        a.reg_0000_id,
        a.comp_efd,
        p.tipo_valor,
        p.bloco_destino,
        p.cod_ajuste
),

/*
Bloco E210/E220.
Ajuste a estrutura caso o schema local use chaves ou nomes físicos diferentes.
*/
e220_raw AS (
    SELECT
        e210.reg_0000_id,
        e220.cod_aj_apur,
        e220.vl_aj_apur
    FROM sped.reg_e210 e210
    JOIN sped.reg_e220 e220
      ON e220.reg_e210_id = e210.id
     AND e220.reg_0000_id = e210.reg_0000_id
),

e220_agregado AS (
    SELECT
        a.reg_0000_id,
        a.comp_efd,
        p.tipo_valor,
        p.bloco_destino,
        p.cod_ajuste,
        SUM(NVL(e.vl_aj_apur, 0)) AS vl_bloco_e,
        LISTAGG(DISTINCT p.cod_ajuste, ', ') WITHIN GROUP (ORDER BY p.cod_ajuste) AS codigos_conciliados
    FROM base_periodizada_explodida a
    JOIN param_codigos_ajuste p
      ON p.bloco_destino = 'E220'
     AND p.tipo_valor = a.tipo_valor
     AND a.comp_efd >= p.dt_ini_vig
     AND (p.dt_fim_vig IS NULL OR a.comp_efd <= p.dt_fim_vig)
    LEFT JOIN e220_raw e
      ON e.reg_0000_id = a.reg_0000_id
     AND e.cod_aj_apur = p.cod_ajuste
    GROUP BY
        a.reg_0000_id,
        a.comp_efd,
        p.tipo_valor,
        p.bloco_destino,
        p.cod_ajuste
),

bloco_e_agregado AS (
    SELECT * FROM e111_agregado
    UNION ALL
    SELECT * FROM e220_agregado
),

reconciliacao AS (
    SELECT
        a.reg_0000_id,
        a.comp_efd,
        a.tipo_valor,
        b.bloco_destino,
        b.cod_ajuste,
        a.qtd_linhas_item,
        a.dt_primeira_saida,
        a.dt_ultima_saida,
        a.vl_malha_analitica,
        a.vl_diferenca_itemizada,
        NVL(b.vl_bloco_e, 0) AS vl_bloco_e,
        a.vl_malha_analitica - NVL(b.vl_bloco_e, 0) AS dif_malha_vs_bloco_e,
        b.codigos_conciliados,
        CASE
            WHEN b.cod_ajuste IS NULL THEN 'SEM CODIGO PARAMETRIZADO'
            WHEN ABS(a.vl_malha_analitica - NVL(b.vl_bloco_e, 0)) <= 0.01 THEN 'CONCILIADO'
            WHEN ABS(a.vl_malha_analitica - NVL(b.vl_bloco_e, 0)) <= 10 THEN 'DIFERENCA BAIXA'
            ELSE 'DIVERGENCIA RELEVANTE'
        END AS status_reconciliacao
    FROM base_periodizada_explodida a
    LEFT JOIN bloco_e_agregado b
      ON b.reg_0000_id = a.reg_0000_id
     AND b.comp_efd = a.comp_efd
     AND b.tipo_valor = a.tipo_valor
)
SELECT *
FROM reconciliacao
ORDER BY
    comp_efd,
    tipo_valor,
    bloco_destino,
    cod_ajuste;
