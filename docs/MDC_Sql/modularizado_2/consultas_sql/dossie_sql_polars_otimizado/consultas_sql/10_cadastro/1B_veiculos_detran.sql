-- Objetivo: veículos históricos do DETRAN não presentes na base atual do SITAFE
-- Binds esperados: :CO_CNPJ_CPF

SELECT
    SUBSTR(d.numero_devedor, 1, 14) AS co_cnpj_cpf,
    'DETRAN' AS origem,
    tv.it_no_marca_modelo AS modelo,
    d.ano_fabricacao,
    d.ano_modelo,
    d.placa,
    d.renavam,
    d.chassi
FROM detran.log_cadastro d
LEFT JOIN sitafe.sitafe_tab_veiculo tv
       ON d.marca_modelo = tv.it_co_marca_modelo
WHERE SUBSTR(d.numero_devedor, 1, 14) = :CO_CNPJ_CPF
  AND TRIM(d.chassi) NOT IN (
      SELECT TRIM(v.it_nu_chassi)
      FROM sitafe.sitafe_veiculo v
      WHERE v.it_nu_devedor = :CO_CNPJ_CPF
  )
GROUP BY
    SUBSTR(d.numero_devedor, 1, 14),
    tv.it_no_marca_modelo,
    d.ano_fabricacao,
    d.ano_modelo,
    d.placa,
    d.renavam,
    d.chassi;
