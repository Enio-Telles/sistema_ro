/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_pessoa_fisica.xml
CAMINHO_NO_XML: Dossiê Pessoa Física 1.3 > Veículos
ESTILO: Table
HABILITADA: true
BINDS:
 - CPF | prompt=CPF | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
SELECT info FROM (
SELECT
      1 codigo, '<html><b style="background-color:#4ACC70">É proprietário:' info
  FROM
      dual
UNION ALL
SELECT
      2 codigo, 
      '<html>----Modelo: '
      ||'<b>'|| tb.it_no_marca_modelo
      || '</b> - Ano Fabricação <b>'
      || t.it_da_ano_fabricacao
      || '</b> -  Ano do Modelo: <b>'
      || t.it_da_ano_modelo
      || '</b> - Placa: <b>'
      || t.it_nu_placa
      || '</b> Renavam: <b>'
      || t.it_co_renavam
      || '</b> Chassi: <b>'
      || t.it_nu_chassi info
  FROM
      sitafe.sitafe_veiculo        t
        LEFT JOIN sitafe.sitafe_tab_veiculo    tb ON t.it_co_marca_modelo = tb.it_co_marca_modelo
 WHERE
      it_nu_devedor = :CPF
UNION ALL
SELECT
     3 codigo,  '<html><b style="background-color:orange">Já foi proprietário:' info
  FROM
      dual
UNION ALL
SELECT
     4 codigo,
     '<html>----Modelo: '
      || '<b>'||tb.it_no_marca_modelo
      || '</b> - Ano Fabricação <b>'
      || t.ano_fabricacao
      || '</b> -  Modelo: <b>'
      || t.ano_modelo
      || '</b> - Placa: <b>'
      || t.placa
      || '</b> Renavam: <b>'
      || t.renavam
      || '</b> Chassi: <b>'
      || t.chassi info
  FROM
      detran.log_cadastro       t
        LEFT JOIN sitafe.sitafe_tab_veiculo    tb ON t.marca_modelo = tb.it_co_marca_modelo
 WHERE
            substr(
                  numero_devedor,
                  1,
                  11
            )= :CPF
         AND TRIM(chassi)NOT IN(
            SELECT
                  TRIM(it_nu_chassi)
              FROM
                  sitafe.sitafe_veiculo
             WHERE
                  it_nu_devedor = :CPF
      ))
group by codigo, info
order by codigo
