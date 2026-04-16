-- efd_reg_0200.sql
-- grupo: core
-- dominio: EFD reg 0200
-- objetivo: cadastro de itens
-- parametros esperados: cnpj, periodo_inicio, periodo_fim
-- observacao: base de produto antes do agrupamento
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
    i.reg_0000_id,
    i.cod_item,
    i.descr_item,
    i.cod_barra,
    i.cod_ncm,
    i.cest,
    i.unid_inv
FROM sped.reg_0200 i
JOIN arquivos_validos a
  ON a.reg_0000_id = i.reg_0000_id;
