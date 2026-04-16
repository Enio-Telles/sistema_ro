/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_pessoa_fisica.xml
CAMINHO_NO_XML: Dossiê Pessoa Física 1.3 > Eleições - TSE
ESTILO: Table
HABILITADA: true
BINDS:
 - CPF | prompt=CPF | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
SELECT
      bi.dm_candidatos.ds_eleicao eleicao,
      bi.dm_candidatos.ds_cargo                  cargo,
      bi.dm_candidatos.nm_ue
      || ' / '
      || bi.dm_candidatos.sg_uf                  local,
      bi.dm_candidatos.nm_candidato nome,
      bi.dm_candidatos.nm_urna_candidato         nome_urna,
      bi.dm_candidatos.nm_email                  email,
      bi.dm_candidatos.sg_partido                partido,
      bi.dm_candidatos.nm_municipio_nascimento
      || ' / '
      || bi.dm_candidatos.sg_uf_nascimento       local_nascimento,
      bi.dm_candidatos.dt_nascimento,
      bi.dm_candidatos.nr_titulo_eleitoral_candidato titulo_eleitor,
      bi.dm_candidatos.ds_grau_instrucao grau_instrucao,
      bi.dm_candidatos.ds_estado_civil estado_civil,
      bi.dm_candidatos.ds_cor_raca cor_raca,
      bi.dm_candidatos.ds_ocupacao ocupacao,
      '<html><b>'||bi.dm_candidatos.ds_sit_tot_turno resultado
  FROM
      bi.dm_candidatos
 WHERE
      bi.dm_candidatos.nr_cpf_candidato = :CPF
