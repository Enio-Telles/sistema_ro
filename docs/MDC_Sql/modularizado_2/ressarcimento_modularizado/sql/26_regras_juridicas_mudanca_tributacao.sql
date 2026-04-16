/*
===============================================================================
MUDANÇA DE TRIBUTAÇÃO ST - MÓDULO 26
CLASSIFICAÇÃO JURÍDICA INICIAL DA MUDANÇA DE TRIBUTAÇÃO
-------------------------------------------------------------------------------
Objetivo:
- separar evidência documental de elegibilidade tributária;
- preparar a base para crédito (E111) ou débito (E210/E220).

Atenção:
- este módulo NÃO presume, sozinho, que toda linha de H020 gera crédito.
- a direção da mudança (saindo da ST x entrando na ST) precisa ser confirmada
  com base normativa externa por NCM/CEST/vigência.
===============================================================================
*/
SELECT
    b.*,
    CASE
        WHEN b.mot_inv <> '02' THEN 'FORA DO ESCOPO PADRÃO DE MUDANÇA DE TRIBUTAÇÃO'
        WHEN b.reg_h020 IS NULL THEN 'INVENTÁRIO SEM H020'
        WHEN b.vl_icms_h020 IS NOT NULL AND b.vl_icms_h020 > 0 THEN 'POTENCIAL CRÉDITO OU DÉBITO - VALIDAR DIREÇÃO DA MUDANÇA'
        ELSE 'PENDENTE DE ENQUADRAMENTO NORMATIVO'
    END AS status_juridico_inicial,
    CASE
        WHEN b.mot_inv = '02' AND b.reg_h020 IS NOT NULL THEN 1
        ELSE 0
    END AS ind_inventario_apto_mudanca,
    CASE
        WHEN b.reg_h020 IS NOT NULL AND b.vl_icms_h020 IS NOT NULL THEN b.vl_icms_h020
        ELSE NULL
    END AS valor_h020_documental
FROM base_mudanca_tributacao b;
