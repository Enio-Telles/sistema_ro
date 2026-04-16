/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > Contador > Empresas do Contador
ESTILO: Table
HABILITADA: true
BINDS:
 - CO_CNPJ_CPF_CONTADOR | prompt=CO_CNPJ_CPF_CONTADOR | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
SELECT
                                               P.CO_CNPJ_CPF                     CNPJ_EMPRESA,
                                               P.CO_CAD_ICMS                     IE_EMPRESA,
                                               P.NO_RAZAO_SOCIAL                 RAZÃO_EMPRESA,
                                               P.DESC_ENDERECO||' - '||P.BAIRRO  ENDEREÇO_EMPRESA,
                                               LOC.NO_MUNICIPIO                  MUNICÍPIO_EMPRESA,
                                               CAD.IT_NO_SITUACAO_CONTRIBUINTE   SITUAÇÃO,
                                               '<html><font color="red">'||lpad(TRIM(to_char(i.inadimplencia, '999G999G999G990D00')), length(MAX(i.inadimplencia)
                                                                                                         OVER()) + 6)      inadimplencia
                                        FROM 
                                               BI.DM_PESSOA P
                                        
                                        LEFT JOIN SITAFE.SITAFE_TABELAS_CADASTRO CAD
                                             ON P.IN_SITUACAO = CAD.IT_CO_SITUACAO_CONTRIBUINTE    
                                        
                                        LEFT JOIN BI.DM_LOCALIDADE LOC
                                             ON P.CO_MUNICIPIO = LOC.CO_MUNICIPIO
                                        
                                        LEFT JOIN (
                                            SELECT t.co_cnpj_cpf,
                                                   SUM(t.va_principal + t.va_multa + t.va_juros + t.va_acrescimo) inadimplencia
                                            FROM bi.fato_lanc_arrec_sum t
                                            WHERE t.da_arrecadacao IS NULL
                                                  AND t.id_situacao = '01'
                                                  AND t.vencido = '3'
                                            GROUP BY t.co_cnpj_cpf
                                        )               i ON p.co_cnpj_cpf = i.co_cnpj_cpf
                                        
                                        WHERE 
                                               P.CO_CNPJ_CPF_CONTADOR = :CO_CNPJ_CPF_CONTADOR
                                               
                                        order by decode(i.inadimplencia, null,0) desc, i.inadimplencia desc
