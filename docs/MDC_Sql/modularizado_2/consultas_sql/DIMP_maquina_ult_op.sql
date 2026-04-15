SELECT
    r0.NOME AS INSTITUICAO,
    mpg.cod_mcapt,
    :cpf AS cpf_consultado,
    reg_0100.n_fant,
    reg_0100."END" AS endereco,
    reg_0100.cep,
    
    MAX(mpg.dt_op) AS ultima_dt_op
FROM bi.mpg_f_detalhe_operacao mpg

LEFT JOIN dimp.reg0100s reg_0100 
       ON reg_0100.REG0000_ID = mpg.ID_REG0000  

LEFT JOIN dimp.reg0000s r0 
       ON r0.ID = mpg.ID_REG0000
WHERE mpg.CNPJ_CPF = :cpf 
  AND reg_0100.CPF = :cpf
GROUP BY 
    r0.NOME, 
    mpg.cod_mcapt,
    reg_0100.n_fant,
    reg_0100."END",
    reg_0100.cep
ORDER BY ultima_dt_op DESC;