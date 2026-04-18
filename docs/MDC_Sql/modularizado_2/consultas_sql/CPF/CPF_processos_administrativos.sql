/*
    Analise da Consulta: CPF_processos_administrativos.sql
    Objetivo: Listar processos administrativos abertos por/para um contribuinte.

    Tabelas Utilizadas:
    - bi.dm_processo_administrativo (t): Processos administrativos.
      Colunas: dt_abertura, nu_processo, co_servico, in_status, cpf_solicitante, co_cpf_cnpj_contribuinte.
    - sitafe.sitafe_servico (serv): Descricoes dos servicos.
      Colunas: it_co_servico, it_no_servico.
    - bi.dm_pessoa (pessoa): Dados do solicitante.

    Tipos de Processos Tipicos:
    - Solicitacao de regime especial
    - Pedido de baixa/suspensao
    - Restituicao/compensacao
    - Recursos administrativos

    Logica Principal:
    1. Busca processos pelo CPF/CNPJ do contribuinte.
    2. Enriquece com descricao do servico.
    3. Ordena pela data de abertura (mais recente primeiro).
*/

SELECT
      t.dt_abertura,                                           -- Data de abertura
      t.nu_processo,                                           -- Numero do processo
      t.co_servico,                                            -- Codigo do servico
      t.in_status,                                             -- Status atual
      t.cpf_solicitante,                                       -- CPF de quem solicitou
      serv.it_co_servico || ' - ' ||
      upper(convert(serv.it_no_servico, 'AL32UTF8', 'WE8MSWIN1252')) servico   -- Descricao do servico
  FROM
      bi.dm_processo_administrativo    t
        LEFT JOIN sitafe.sitafe_servico            serv ON t.co_servico = serv.it_co_servico
        LEFT JOIN bi.dm_pessoa                     pessoa ON t.cpf_solicitante = pessoa.co_cnpj_cpf
 WHERE
      t.co_cpf_cnpj_contribuinte = :CPF
 ORDER BY
      t.dt_abertura DESC
