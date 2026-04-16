-- efd_reg_0220.sql
-- grupo: core
-- dominio: EFD reg 0220
-- objetivo: fatores oficiais de conversão do item
-- parametros esperados: cnpj, periodo_inicio, periodo_fim
-- observacao: apoio à conversão estrutural
-- status: template curado para implementação no novo projeto
-- regra: selecionar apenas colunas necessárias e preservar chaves físicas

/* :cnpj :periodo_inicio :periodo_fim */
WITH arquivos_validos AS (
    SELECT reg_0000_id
    FROM (
        SELECT r.id AS reg_0000_id,
               ROW_NUMBER() OVER (
                   PARTITION BY r.cnpj, r.dt_ini, NVL(r.dt_fin, r.dt_ini)
                   ORDER BY r.data_entrega DESC, r.id DESC
               ) rn
        FROM sped.reg_0000 r
        WHERE r.cnpj = REGEXP_REPLACE(TRIM(:cnpj), '[^0-9]', '')
          AND r.dt_ini BETWEEN TO_DATE(:periodo_inicio, 'YYYY-MM-DD')
                           AND TO_DATE(:periodo_fim, 'YYYY-MM-DD')
    )
    WHERE rn = 1
)
SELECT
    c.reg_0000_id,
    c.cod_item,
    c.unid_conv,
    c.fat_conv
FROM sped.reg_0220 c
JOIN arquivos_validos a
  ON a.reg_0000_id = c.reg_0000_id;
