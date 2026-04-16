-- Objetivo: histórico de regime de pagamento por referência
-- Binds esperados: :CO_CNPJ_CPF

SELECT
    r.co_cnpj_cpf,
    r.co_regime_pagto,
    r.desc_reg_pagto,
    MIN(r.da_referencia) AS da_referencia_inicio,
    MAX(r.da_referencia) AS da_referencia_fim
FROM bi.dm_regime_pagto_contribuinte r
WHERE r.co_cnpj_cpf = :CO_CNPJ_CPF
GROUP BY
    r.co_cnpj_cpf,
    r.co_regime_pagto,
    r.desc_reg_pagto
ORDER BY da_referencia_inicio DESC;
