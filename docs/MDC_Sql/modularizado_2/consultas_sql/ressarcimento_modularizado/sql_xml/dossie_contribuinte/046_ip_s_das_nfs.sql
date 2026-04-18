/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > IP(s) das NFs
ESTILO: Table
HABILITADA: true
BINDS:
 - CO_CNPJ_CPF | prompt=CO_CNPJ_CPF | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
WITH IP_ALVO AS (
                                    SELECT SUBSTR(IP.CHAVE_ACESSO,7,14) CNPJ,
                                                    IP.IP_TRANSMISSOR            IP,
                                                    COUNT(IP.CHAVE_ACESSO)       QTD_NOTAS
                                       FROM BI.DM_IP_TRANSMISSOR IP
                                    WHERE SUBSTR(IP.CHAVE_ACESSO,7,14) = :CO_CNPJ_CPF
                                      AND IP.TIPO_REG = '55'
                                    GROUP BY SUBSTR(IP.CHAVE_ACESSO,7,14),
                                                     IP.IP_TRANSMISSOR)
                                    , OUTROS_CNPJS AS (
                                    SELECT IP_OUTROS.IP_TRANSMISSOR,
                                           COUNT(DISTINCT(SUBSTR(IP_OUTROS.CHAVE_ACESSO,7,14))) QTD_OUTROS_CNPJS
                                    FROM IP_ALVO
                                    LEFT JOIN BI.DM_IP_TRANSMISSOR IP_OUTROS
                                           ON IP_OUTROS.IP_TRANSMISSOR = IP_ALVO.IP
                                                AND SUBSTR(IP_OUTROS.CHAVE_ACESSO,7,14) != IP_ALVO.CNPJ
                                                AND IP_OUTROS.TIPO_REG = '55'
                                    GROUP BY IP_OUTROS.IP_TRANSMISSOR)
                                    SELECT CNPJ, IP, QTD_NOTAS, QTD_OUTROS_CNPJS CONTRIBUINTES
                                      FROM IP_ALVO, OUTROS_CNPJS
                                    WHERE IP_ALVO.IP = OUTROS_CNPJS.IP_TRANSMISSOR
									ORDER BY 3 DESC
