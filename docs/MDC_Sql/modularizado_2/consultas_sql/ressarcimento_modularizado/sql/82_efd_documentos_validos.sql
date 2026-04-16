/*
===============================================================================
MÓDULO 82 - DOCUMENTOS ESCRITURADOS NA EFD VÁLIDA
-------------------------------------------------------------------------------
Objetivo
- Reunir os documentos escriturados em C100 e D100, usando apenas a EFD válida.

Granularidade
- 1 linha por documento escriturado na EFD.

Regra de negócio
- A seleção depende da dimensão bi.dm_efd_arquivo_valido.
===============================================================================
*/

WITH parametros AS (
    SELECT REGEXP_REPLACE(TRIM(:CNPJ), '[^0-9]', '') AS cnpj FROM dual
)
SELECT * FROM (
    SELECT r.cnpj, r.dt_ini AS efd_ref, r.data_entrega,
           c.chv_nfe AS chave_efd, c.vl_icms AS efd_icms,
           c.reg, c.ind_oper, c.ser, c.num_doc, c.cod_sit, c.cod_mod
    FROM sped.reg_c100 c
    JOIN sped.reg_0000 r ON r.id = c.reg_0000_id
    JOIN bi.dm_efd_arquivo_valido a ON a.reg_0000_id = c.reg_0000_id
    JOIN parametros p ON r.cnpj = p.cnpj
    WHERE c.cod_mod IN ('55','65')

    UNION ALL

    SELECT r.cnpj, r.dt_ini AS efd_ref, r.data_entrega,
           d.chv_cte AS chave_efd, d.vl_icms AS efd_icms,
           d.reg, d.ind_oper, d.ser, d.num_doc, d.cod_sit, d.cod_mod
    FROM sped.reg_d100 d
    JOIN sped.reg_0000 r ON r.id = d.reg_0000_id
    JOIN bi.dm_efd_arquivo_valido a ON a.reg_0000_id = d.reg_0000_id
    JOIN parametros p ON r.cnpj = p.cnpj
    WHERE d.cod_mod = '57'
);
