/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > DET > Arquivo da Notificação
ESTILO: Table
HABILITADA: true
BINDS:
 - ID_NOTIFICACAO | prompt=ID_NOTIFICACAO | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
select case when CHAVE != 'NOTIFICACAO' then 'Anexo'||' - '||tipo else chave||' - '||tipo end tipo, 'https://det.sefin.ro.gov.br/arquivo/download_anexos?uuid='||t.uuid||chr(38)||'id_anexo='||t.id_anexo link_do_anexo 
								from bi.vm_dm_det_arquivos t
							WHERE ID_NOTIFICACAO = :ID_NOTIFICACAO
