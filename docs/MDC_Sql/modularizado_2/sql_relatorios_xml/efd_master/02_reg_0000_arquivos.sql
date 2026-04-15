-- Origem: EFD_master.xml
-- Título no relatório: Reg 0000 (arquivos)
-- Caminho no XML: EFD Master 2.0 > Reg 0000 (arquivos)
-- Utilidade fiscal: Altíssima
-- Foco: Lista arquivos EFD, período, entrega, importação e identificação cadastral do arquivo.
-- Uso sugerido: Provar existência, versão e tempestividade/extemporaneidade do arquivo antes de qualquer auditoria de mérito.
-- Riscos/Limites: Sem essa consulta, análises em C100/C170/E110 podem recair sobre arquivo errado ou entrega superada.
-- Tabelas/fontes identificadas: sped.reg_0000, sped.fis_efd_arquivo_sped, bi.dm_localidade
-- Binds declarados: CNPJ_CPF, DATA_INICIAL, DATA_FINAL

SELECT

    t.dt_ini,
    t.dt_fin,
    t.cnpj,
    t.ie,
    t.im,
    t.suframa,
    t.nome,
    l.no_municipio,
    t.uf,
    t.ind_perfil,
    t.ind_ativ,

    t.cod_fin,
    t.cod_ver,
    arq.giam,
        substr(t.data_entrega, 1, 17)           da_entrega,
    arq.data_importacao                   da_imp,
        t.id
FROM
    sped.reg_0000                t
    LEFT JOIN sped.fis_efd_arquivo_sped    arq ON t.arquivo_nome = arq.arquivo_nome
    LEFT JOIN bi.dm_localidade             l ON t.cod_mun = l.co_mun_ibge
WHERE
    t.cnpj = :CNPJ_CPF
   and t.dt_ini between :DATA_INICIAL AND :DATA_FINAL
     
    
ORDER BY
    t.dt_ini DESC,
    t.data_entrega DESC
