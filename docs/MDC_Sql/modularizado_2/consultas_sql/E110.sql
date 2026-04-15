WITH PARAMETROS AS (
    SELECT 
        :CNPJ AS cnpj_filtro,
        TO_DATE(:data_inicial, 'DD/MM/YYYY') AS dt_ini_filtro,
        TO_DATE(:data_final,   'DD/MM/YYYY') AS dt_fim_filtro,
        /* Garante que se o parametro vier nulo, usa sysdate, senao usa a data informada */
        NVL(TO_DATE(:data_limite_processamento, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_corte
    FROM dual
),

ARQUIVOS_RANKING AS (
    SELECT 
        dm.REG_0000_ID            AS reg_0000_id,
        dm.DA_INICIO_ARQUIVO      AS dt_ini,
        dm.DA_FINAL_ARQUIVO       AS dt_fin,
        dm.CO_CNPJ_CPF_DECLARANTE AS cnpj,
        dm.DA_ENTREGA_ARQUIVO     AS data_entrega,
        dm.IN_CODIGO_FINALIDADE   AS cod_fin_efd,
        /* Função de janela para pegar a última entrega válida até a data de corte */
        ROW_NUMBER() OVER (
            PARTITION BY dm.CO_CNPJ_CPF_DECLARANTE, dm.DA_INICIO_ARQUIVO, dm.DA_FINAL_ARQUIVO 
            ORDER BY dm.DA_ENTREGA_ARQUIVO DESC
        ) AS rn
    FROM BI.DM_EFD_ARQUIVO_VALIDO dm
    JOIN PARAMETROS p 
      ON dm.CO_CNPJ_CPF_DECLARANTE = p.cnpj_filtro
    WHERE dm.DA_ENTREGA_ARQUIVO <= p.dt_corte
      AND dm.DA_INICIO_ARQUIVO BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro
)

SELECT
    TO_CHAR(arq.dt_ini, 'MM/YYYY') AS periodo,
    
    /* Tratamento de Nulos para evitar erros em somas ou relatórios */
    NVL(e110.vl_tot_debitos, 0)        AS vl_tot_debitos,
    NVL(e110.vl_aj_debitos, 0)         AS vl_aj_debitos,
    NVL(e110.vl_tot_aj_debitos, 0)     AS vl_tot_aj_debitos,
    NVL(e110.vl_estornos_cred, 0)      AS vl_estornos_cred,
    NVL(e110.vl_tot_creditos, 0)       AS vl_tot_creditos,
    NVL(e110.vl_aj_creditos, 0)        AS vl_aj_creditos,
    NVL(e110.vl_tot_aj_creditos, 0)    AS vl_tot_aj_creditos,
    NVL(e110.vl_estornos_deb, 0)       AS vl_estornos_deb,
    NVL(e110.vl_sld_credor_ant, 0)     AS vl_sld_credor_ant,
    NVL(e110.vl_sld_apurado, 0)        AS vl_sld_apurado,
    NVL(e110.vl_tot_ded, 0)            AS vl_tot_ded,
    NVL(e110.vl_icms_recolher, 0)      AS vl_icms_recolher,
    NVL(e110.vl_sld_credor_transportar, 0) AS vl_sld_credor_transportar,
    NVL(e110.deb_esp, 0)               AS deb_esp,
    
    arq.data_entrega                   AS Data_entrega_efd_periodo,
    arq.cod_fin_efd
FROM sped.reg_e110 e110
INNER JOIN ARQUIVOS_RANKING arq 
  ON e110.reg_0000_id = arq.reg_0000_id
WHERE arq.rn = 1 /* Filtra apenas a versão mais recente (Original ou Retificadora Final) */
ORDER BY arq.dt_ini ASC