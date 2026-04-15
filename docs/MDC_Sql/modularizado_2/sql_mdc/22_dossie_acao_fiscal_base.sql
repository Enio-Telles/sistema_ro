/*
===============================================================================
MDC 22 - DOSSIÊ DE AÇÃO FISCAL / AINF / AUDITORES
-------------------------------------------------------------------------------
Objetivo
- Cobrir o núcleo mínimo das consultas de ação fiscal observadas nos dossiês.
- Permite regenerar desdobramentos de autos, auditores e guias vinculadas ao
  contribuinte.

Granularidade
- 1 linha por ação/autuação vinculada ao contribuinte.
===============================================================================
*/
SELECT
    l.cnpj_cpf,
    ainf.nu_acao_fiscal,
    ainf.nu_guia_lanc_multa,
    aud.co_matricula,
    aud.co_cpf_auditor,
    p.no_razao_social AS no_auditor
FROM bi.arr_f_lancamento_detalhe l
JOIN bi.fato_acao_fiscal_ainf ainf
  ON ainf.nu_guia_lanc_multa = l.numero_guia
LEFT JOIN bi.dm_acao_fiscal_auditores aud
  ON aud.nu_acao_fiscal = ainf.nu_acao_fiscal
LEFT JOIN bi.dm_pessoa p
  ON p.co_cnpj_cpf = aud.co_cpf_auditor
WHERE l.cnpj_cpf = REGEXP_REPLACE(TRIM(:CNPJ_CPF), '[^0-9]', '');
