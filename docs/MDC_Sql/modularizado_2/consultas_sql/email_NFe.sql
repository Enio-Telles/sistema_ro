SELECT 
chave_Acesso, FNF.fone_dest_a8, DHEMI, XNOME_DEST, prod_xprod, fnf.xlgr_dest, fnf.xbairro_dest,  fnf.email_dest/*,
    infadfisco,
    infcpl*/
FROM
    bi.fato_nfe_Detalhe FNF /*,
    xdb_nfe.arquivo@XDB_NFE_PRODUCAO a, 
         xmltable( XMLNamespaces (DEFAULT 'http://www.portalfiscal.inf.br/nfe'),'//infNFe' passing a.xml 
             columns
                    chave_acesso varchar2(50) path '@Id',
                    infAdFisco varchar2(2000) path 'infAdic/infAdFisco[1]',
                    infCpl varchar2(4000) path 'infAdic/infCpl[1]'
                    ) ident*/
        WHERE /*A.NSU = FNF.NSU
            AND */FNF.co_destinatario = :CNPJ_OU_CPF
            AND FNF.dhemi between :data_inicial and :data_final
            AND FNF.infprot_cstat in ('100','150')
ORDER BY DHEMI DESC