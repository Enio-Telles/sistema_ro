/*
    Analise da Consulta: CPF_empresa_reg_pgto.sql
    Objetivo: Exibir historico de regimes de pagamento de uma empresa.
    
    Tabela Utilizada:
    - BI.dm_regime_pagto_contribuinte: Historico de regimes por periodo.
      Colunas: co_cnpj_cpf, co_regime_pagto, desc_reg_pagto, da_referencia.

    Regimes de Pagamento Tipicos:
    - Normal (debito/credito)
    - Simples Nacional
    - Estimativa
    - Substituto Tributario
    
    Logica Principal:
    1. Agrupa por regime e mostra periodo de vigencia (inicio e fim).
    2. Se o fim coincidir com o mes atual, exibe 'Atual'.
*/

select
                co_regime_pagto,                                -- Codigo do regime
                desc_reg_pagto,                                 -- Descricao do regime
                min(da_referencia)  inicio,                     -- Data de inicio do regime
                -- Se o regime vai ate o mes atual, mostra 'Atual'
                case when max(da_referencia) = trunc(sysdate,'mm') then 'Atual' else to_char(max(da_referencia)) end fim
            from BI.dm_regime_pagto_contribuinte
            where co_cnpj_cpf  = :CO_CNPJ_CPF
            group by co_cnpj_cpf,
                co_regime_pagto,
                desc_reg_pagto
            order by 3 desc                                     -- Ordena pelo mais recente primeiro