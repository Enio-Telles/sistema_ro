SELECT
    a.cod_mes periodo,
    cont.co_cnpj_cpf cnpn_cpf,
    cont.no_razao_social razao_social,
    cont.da_inicio_atividade in_atividade,
    cont.in_situacao situacao,
    e110.vl_sld_credor_transportar sld_credor_atual ,
    cont.co_cad_icms ie,
    l.no_municipio municipio,
    s.id_grupo,
    s.id_status,
    st.descricao,
    cg.monitorado,
    s.nome_grupo,
    dfe.nu_acao_fiscal acao_fiscal,
    dfe.da_periodo_inicio_fisc inicio,
    dfe.da_periodo_fim_fisc fim,
    dfe.no_situacao_acao situacao,
    tp.tx_tipo_acao


FROM
    sped.REG_E110              e110
    LEFT JOIN bi.dm_efd_arquivo_valido   a ON a.reg_0000_id = e110.reg_0000_id
    LEFT JOIN bi.dm_contribuinte         cont ON cont.co_cad_icms = a.ie
    LEFT JOIN bi.dm_localidade           l ON l.co_municipio = cont.co_municipio
    LEFT JOIN bi.dm_cnae                 cn ON cn.co_cnae = cont.co_cnae
    left join sismonitora.contribuintes_grupo cg on cg.cnpj = a.co_cnpj_cpf_declarante
    Left join SISMONITORA.grupo_monitorado s on s.id_grupo = cg.id_grupo
    Left join sismonitora.STATUS_MONITORAMENTO st ON st.id_status = s.id_status
    Left Join BI.DM_ACAO_FISCAL dfe ON dfe.co_cnpj_cpf = a.co_cnpj_cpf_declarante
    Left Join BI.DM_ACAO_FISCAL_TIPO_ACAO tp ON tp.nu_acao_fiscal = dfe.nu_acao_fiscal

WHERE
    a.da_inicio_arquivo = '01/12/2025'
    AND e110.vl_sld_credor_transportar >= '100000'
    AND cont.co_cad_icms not in ('00000000002208',
    '00000000032301',
    '00000001184849',
    '00000001140671',
    '00000000911721',
    '00000000963011',
    '00000004672437')

GROUP BY
    a.cod_mes,
    cont.co_cnpj_cpf,
    cont.no_razao_social,
    cont.da_inicio_atividade,
    cont.in_situacao,
    e110.vl_sld_credor_transportar,
    cont.co_cad_icms,
    l.no_municipio,
    s.id_grupo,
    s.id_status,
    st.descricao,
    cg.monitorado,
    s.nome_grupo,
    dfe.nu_acao_fiscal,
    dfe.da_periodo_inicio_fisc,
    dfe.da_periodo_fim_fisc,
    dfe.no_situacao_acao,
    tp.tx_tipo_acao

ORDER BY
   e110.vl_sld_credor_transportar DESC
