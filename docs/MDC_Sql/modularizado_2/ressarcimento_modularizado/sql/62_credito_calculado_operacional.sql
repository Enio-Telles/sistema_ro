/*
===============================================================================
MÓDULO 62 - CRÉDITO CALCULADO OPERACIONAL
-------------------------------------------------------------------------------
Objetivo
- Reproduzir a CTE CREDITO_CALCULADO da query original.

Leitura crítica
- Esta fórmula é útil para reconstrução analítica do crédito próprio, mas não
  deve ser confundida com autorização jurídica automática de apropriação.
===============================================================================
*/

WITH chaves_alvo AS (
    SELECT chave_acesso
    FROM tabela_chaves_alvo
)
SELECT
    nf.chave_acesso,
    nf.prod_nitem,
    ROUND(
        CASE
            WHEN nf.icms_orig IN ('1', '2', '3', '8') THEN 0.04
            ELSE (
                SELECT uf.aliq
                FROM qvw.tbl_aliq_ufs uf
                WHERE nf.co_uf_emit = uf.uf
            )
        END * (
            NVL(nf.prod_vprod, 0)
          + NVL(nf.prod_vfrete, 0)
          + NVL(nf.prod_vseg, 0)
          - NVL(nf.prod_vdesc, 0)
          + NVL(nf.prod_voutro, 0)
        ),
        2
    ) AS cred_calc
FROM bi.fato_nfe_detalhe nf
JOIN chaves_alvo c
  ON nf.chave_acesso = c.chave_acesso
ORDER BY nf.chave_acesso, nf.prod_nitem;
