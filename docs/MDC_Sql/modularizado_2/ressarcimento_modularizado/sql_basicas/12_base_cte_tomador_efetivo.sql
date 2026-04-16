/*
Base compartilhada para identificar o tomador efetivo do CT-e.
Útil para auditorias de modelo 57 e para qualquer cruzamento por papel do contribuinte.
*/
SELECT
    c.chave_acesso,
    c.co_tomador3,
    CASE
        WHEN c.co_tomador3 = '0' THEN c.rem_cnpj_cpf
        WHEN c.co_tomador3 = '1' THEN c.exp_co_cnpj_cpf
        WHEN c.co_tomador3 = '2' THEN c.receb_cnpj_cpf
        WHEN c.co_tomador3 = '3' THEN c.dest_cnpj_cpf
        ELSE c.co_tomador4_cnpj_cpf
    END AS cnpj_cpf_tomador,
    c.emit_co_cnpj,
    c.dhemi,
    c.icms_vicms,
    c.prest_vtprest
FROM bi.fato_cte_detalhe c;
