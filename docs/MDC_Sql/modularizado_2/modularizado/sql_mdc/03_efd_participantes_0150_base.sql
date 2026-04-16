/*
===============================================================================
MDC 03 - PARTICIPANTES EFD (REG_0150)
-------------------------------------------------------------------------------
Objetivo
- Normalizar emitentes, destinatários e tomadores vinculados à EFD.
- Dar suporte a C100, entradas, saídas e cruzamentos documentais.

Granularidade
- 1 linha por participante por arquivo EFD.
===============================================================================
*/
WITH arquivos_validos AS (
    SELECT reg_0000_id
    FROM (
        SELECT
            r.id AS reg_0000_id,
            ROW_NUMBER() OVER (
                PARTITION BY r.cnpj, r.dt_ini, NVL(r.dt_fin, r.dt_ini)
                ORDER BY r.data_entrega DESC, r.id DESC
            ) rn
        FROM sped.reg_0000 r
        WHERE r.cnpj = REGEXP_REPLACE(TRIM(:CNPJ_CPF), '[^0-9]', '')
          AND r.dt_ini BETWEEN TO_DATE(:DATA_INICIAL, 'DD/MM/YYYY')
                           AND TO_DATE(:DATA_FINAL, 'DD/MM/YYYY')
    )
    WHERE rn = 1
)
SELECT
    p.reg_0000_id,
    p.cod_part,
    NVL(p.cnpj, p.cpf) AS cnpj_cpf_participante,
    p.nome,
    p.cod_mun,
    l.no_municipio,
    l.co_uf,
    p.ie,
    p.suframa,
    p.end,
    p.num,
    p.compl,
    p.bairro
FROM sped.reg_0150 p
LEFT JOIN bi.dm_localidade l
       ON l.co_mun_ibge = p.cod_mun
WHERE p.reg_0000_id IN (SELECT reg_0000_id FROM arquivos_validos);
