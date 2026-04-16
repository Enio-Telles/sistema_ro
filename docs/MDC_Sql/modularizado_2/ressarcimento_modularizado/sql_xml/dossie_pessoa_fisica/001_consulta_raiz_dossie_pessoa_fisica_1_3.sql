/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_pessoa_fisica.xml
CAMINHO_NO_XML: Dossiê Pessoa Física 1.3
ESTILO: Table
HABILITADA: true
BINDS:
 - CPF_ | prompt=CPF_ | default=03027064290
 - NOME | prompt=NOME | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
with itcd as(
								--consolidado do sistema antigo e novo, pegando apenas o ultimo
								select
									cpf_de_cujus,
									'<html><b style="color:red">Consta óbito em '||count(1)||' processo(s) de inventário, números '||LISTAGG(numero_processo,' * ') within group (order by data_envio desc)||'.</b><b> Checar DIEF(s) em:</b>' info,
									'https://itcd.sefin.ro.gov.br/visualizar_consulta_autenticacao_sistemas_sefin' link
									
								from (
										--sistema antigo de itcd
										select 
										   prot.da_envio              data_envio,
										   proc.nu_ident_inventariado cpf_de_cujus,
										   prot.co_protocolo          numero_processo
										from 
											itcd_prod.tri_itd_processo proc, 
											itcd_prod.tri_itd_protocolo prot, 
											itcd_prod.tri_itd_fato_gerador fg 
										where prot.fk_fato_gerador = 1
										  and prot.fk_situacao = 5
										  --and proc.nu_ident_inventariado = regexp_replace(:CPF_,'\D+', '')
										  and proc.fk_protocolo = prot.pk_protocolo
										  and fg.pk_fato_gerador = prot.fk_fato_gerador
										union
										--sistema novo de itcd
										select
											proc.data_envio         data_envio,
											inv.cpf_cnpj            cpf_de_cujus,
											proc.numero_processo    numero_processo
											
										from 
											ITCD.processos proc, 
											itcd.inventariados inv
										where proc.fato_gerador_id = 1
										  and proc.situacao_id = 5
										  --and inv.cpf_cnpj = regexp_replace(:CPF_,'\D+', '')
										  and proc.id = inv.processo_id
								)
								group by cpf_de_cujus
								)

								SELECT
									t.co_cnpj_cpf CPF,
									'<html><b>'||t.no_razao_social nome,
									t.desc_endereco logradouro,
									t.bairro,
									t.nu_cep CEP,
									localid.no_municipio municipio,
									localid.co_uf uf,
									nvl(i.info,' ') info,
									nvl(i.link,' ') link
								FROM
									bi.dm_pessoa t
									left join bi.dm_localidade localid on t.co_municipio = localid.co_municipio
									left join itcd i on t.co_cnpj_cpf = i.cpf_de_cujus
								where (:CPF_ is null or t.co_cnpj_cpf = regexp_replace(:CPF_,'\D+', ''))
								  and (:NOME is null or upper(t.no_razao_social) like '%'||regexp_replace(upper(:NOME),'\s', '%')||'%')
								  and length(t.co_cnpj_cpf) = 11
								order by case when :NOME is not null then t.no_razao_social else t.co_cnpj_cpf end
