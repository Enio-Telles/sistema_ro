/* ============================================================================
   100_parametros_origem_nfe_fronteira_completo.sql
   ----------------------------------------------------------------------------
   Objetivo:
   - receber o CNPJ-alvo;
   - construir a base documental mínima das NF-e de entrada interestadual
     destinadas ao contribuinte em Rondônia;
   - servir de driving set para a trilha SITAFE/Fronteira completa.
============================================================================ */

WITH parametros AS (
    SELECT :cnpj AS cnpj_filtro FROM dual
),
origem_nfe AS (
    SELECT
        nf.chave_acesso,
        MAX(nf.nnf) AS nota,
        MAX(nf.co_emitente) AS cnpj_emit,
        MAX(nf.xnome_emit) AS nome_emit,
        MAX(nf.dhemi) AS emissao,
        MAX(nf.co_uf_emit) AS uf_emitente
    FROM bi.fato_nfe_detalhe nf
    JOIN parametros p
      ON nf.co_destinatario = p.cnpj_filtro
    WHERE nf.co_tp_nf = 1
      AND nf.co_uf_emit <> 'RO'
      AND nf.infprot_cstat IN ('100','150')
    GROUP BY nf.chave_acesso
)
SELECT *
FROM origem_nfe
ORDER BY emissao, cnpj_emit, nota;
