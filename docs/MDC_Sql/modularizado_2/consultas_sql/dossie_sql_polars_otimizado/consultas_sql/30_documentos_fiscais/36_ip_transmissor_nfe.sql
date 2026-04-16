-- Objetivo: IPs transmissores de NFe do contribuinte e quantidade de outros CNPJs no mesmo IP
-- Binds esperados: :CO_CNPJ_CPF

WITH ip_alvo AS (
    SELECT
        SUBSTR(ip.chave_acesso, 7, 14) AS co_cnpj_cpf,
        ip.ip_transmissor,
        COUNT(ip.chave_acesso) AS qtd_notas
    FROM bi.dm_ip_transmissor ip
    WHERE SUBSTR(ip.chave_acesso, 7, 14) = :CO_CNPJ_CPF
      AND ip.tipo_reg = '55'
    GROUP BY
        SUBSTR(ip.chave_acesso, 7, 14),
        ip.ip_transmissor
),
outros AS (
    SELECT
        ip_outros.ip_transmissor,
        COUNT(DISTINCT SUBSTR(ip_outros.chave_acesso, 7, 14)) AS qtd_outros_cnpjs
    FROM ip_alvo a
    LEFT JOIN bi.dm_ip_transmissor ip_outros
           ON ip_outros.ip_transmissor = a.ip_transmissor
          AND SUBSTR(ip_outros.chave_acesso, 7, 14) != a.co_cnpj_cpf
          AND ip_outros.tipo_reg = '55'
    GROUP BY ip_outros.ip_transmissor
)
SELECT
    a.co_cnpj_cpf,
    a.ip_transmissor,
    a.qtd_notas,
    o.qtd_outros_cnpjs
FROM ip_alvo a
LEFT JOIN outros o
       ON a.ip_transmissor = o.ip_transmissor
ORDER BY a.qtd_notas DESC;
