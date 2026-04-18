-- Consulta: DIMP_maquinas_por_endereco
-- Objetivo: Identificar todos os cod_mcapt (máquinas) para cada endereço
-- Baseada em: DIMP_maquina_ult_op.sql

SELECT
    r0.NOME AS INSTITUICAO,
    reg_0100.n_fant,
    reg_0100."END" AS endereco,
    reg_0100.cep,

    -- Agrupa todos os cod_mcapt em uma lista para cada endereço
    LISTAGG(DISTINCT mpg.cod_mcapt, ', ') WITHIN GROUP (ORDER BY mpg.cod_mcapt) AS maquinas,

    -- Conta quantas máquinas existem por endereço
    COUNT(DISTINCT mpg.cod_mcapt) AS qtd_maquinas,

    -- Última operação no endereço
    MAX(mpg.dt_op) AS ultima_dt_op

FROM bi.mpg_f_detalhe_operacao mpg
-- Join existente
LEFT JOIN dimp.reg0100s reg_0100
       ON reg_0100.REG0000_ID = mpg.ID_REG0000
-- Join para obter nome da instituição
LEFT JOIN dimp.reg0000s r0
       ON r0.ID = mpg.ID_REG0000
WHERE
   -- Busca flexível: remove caracteres especiais e compara apenas letras/números
   REGEXP_REPLACE(UPPER(reg_0100."END"), '[^A-Z0-9]', '')
   LIKE '%' || REGEXP_REPLACE(UPPER(:endereco), '[^A-Z0-9]', '') || '%'
GROUP BY
    r0.NOME,
    reg_0100.n_fant,
    reg_0100."END",
    reg_0100.cep
ORDER BY ultima_dt_op DESC;
