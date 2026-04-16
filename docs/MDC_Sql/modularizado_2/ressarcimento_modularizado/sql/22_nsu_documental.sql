/*
===============================================================================
MUDANÇA DE TRIBUTAÇÃO ST - MÓDULO 22
NSU E UFs DOCUMENTAIS NO BI
-------------------------------------------------------------------------------
Objetivo:
- isolar o enriquecimento documental do BI;
- evitar misturar prova do documento com regra tributária da mudança.

Observação:
- a lógica de usar SEQ_NITEM = 1 é um atalho documental da consulta original.
===============================================================================
*/
WITH PARAMETROS AS (
    SELECT
        :CNPJ AS cnpj_filtro,
        TO_DATE(:data_inicial, 'DD/MM/YYYY') AS dt_ini_filtro,
        ADD_MONTHS(TO_DATE(NVL(:data_final, TO_CHAR(SYSDATE, 'DD/MM/YYYY')), 'DD/MM/YYYY'), 2) AS dt_fim_filtro
    FROM dual
)
SELECT
    nfe.nsu,
    nfe.chave_acesso,
    nfe.co_uf_emit,
    nfe.co_uf_dest
FROM bi.fato_nfe_detalhe nfe
JOIN PARAMETROS p
  ON 1 = 1
WHERE (nfe.co_emitente = p.cnpj_filtro OR nfe.co_destinatario = p.cnpj_filtro)
  AND nfe.dhemi BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro
  AND nfe.infprot_cstat IN ('100', '150')
  AND nfe.seq_nitem = 1;
