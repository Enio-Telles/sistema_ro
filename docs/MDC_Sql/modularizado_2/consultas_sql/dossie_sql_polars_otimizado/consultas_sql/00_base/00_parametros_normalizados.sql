-- Objetivo: normalizar parâmetros de entrada do dossiê
-- Binds esperados: :CNPJ, :IE, :NOME

SELECT
    REGEXP_REPLACE(:CNPJ, '\D+', '') AS cnpj_normalizado,
    REGEXP_REPLACE(:IE,   '\D+', '') AS ie_normalizada,
    UPPER(TRIM(:NOME))                AS nome_normalizado
FROM dual;
