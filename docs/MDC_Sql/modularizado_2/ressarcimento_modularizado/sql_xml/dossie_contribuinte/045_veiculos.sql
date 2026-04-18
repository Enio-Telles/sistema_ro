/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > Veículos
ESTILO: Table
HABILITADA: true
BINDS:
 - CO_CNPJ_CPF | prompt=CO_CNPJ_CPF | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
select
								  '<html><b>'||modelo veiculo,
								  ano_fabricacao ano,
								  ano_modelo modelo,
								  placa,
								  renavam,
								  chassi,
								  case when codigo = 2 then '<html><b style="background-color:#4ACC70">É proprietário'  else '<html><b style="background-color:orange">Já foi proprietário'  end info
							from
							(
							select
								  2                         codigo,
								  tb.it_no_marca_modelo     modelo,
								  t.it_da_ano_fabricacao    ano_fabricacao,
								  t.it_da_ano_modelo        ano_modelo,
								  t.it_nu_placa             placa,
								  t.it_co_renavam           renavam,
								  t.it_nu_chassi            chassi
							  from
								  sitafe.sitafe_veiculo        t
								  left join sitafe.sitafe_tab_veiculo    tb on t.it_co_marca_modelo = tb.it_co_marca_modelo
							 where
								  it_nu_devedor = :CO_CNPJ_CPF

							union all

							select
								  4                        codigo,
								  tb.it_no_marca_modelo    modelo,
								  t.ano_fabricacao,
								  t.ano_modelo,
								  t.placa,
								  t.renavam,
								  t.chassi
							  from
								  detran.log_cadastro       t
									left join sitafe.sitafe_tab_veiculo    tb on t.marca_modelo = tb.it_co_marca_modelo
							 where
								  substr( numero_devedor, 1, 14 )= :CO_CNPJ_CPF
									and trim(chassi)not in( select trim(it_nu_chassi) from sitafe.sitafe_veiculo where it_nu_devedor = :CO_CNPJ_CPF )
							group by 4,
								  tb.it_no_marca_modelo,
								  t.ano_fabricacao,
								  t.ano_modelo,
								  t.placa,
								  t.renavam,
								  t.chassi
							)
							order by codigo, ano
