/*
===============================================================================
MDC 20 - DOSSIÊ CADASTRAL / CONTA CORRENTE
-------------------------------------------------------------------------------
Objetivo
- Manter um núcleo mínimo para regenerar a parte fiscal-cadastral dos dossiês de
  contribuinte e pessoa física extraídos dos XMLs.
- Não tenta cobrir todos os relatórios acessórios; cobre o eixo cadastro,
  situação, regime e conta corrente.

Granularidade
- 1 linha por combinação contribuinte x regime/situação/lote de inadimplência.
===============================================================================
*/
SELECT
    p.co_cnpj_cpf,
    p.no_razao_social,
    p.co_regime_pagto,
    r.desc_reg_pagto,
    p.in_situacao,
    s.situacao,
    l.no_municipio,
    l.co_uf,
    v.total AS total_vencido
FROM bi.dm_pessoa p
LEFT JOIN bi.dm_regime_pagto_descricao r
       ON r.co_regime_pagamento = p.co_regime_pagto
LEFT JOIN bi.vw_situacao_contribuinte s
       ON s.in_situacao = p.in_situacao
LEFT JOIN bi.dm_localidade l
       ON l.co_municipio = p.co_municipio
LEFT JOIN (
    SELECT
        fa.co_cnpj_cpf,
        SUM(fa.va_principal + fa.va_multa + fa.va_juros + fa.va_acrescimo) AS total
    FROM bi.fato_lanc_arrec_sum fa
    WHERE fa.vencido = 3
      AND fa.id_situacao = '01'
    GROUP BY fa.co_cnpj_cpf
) v ON v.co_cnpj_cpf = p.co_cnpj_cpf
WHERE p.co_cnpj_cpf = REGEXP_REPLACE(TRIM(:CNPJ_CPF), '[^0-9]', '');
