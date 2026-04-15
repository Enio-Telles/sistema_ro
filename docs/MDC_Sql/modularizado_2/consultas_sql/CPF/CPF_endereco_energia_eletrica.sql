/*
    Analise da Consulta: CPF_endereco_energia_eletrica.sql
    Objetivo: Obter enderecos de um CPF a partir de contas de energia eletrica (NF3-e).
    
    Tabela Utilizada:
    - bi.vw_nf3_detalhe: View com detalhes de NF3-e (Nota Fiscal de Energia Eletrica).
      Colunas: co_destinatario, dest_* (dados do destinatario), acessante_* (GPS).

    Logica Principal:
    1. CTE HistoricoCliente: Agrupa por endereco unico usando ROW_NUMBER.
    2. Particiona por todos os campos de endereco + contato + GPS.
    3. Ordena pelo mais recente (dhemi DESC).
    4. Retorna apenas a linha 1 de cada grupo (endereco mais recente).
    
    Diferenciais:
    - Inclui coordenadas GPS (latitude/longitude) quando disponiveis.
    - Util para geolocalizacao do contribuinte.
*/

WITH HistoricoCliente AS (
    SELECT 
        nf3.chave_acesso,
        nf3.dhemi AS data_emissao,
        nf3.dest_xnome AS nome,
        nf3.dest_xlgr AS logradouro,
        nf3.dest_nro AS numero,
        nf3.dest_xcpl AS complemento,
        nf3.dest_xbairro AS bairro,
        nf3.dest_xmun AS municipio,
        nf3.dest_cep AS cep,
        nf3.dest_fone AS telefone,
        nf3.dest_email AS email,
        nf3.acessante_latgps AS latitude,
        nf3.acessante_longgps AS longitude,
        
        -- Numera as linhas por grupo de endereco identico, da data mais recente para a mais antiga
        ROW_NUMBER() OVER (
            PARTITION BY 
                nf3.dest_xnome, nf3.dest_xlgr, nf3.dest_nro, 
                nf3.dest_xcpl, nf3.dest_xbairro, nf3.dest_xmun, 
                nf3.dest_cep, nf3.dest_fone, nf3.dest_email, 
                nf3.acessante_latgps, nf3.acessante_longgps
            ORDER BY nf3.dhemi DESC
        ) AS num_linha

    FROM bi.vw_nf3_detalhe nf3
    WHERE nf3.co_destinatario = :CPF
)

-- Seleciona apenas a linha 1 (a mais recente) de cada conjunto de dados diferentes
SELECT 
    chave_acesso,
    data_emissao,
    nome,
    logradouro,
    numero,
    complemento,
    bairro,
    municipio,
    cep,
    telefone,
    email,
    latitude,
    longitude
FROM HistoricoCliente
WHERE num_linha = 1;
