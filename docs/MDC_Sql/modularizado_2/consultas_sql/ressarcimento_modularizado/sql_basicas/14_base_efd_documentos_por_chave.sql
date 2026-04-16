/*
Base compartilhada para consolidar documentos escriturados na EFD por chave de acesso.
Útil em cruzamentos com BI/XML e reconciliações de obrigação acessória.
*/
SELECT r.cnpj, r.dt_ini AS efd_ref, r.data_entrega,
       c.chv_nfe AS chave_efd, c.vl_icms AS efd_icms,
       c.ind_oper, c.cod_mod, c.ser, c.num_doc, c.cod_sit
FROM sped.reg_c100 c
JOIN sped.reg_0000 r ON r.id = c.reg_0000_id
UNION ALL
SELECT r.cnpj, r.dt_ini AS efd_ref, r.data_entrega,
       d.chv_cte AS chave_efd, d.vl_icms AS efd_icms,
       d.ind_oper, d.cod_mod, d.ser, d.num_doc, d.cod_sit
FROM sped.reg_d100 d
JOIN sped.reg_0000 r ON r.id = d.reg_0000_id;
