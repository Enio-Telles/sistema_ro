SELECT
    to_char(a.da_inicio_arquivo, 'YYYY/MM')                          AS periodo_efd,
    a.da_entrega_arquivo                                             AS data_entrega_efd_periodo,
    a.in_codigo_finalidade                                           AS cod_fin_efd,
    CAST('Estoque' AS VARCHAR2(20))                                  AS entrada_saida,
    to_date(d.dt_inv, 'DD/MM/YYYY')                                  AS data_inv,
    EXTRACT(YEAR FROM to_date(d.dt_inv, 'DD/MM/YYYY') + 1)           AS ano,
    --d.mot_inv,
    CAST(
        CASE
            WHEN d.mot_inv = 01    THEN
                '01 - No final no período'
            WHEN d.mot_inv = 02    THEN
                '02 - Na mudança de forma de tributação da mercadoria (ICMS)'
            WHEN d.mot_inv = 03    THEN
                '03 - Na solicitação da baixa cadastral, paralisação temporária e outras situações'
            WHEN d.mot_inv = 04    THEN
                '04 - Na alteração de regime de pagamento – condição do contribuinte'
            WHEN d.mot_inv = 05    THEN
                '05 - Por determinação dos fiscos'
            WHEN d.mot_inv = 06    THEN
                '06 - Para controle das mercadorias sujeitas ao regime de substituição tributária – restituição/ ressarcimento/ complementação'
            ELSE
                'Desconhecido'
        END
    AS VARCHAR2(100))                                                AS descr_compl,
    
    d.vl_inv
    
FROM
         bi.dm_efd_arquivo_valido a
    INNER JOIN bi.dm_contribuinte    c ON a.co_cnpj_cpf_declarante = c.co_cnpj_cpf
    LEFT JOIN sped.reg_h005         d ON d.reg_0000_id = a.reg_0000_id
WHERE
        a.co_cnpj_cpf_declarante = :cnpj
    AND a.da_inicio_arquivo BETWEEN :inicio AND add_months(:fim, 2)
    AND d.dt_inv IS NOT NULL
ORDER BY
    data_inv