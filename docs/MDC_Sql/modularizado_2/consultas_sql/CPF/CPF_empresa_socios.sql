/*
    Analise da Consulta: CPF_empresa_socios.sql
    Objetivo: Listar socios atuais e antigos de uma empresa.

    Tabelas Utilizadas:
    - bi.dm_pessoa: Cadastro para obter a IE da empresa.
    - sitafe.sitafe_historico_socio (shs): Historico de participacao societaria.
    - sitafe.sitafe_pessoa (p): Dados do socio (nome).

    Logica Principal:
    1. CTE s_auto: Obtem a IE da empresa pelo CNPJ.
    2. CTE hist_socio: Historico completo de socios (datas de entrada/saida).
    3. CTE ult_socio: Socios ATUAIS (ultima FAC = 9, sem data de saida).
    4. CTE tabela: Consolida informacoes com status (ATUAL ou ANTIGO).
    5. Gera link para Portal da Transparencia para consulta do CPF.
*/

with s_auto as
            (
            select
                bi.dm_pessoa.co_cnpj_cpf,
                bi.dm_pessoa.co_cad_icms ie
            from
                bi.dm_pessoa
            where
                bi.dm_pessoa.co_cnpj_cpf = :CO_CNPJ_CPF
            ),

            hist_socio as (
            select
                shs.gr_identificacao,
                shs.it_nu_inscricao_estadual,
                min(shs.it_da_inicio_part_societaria)       da_entrada,
                max(shs.it_da_fim_part_societaria)          da_saida
            from
                s_auto
            left join sitafe.sitafe_historico_socio shs
                   on shs.it_nu_inscricao_estadual = s_auto.ie
            group by
                shs.gr_identificacao,
                shs.it_nu_inscricao_estadual
            ),

            ult_socio as (
            select
                shs.gr_identificacao,
                shs.it_nu_inscricao_estadual
            from
                s_auto
                left join sitafe.sitafe_historico_socio shs
                       on shs.it_nu_inscricao_estadual = s_auto.ie
                      and shs.it_in_ultima_fac = '9'
                      and (shs.it_da_fim_part_societaria = '        ' or shs.it_da_fim_part_societaria > to_char(sysdate, 'yyyymmdd'))
            group by
                shs.gr_identificacao,
                shs.it_nu_inscricao_estadual
            ),

            tabela as (
            select
                case
                    when ult_socio.gr_identificacao is not null then
                        'SOCIO ATUAL'
                    else
                        'SOCIO ANTIGO'
                end  part_atual,
                substr(p.gr_identificacao, 2)  cpfcnpj,
                p.it_no_pessoa,
                case
                    when hist_socio.da_entrada != '         ' then
                        to_date(hist_socio.da_entrada, 'YYYYMMDD')
                end  it_da_inicio_part_societaria,
                case
                    when ult_socio.gr_identificacao is not null then
                        'SOCIO ATUAL'
                    when hist_socio.da_saida = '        ' then
                        'NAO INFORMADO'
                    else
                        to_char(to_date(hist_socio.da_saida, 'YYYYMMDD'))
                end  fim_part_societaria_real
            from
                hist_socio
                left join ult_socio on hist_socio.gr_identificacao = ult_socio.gr_identificacao
                                       and hist_socio.it_nu_inscricao_estadual = ult_socio.it_nu_inscricao_estadual
                left join sitafe.sitafe_pessoa p on p.gr_identificacao = hist_socio.gr_identificacao
                                                    and p.it_in_ultima_situacao = '9'
            )
                    select
                        tabela.part_atual                   situacao,
                        tabela.cpfcnpj                      co_cnpj_cpf,
                        tabela.it_no_pessoa                 nome,
                        tabela.it_da_inicio_part_societaria da_inicio,
                        tabela.fim_part_societaria_real     da_fim,
                        'http://www.portaltransparencia.gov.br/pessoa-fisica/busca/lista?termo='||tabela.cpfcnpj portal_transparencia
                    from
                        tabela
            order by
                1,
                4 desc,
                5 desc,
                3 asc
