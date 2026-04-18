SELECT
    bi.dm_cest.cod_segmento Segmento_CEST,
    bi.dm_cest.cod_cest CEST,
    bi.dm_cest.cod_ncm_sh NCM,
    bi.dm_cest.desc_cest Descricao_CEST,
    bi.dm_cest.dt_fim Data_Fim,
    bi.dm_cest.dt_ini Data_Ini
FROM
    bi.dm_cest
