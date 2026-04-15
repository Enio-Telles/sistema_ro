SELECT
    d.nome,
    mp.cnpj_declarante,
    mp.cnpj_cpf        AS cnpj_favorecido,
    mp.cnpj_adquirente AS cnpj_liquidante_operacao,
    mp.dt_op,
    -- FORMATAÇÃO DA HORA AQUI:
    REGEXP_REPLACE(LPAD(h.hora, 6, '0'), '(\d{2})(\d{2})(\d{2})', '\1:\2:\3') AS hora,
    mp.valor,
    mp.flag_extemporaneo,
    mp.id_transac,
    mp.nat_oper_descricao,
    mp.flag_comex,
    mp.id_origem_informacao,
    mp.flag_cancelado,
    mp.nsu,
    d.reg,
    mp.id_reg1200,
    mp.cod_aut,
    mp.cod_mcapt,
    mp.id_reg0000,
    mp.id_mes_operacao,
    mp.id_reg1115
FROM
    bi.mpg_f_detalhe_operacao mp
    INNER JOIN dimp.reg0000s d 
        ON mp.id_reg0000 = d.id
        AND mp.cnpj_declarante = d.cnpj
    LEFT JOIN dimp.reg1115S h 
        ON h.id = mp.id_reg1115
WHERE
    mp.cnpj_cpf = REGEXP_REPLACE(:cpf, '\D+', '') 
    AND mp.dt_op BETWEEN :data_inicial AND :data_final
    AND mp.flag_comex = 0
    AND mp.id_origem_informacao = 'DIMP'
    AND mp.flag_cancelado = 0
    AND mp.nat_oper <> 5