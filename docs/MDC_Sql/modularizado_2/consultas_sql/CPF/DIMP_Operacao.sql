WITH PARAMETROS AS (
    SELECT
        :CPF AS cnpj_filtro, -- Atende tanto CNPJ quanto CPF conforme comentrio original
        TO_DATE(:data_inicial, 'DD/MM/YYYY') AS dt_ini_filtro,
        TO_DATE(:data_final,   'DD/MM/YYYY') AS dt_fim_filtro
    FROM DUAL
)

SELECT
    D.NOME,
    MP.CNPJ_DECLARANTE,
    MP.CNPJ_CPF AS FAVORECIDO,
    MP.CNPJ_ADQUIRENTE AS CNPJ_LIQUIDANTE_OPERACAO,
    MP.DT_OP,
    MP.VALOR,
    MP.FLAG_EXTEMPORANEO,
    MP.ID_TRANSAC,
    MP.NAT_OPER_DESCRICAO

FROM BI.MPG_F_DETALHE_OPERACAO MP
INNER JOIN DIMP.REG0000S D ON MP.ID_REG0000 = D.ID AND MP.CNPJ_DECLARANTE = D.CNPJ
INNER JOIN PARAMETROS p ON MP.CNPJ_CPF = p.cnpj_filtro

WHERE MP.DT_OP BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro
  AND MP.FLAG_COMEX = 0
  --AND ((MP.CNPJ_ADQUIRENTE = MP.CNPJ_DECLARANTE) OR (MP.CNPJ_ADQUIRENTE IS NULL))   --COM COMENT�RIO: IGUAL VIS�O 360 / SEM COMENT�RIO: IGUAL FISCONFORME
  AND MP.ID_ORIGEM_INFORMACAO = 'DIMP'
  AND MP.FLAG_CANCELADO = 0
  AND MP.NAT_OPER <> 5 -- Pagamento efetuado em dinheiro ou por outra estrutura

--Se quiser uma query que traga as informa��es do Fiscofnorme precisa desmarcar o campo --AND MP.NAT_OPER <> 5
