/*
    Analise da Consulta: CPF_veiculos.sql
    Objetivo: Listar veiculos atuais e anteriores de propriedade de um CPF.
    
    Tabelas Utilizadas:
    - sitafe.sitafe_veiculo (t): Veiculos atuais (propriedade vigente).
      Colunas: it_nu_devedor (CPF), it_nu_placa, it_co_renavam, it_nu_chassi, it_co_marca_modelo.
    - sitafe.sitafe_tab_veiculo (tb): Tabela de marcas/modelos.
      Colunas: it_co_marca_modelo, it_no_marca_modelo.
    - detran.log_cadastro (t): Historico de veiculos (DETRAN).
      Colunas: numero_devedor, placa, renavam, chassi, marca_modelo, ano_fabricacao, ano_modelo.

    Logica Principal:
    1. Primeiro bloco: Veiculos ATUAIS (proprietario atual).
    2. Segundo bloco: Veiculos ANTERIORES (historico DETRAN).
    3. Exclui do historico os veiculos que ainda sao do CPF (NOT IN).
    4. Formata saida com HTML para destaque visual.
    
    Cores:
    - Verde (#4ACC70): Proprietario atual.
    - Laranja: Ja foi proprietario.
*/

SELECT info FROM (
SELECT
      1 codigo, 'E proprietario:' info
  FROM
      dual
UNION ALL
-- Veiculos ATUAIS
SELECT
      2 codigo, 
      '----Modelo: '
      || tb.it_no_marca_modelo
      || ' - Ano Fabricacao '
      || t.it_da_ano_fabricacao
      || ' -  Ano do Modelo: '
      || t.it_da_ano_modelo
      || ' - Placa: '
      || t.it_nu_placa
      || ' Renavam: '
      || t.it_co_renavam
      || ' Chassi: '
      || t.it_nu_chassi info
  FROM
      sitafe.sitafe_veiculo        t
        LEFT JOIN sitafe.sitafe_tab_veiculo    tb ON t.it_co_marca_modelo = tb.it_co_marca_modelo
 WHERE
      it_nu_devedor = :CPF
UNION ALL
SELECT
     3 codigo,  'Ja foi proprietario:' info
  FROM
      dual
UNION ALL
-- Veiculos ANTERIORES (historico)
SELECT
     4 codigo,
     '----Modelo: '
      || tb.it_no_marca_modelo
      || ' - Ano Fabricacao '
      || t.ano_fabricacao
      || ' -  Modelo: '
      || t.ano_modelo
      || ' - Placa: '
      || t.placa
      || ' Renavam: '
      || t.renavam
      || ' Chassi: '
      || t.chassi info
  FROM
      detran.log_cadastro       t
        LEFT JOIN sitafe.sitafe_tab_veiculo    tb ON t.marca_modelo = tb.it_co_marca_modelo
 WHERE
            substr(numero_devedor, 1, 11)= :CPF
         -- Exclui veiculos que ainda sao do CPF (evita duplicidade)
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
