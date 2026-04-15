/*
    Analise da Consulta: CPF_empresa_atividades.sql
    Objetivo: Listar as atividades economicas (CNAEs) de uma empresa - principal e secundarias.
    
    Tabelas Utilizadas:
    - bi.dm_cnae_secundaria: CNAEs secundarios vinculados ao CNPJ/CPF.
      Colunas: co_cnpj_cpf, co_cnae_secundaria.
    - bi.dm_pessoa: Cadastro principal com CNAE principal.
      Colunas: co_cnpj_cpf, co_cnae.
    - bi.dm_cnae: Tabela de descricoes de CNAEs.
      Colunas: co_cnae, no_cnae (nome/descricao).

    Logica Principal:
    1. UNION entre CNAE principal (dm_pessoa) e secundarios (dm_cnae_secundaria).
    2. LEFT JOIN com dm_cnae para obter a descricao de cada CNAE.
    3. Ordena destacando o PRINCIPAL primeiro.
*/

SELECT
                                    base.tipo,                         -- 'PRINCIPAL' ou 'SECUND'
                                    base.co_cnae,                      -- Codigo CNAE
                                    cnae.no_cnae                       -- Descricao da atividade
                                FROM
                                    (
                                        -- CNAEs Secundarios
                                        SELECT
                                            'SECUND' tipo,
                                            t.co_cnae_secundaria co_cnae
                                        FROM
                                            bi.dm_cnae_secundaria t
                                        WHERE
                                            t.co_cnpj_cpf = :CO_CNPJ_CPF
                                        UNION
                                        -- CNAE Principal
                                        SELECT
                                            'PRINCIPAL' tipo,
                                            t.co_cnae co_cnae
                                        FROM
                                            bi.dm_pessoa t
                                        WHERE
                                            t.co_cnpj_cpf = :CO_CNPJ_CPF
                                    ) base
                                    LEFT JOIN bi.dm_cnae cnae ON base.co_cnae = cnae.co_cnae
                                ORDER BY
                                    base.tipo ASC,                     -- PRINCIPAL vem primeiro (alfabeticamente)
                                    base.co_cnae