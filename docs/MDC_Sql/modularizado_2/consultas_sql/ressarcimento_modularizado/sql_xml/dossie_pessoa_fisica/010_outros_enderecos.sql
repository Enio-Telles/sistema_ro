/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_pessoa_fisica.xml
CAMINHO_NO_XML: Dossiê Pessoa Física 1.3 > Outros endereços
ESTILO: Table
HABILITADA: true
BINDS:
 - CPF | prompt=CPF | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
select fonte, periodo, endereco, numero, complemento, bairro, municipio, uf, cep, telefone, email
from(
SELECT
      '<html><p style="color:blue">DETRAN'                                          fonte,
      t.data                                                                        ordem,
      to_char(EXTRACT(YEAR FROM t.data)|| '/' || EXTRACT(MONTH FROM t.data))        periodo,
      t.endereco,
      t.numero,
      t.complemento,
      t.bairro,
      m.it_no_municipio                                                             municipio,
      m.it_sg_uf                                                                    uf,
      t.cep,
      t.ddd || '-' || t.telefone                                                    telefone,
      NULL                                                                          email
  FROM
      detran.log_cadastro          t
        LEFT JOIN sitafe.sitafe_municipio_ipva    m ON t.municipio = m.it_co_municipio_ant
 WHERE
      substr(numero_devedor,1,11) = :CPF
UNION ALL
SELECT
      '<html><p style="color:red">TSE'                                              fonte,
      t.dt_eleicao,
      to_char( to_char(EXTRACT(YEAR FROM t.dt_eleicao) || '/' || EXTRACT(MONTH FROM t.dt_eleicao)) ) periodo,
      NULL,
      NULL,
      NULL,
      NULL,
      t.nm_ue,
      t.sg_uf,
      NULL,
      NULL,
      t.nm_email
  FROM
      bi.dm_candidatos t
 WHERE
      t.nr_cpf_candidato = :CPF
union all

SELECT
'SITAFE',
to_date(t.it_da_transacao, 'YYYYMMDD'),
      to_char(EXTRACT(YEAR FROM to_date(t.it_da_transacao, 'YYYYMMDD'))
              || '/'
              || EXTRACT(MONTH FROM to_date(t.it_da_transacao, 'YYYYMMDD'))),
t.it_tx_logradouro_corresp,
null,
null,
t.it_no_bairro_corresp,
l.no_municipio,
l.co_uf,
t.it_co_cep_corresp,
t.it_nu_ddd_corresp||'-'||t.it_nu_telefone_corresp,
t.it_co_correio_eletro_corresp
  FROM
      sitafe.sitafe_pessoa t
      left join bi.dm_localidade l on t.it_co_municipio_corresp = l.co_municipio
 WHERE
      substr(
            t.gr_identificacao,
            2
      )= :CPF

union all

SELECT
'<html><p style="color:green">CRC',
      t.CREATED_AT                                 ordem,
      to_char(EXTRACT(YEAR FROM t.CREATED_AT)
              || '/'
              || EXTRACT(MONTH FROM t.CREATED_AT))         periodo,
              e.tipo_logradouro||' '||e.logradouro,
              e.numero,
              e.complemento,
              e.bairro,
              e.cidade,
              e.uf,
              e.cep,
              e.telefone,
              e.email
  FROM
      app_crc.contadores t
      left join app_crc.enderecos e on t.id = e.contador_id
where t.cpf_cnpj = :CPF

group by '<html><p style="color:green">CRC',
      t.CREATED_AT                              ,
      to_char(EXTRACT(YEAR FROM t.CREATED_AT)
              || '/'
              || EXTRACT(MONTH FROM t.CREATED_AT))  ,
              e.tipo_logradouro||' '||e.logradouro,
              e.numero,
              e.complemento,
              e.bairro,
              e.cidade,
              e.uf,
              e.cep,
              e.telefone,
              e.email
union all
SELECT
'<html><p style="color:orange">ITCD' fonte,
null,
null,
t.tx_logradouro,
t.tx_numero,
t.tx_complemento,
t.tx_bairro,
t.tx_cidade,
t.tx_estado,
t.tx_cep,
t.tx_telefone,
null
  FROM
      itcd_prod.tri_itd_pessoa t
where t.pk_pessoa = :CPF
union all
select
       case when cv115.modelo = '06' then 'CV115 - ENERGIA ELÉTRICA'
            when cv115.modelo = '21' then 'CV115 - COMUNICAÇÃO'
            when cv115.modelo = '22' then 'CV115 - TELECOMUNICAÇÃO'
       end                                                                      fonte,
       to_date(cv115.dt_emissao,'yyyymmdd')                                     ordem,
       substr(cv115.dt_emissao,1,4)||'/'||substr(cv115.dt_emissao,5,2)          periodo,
       cv115.logradouro                                                         endereco,
       cv115.numero_end                                                         numero,
       cv115.complemento                                                        complemento,
       cv115.bairro                                                             bairro,
       cv115.municipio                                                          municipio,
       cv115.uf                                                                 uf,
       cv115.cep                                                                cep,
       cv115.telefone                                                           telefone,
       ''                                                                       email
from novo_sisconv.dados_cadastrais cv115
   where cv115.cpf_cnpj like '%'||:CPF
) b
order by case when substr(b.fonte,1,5) = 'CV115' THEN 2
              else 1 end,
          b.ordem desc
