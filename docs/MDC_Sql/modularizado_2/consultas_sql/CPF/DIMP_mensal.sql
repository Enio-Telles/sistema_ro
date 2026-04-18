WITH PARAMETROS AS (
    SELECT
        :CNPJ AS cnpj_filtro,
        TO_DATE(:data_inicial, 'DD/MM/YYYY') AS dt_ini_filtro,
        TO_DATE(:data_final,   'DD/MM/YYYY') AS dt_fim_filtro,
        /* O parâmetro de corte é mantido para padronização de inputs, mesmo que não usado na lógica transacional abaixo */
        NVL(TO_DATE(:data_limite_processamento, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_corte
    FROM dual
)

SELECT
    MP.CNPJ_CPF AS CPF,
    TO_CHAR(MP.DT_OP, 'MM/YYYY') AS MES_REFERENCIA,
    --D.NOME,

    -- Valores
    SUM(CASE WHEN MP.NAT_OPER = 1 THEN MP.VALOR ELSE 0 END) AS Credito,
    SUM(CASE WHEN MP.NAT_OPER = 2 THEN MP.VALOR ELSE 0 END) AS Debito,
    SUM(CASE WHEN MP.NAT_OPER = 6 THEN MP.VALOR ELSE 0 END) AS PIX,
    SUM(CASE WHEN MP.NAT_OPER = 7 THEN MP.VALOR ELSE 0 END) AS Voucher,
    SUM(MP.VALOR) AS TOTAL_VALOR_GERAL,

    -- Quantidades
    COUNT(*) AS Qtd_Operacoes

FROM BI.MPG_F_DETALHE_OPERACAO MP
INNER JOIN DIMP.REG0000S D ON MP.ID_REG0000 = D.ID AND MP.CNPJ_DECLARANTE = D.CNPJ
INNER JOIN PARAMETROS p ON MP.CNPJ_CPF = p.cnpj_filtro -- Join direto com parâmetros para filtro

WHERE MP.DT_OP BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro
  AND MP.FLAG_COMEX = 0
  AND MP.ID_ORIGEM_INFORMACAO = 'DIMP'
  AND MP.FLAG_CANCELADO = 0
  AND MP.NAT_OPER IN (1, 2, 6, 7)

GROUP BY
    --D.NOME,
    MP.CNPJ_CPF,
    TO_CHAR(MP.DT_OP, 'MM/YYYY'),
    TRUNC(MP.DT_OP, 'MM') -- Mantido para ajudar na ordenação
ORDER BY
    TRUNC(MP.DT_OP, 'MM') DESC;
