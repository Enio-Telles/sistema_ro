/*
Base compartilhada para consolidar documentos eletrônicos por chave.
Útil em auditorias documentais, reconciliação com EFD e checagens preliminares.
*/
SELECT chave_acesso, '55' AS cod_mod, infprot_cstat, ide_serie AS serie, nnf, dhemi,
       tot_vnf AS tot_doc, tot_vicms AS doc_icms, co_emitente, co_destinatario
FROM bi.fato_nfe_detalhe
WHERE seq_nitem = '1'
UNION ALL
SELECT chave_acesso, '65', infprot_cstat, ide_serie, nnf, dhemi,
       tot_vnf, tot_vicms, co_emitente, co_destinatario
FROM bi.fato_nfce_detalhe
WHERE seq_nitem = '1';
