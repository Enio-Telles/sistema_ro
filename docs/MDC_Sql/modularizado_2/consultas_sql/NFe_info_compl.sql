with tab_infadic as
(SELECT /*+ PARALLEL (4) */
    a.nsu,
    -- xml,
    substr(chave_acesso,4,44) AS chave_acesso,
    infadfisco,
    infcpl

FROM
    xdb_nfe.arquivo@XDB_NFE_PRODUCAO a, 
         xmltable( XMLNamespaces (DEFAULT 'http://www.portalfiscal.inf.br/nfe'),'//infNFe' passing a.xml 
             columns
                    chave_acesso varchar2(50) path '@Id',
                    infAdFisco varchar2(2000) path 'infAdic/infAdFisco[1]',
                    infCpl varchar2(4000) path 'infAdic/infCpl[1]'
                    ) ident

, XDB_NFE.DFE@XDB_NFE_PRODUCAO dados 
where a.nsu = dados.nsu
and dados.dest_id = '81021542253'
)

select 'nfe', co_uf_dest,
CASE WHEN d.infprot_cstat IN ('100', '150') THEN 'ATIVA' WHEN d.infprot_cstat = '0' THEN 'CANCELADA' WHEN d.infprot_cstat IN ('301','302') THEN 'DENEGADA' ELSE NULL END AS STATUS, 
d.dhemi, 
d.co_tp_nf, 
d.nnf, 
d.chave_acesso, 
d.co_emitente, 
d.co_cad_icms_emit, 
d.xnome_emit, 
d.xmun_emit, 
d.co_destinatario, 
d.co_cad_icms_dest, 
d.xnome_dest, 
d.xmun_dest, 
d.co_cfop, 
d.prod_ncm, 
d.prod_nitem, 
d.prod_xprod, 
d.prod_vprod,
d.prod_ucom, 
d.prod_qcom,
d.prod_vdesc, d.icms_vbc, d.icms_vicms, d.icms_vbcst, d.icms_vicmsst, d.icms_vicmsstdest, d.icms_vicmsstret, 
d.ipi_vipi, d.ii_vii, d.prod_voutro, infadic.infadfisco, infadic.infcpl


FROM bi.fato_nfe_detalhe d
left join tab_infadic infadic on d.chave_acesso = infadic.chave_acesso
where d.co_destinatario = '81021542253'
and d.dhemi between '01/06/2025' and '31/12/2025'