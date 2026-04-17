/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_pessoa_fisica.xml
CAMINHO_NO_XML: Dossiê Pessoa Física 1.3 > Endereços NFe
ESTILO: Table
HABILITADA: true
BINDS:
 - CPF | prompt=CPF | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
SELECT * FROM (
select
      'ITCD' origem,
      null ano_mes,
     upper( t.tx_logradouro) logradouro,
      upper(t.tx_numero) numero,
      upper(t.tx_complemento) complemento,
      upper(t.tx_bairro) bairro,
      upper(t.tx_telefone) fone,
      upper(t.tx_cep) cep,
      upper(t.tx_cidade) municipio,
      upper(t.tx_estado) uf,
      null max_valor_nf

from itcd_prod.tri_itd_pessoa t
where pk_pessoa =:CPF

union all

SELECT
      'NFE' ORIGEM,
    extract(year from dhemi)||'/'||extract(month from dhemi) ano_mes,
    upper(xlgr_dest) logradouro,
    upper(nro_dest) numero,
    upper(xcpl_dest) complemento,
    upper(xbairro_dest) bairro,
    upper(fone_dest) fone,
    upper(cep_dest) cep,
    upper(xmun_dest) muncipio,
    upper(co_uf_dest) uf,
    max(TOT_VNF) max_valor_nf
FROM
    bi.fato_nfe_detalhe t
where t.co_destinatario = :CPF
group by    upper(xlgr_dest),
    upper(nro_dest),
    upper(xcpl_dest),
    upper(xbairro_dest),
    upper(fone_dest),
    upper(xmun_dest),
    upper(cep_dest),
    upper(co_uf_dest),
    extract(year from dhemi)||'/'||extract(month from dhemi))

order by ano_mes desc
