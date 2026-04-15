-- CPF_historico_regime_pagto.sql
-- Extraído de dossie_contribuinte.xml - Histórico Regime de Pagamento
-- Parâmetro: :CO_CNPJ_CPF

SELECT
    co_regime_pagto           CODIGO_REGIME,
    desc_reg_pagto            DESCRICAO_REGIME,
    min(da_referencia)        DATA_INICIO,
    CASE 
        WHEN max(da_referencia) = trunc(sysdate,'mm') THEN 'Atual' 
        ELSE to_char(max(da_referencia)) 
    END                       DATA_FIM
FROM BI.dm_regime_pagto_contribuinte
WHERE co_cnpj_cpf = :CO_CNPJ_CPF
GROUP BY 
    co_cnpj_cpf,
    co_regime_pagto,
    desc_reg_pagto
ORDER BY 3 DESC
