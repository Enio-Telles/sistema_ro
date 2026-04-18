/*
    Analise da Consulta: CPF_empresa_situacao.sql
    Objetivo: Exibir historico de alteracoes de situacao cadastral de uma empresa.

    Tabelas Utilizadas:
    - sitafe.sitafe_historico_gr_situacao (t): Historico de situacoes.
      Colunas: tuk, it_co_situacao_contribuinte.
    - sitafe.sitafe_historico_situacao (u): Detalhes do historico.
      Colunas: tuk, it_da_transacao, it_nu_fac, it_co_usuario, it_nu_inscricao_estadual.
    - sitafe.sitafe_tabelas_cadastro (cad_sit): Descricoes das situacoes.
      Colunas: it_co_situacao_contribuinte, it_no_situacao_contribuinte.

    Situacoes Tipicas:
    - 001: Ativo
    - 002: Suspenso
    - 003: Baixado
    - 004: Cancelado

    Logica Principal:
    1. Busca historico de situacoes pela Inscricao Estadual.
    2. Filtra situacoes relevantes (exclui 030, 150, 005 - intermediarias).
    3. Exclui alteracoes automaticas (INTERNET, P30015AC).
    4. Ordena pela mais recente primeiro.
*/

SELECT
                                        to_date(u.it_da_transacao, 'YYYYMMDD')        data,       -- Data da alteracao
                                        t.it_co_situacao_contribuinte                 sit,        -- Codigo da situacao
                                        CONVERT(cad_sit.it_no_situacao_contribuinte, 'AL32UTF8', 'WE8MSWIN1252') descricao,  -- Descricao
                                        u.it_nu_fac                                   fac,        -- Numero FAC
                                        u.it_co_usuario                               usuario,    -- Usuario que alterou
                                        u.tuk                                                     -- Chave do registro
                                    FROM
                                        sitafe.sitafe_historico_gr_situacao    t
                                        LEFT JOIN sitafe.sitafe_historico_situacao       u ON t.tuk = u.tuk
                                        LEFT JOIN sitafe.sitafe_tabelas_cadastro         cad_sit ON t.it_co_situacao_contribuinte = cad_sit.it_co_situacao_contribuinte
                                    WHERE
                                        u.it_nu_inscricao_estadual = :CO_CAD_ICMS       -- Filtro por IE
                                        AND t.it_co_situacao_contribuinte NOT IN ( '030', '150', '005' )  -- Exclui situacoes temporarias
                                        AND u.it_co_usuario not in('INTERNET', 'P30015AC   ')              -- Exclui alteracoes automaticas
                                    ORDER BY
                                        u.it_in_ultima_situacao DESC,                   -- Ultima situacao primeiro
                                        u.it_da_atualizacao_situacao DESC,
                                        u.it_ho_transacao DESC,
                                        t.it_da_situacao_contribuinte DESC
