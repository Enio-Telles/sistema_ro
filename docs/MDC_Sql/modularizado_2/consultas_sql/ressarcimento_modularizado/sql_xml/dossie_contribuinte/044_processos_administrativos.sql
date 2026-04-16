/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > Processos Administrativos
ESTILO: Table
HABILITADA: true
BINDS:
 - CO_CNPJ_CPF | prompt=CO_CNPJ_CPF | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
SELECT
                                    t.nu_processo,
                                    t.dt_abertura,
                                    t.in_status,
                                    t.co_servico,
                                    serv.it_no_servico,
                                    t.cpf_solicitante,
                                    pessoa.no_razao_social nome_solicitante
                                FROM
                                    bi.dm_processo_administrativo   t
                                    LEFT JOIN sitafe.sitafe_servico           serv ON t.co_servico = serv.it_co_servico
                                    left join bi.dm_pessoa pessoa on t.cpf_solicitante = pessoa.co_cnpj_cpf
                                    
                                    where t.co_cpf_cnpj_contribuinte = :CO_CNPJ_CPF
                                order by dt_abertura desc
