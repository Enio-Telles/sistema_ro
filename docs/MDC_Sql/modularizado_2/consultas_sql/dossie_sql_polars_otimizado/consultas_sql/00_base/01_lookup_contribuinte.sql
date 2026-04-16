-- Objetivo: localizar candidatos a contribuinte a partir de CNPJ/IE/NOME
-- Binds esperados: :CNPJ, :IE, :NOME

SELECT
    p.co_cnpj_cpf,
    p.co_cad_icms,
    p.no_razao_social,
    p.da_inicio_atividade
FROM bi.dm_pessoa p
WHERE (:CNPJ IS NULL OR p.co_cnpj_cpf LIKE '%' || REGEXP_REPLACE(:CNPJ, '\D+', '') || '%')
  AND (:IE   IS NULL OR p.co_cad_icms LIKE '%' || REGEXP_REPLACE(:IE, '\D+', '') || '%')
  AND (:NOME IS NULL OR UPPER(p.no_razao_social) LIKE '%' || REGEXP_REPLACE(UPPER(:NOME), '\s', '%') || '%')
ORDER BY
    CASE WHEN :NOME IS NOT NULL THEN p.no_razao_social END,
    p.co_cnpj_cpf;
