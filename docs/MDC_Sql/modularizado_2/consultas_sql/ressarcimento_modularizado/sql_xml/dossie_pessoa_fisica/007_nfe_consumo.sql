/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_pessoa_fisica.xml
CAMINHO_NO_XML: Dossiê Pessoa Física 1.3 > NFe - Consumo
ESTILO: Table
HABILITADA: true
BINDS:
 - CPF | prompt=CPF | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
SELECT
      extract(year from t.dhemi) ano,
      t.dhemi data,
      t.chave_acesso,
      t.co_emitente cnpj,
      upper(t.xnome_emit) nome,
      upper(t.xlgr_emit) logradouro,
     upper(t.xbairro_emit) bairro,
      t.nro_emit numero,
     upper( t.xcpl_emit) complemento,
     upper( t.xmun_emit) municipio,
      t.co_uf_emit uf,
     '<html><b>'||upper(t.prod_xprod) produto,
      t.prod_ucom und,
      t.prod_qcom quant,
      sum((t.prod_vprod + t.prod_vfrete + t.prod_vseg - t.prod_vdesc + t.prod_voutro)) valor
  FROM
      bi.fato_nfe_detalhe t
 WHERE
            t.co_destinatario = :CPF
         AND t.infprot_cstat IN('100',
                                '150')

group by grouping sets (

      (),
      (extract(year from t.dhemi)),
      (t.co_emitente,
      upper(t.xnome_emit)),
      (t.co_uf_emit),
      (extract(year from t.dhemi),
      t.dhemi,
      t.chave_acesso,
      t.co_emitente,
      upper(t.xnome_emit),
      upper(t.xlgr_emit),
     upper(t.xbairro_emit),
      t.nro_emit,
     upper( t.xcpl_emit),
     upper( t.xmun_emit),
      t.co_uf_emit,
     '<html><b>'||upper(t.prod_xprod),
      t.prod_ucom,
      t.prod_qcom)

      )


order by case when ano is null and cnpj is null and uf is null and nome is null  then 1
      when ano is not null and cnpj is null and uf is null then 2
      when ano is not null and cnpj is not null and chave_acesso is not null then 3
      when ano is null and cnpj is null and uf is not null then 4
      else 5 end, ano desc, data desc, valor desc


--dhemi desc
