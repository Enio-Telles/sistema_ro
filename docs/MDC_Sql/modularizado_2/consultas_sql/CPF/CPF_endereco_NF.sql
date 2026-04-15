/*
    Analise da Consulta: CPF_endereco_NF.sql
    Objetivo: Consolidar enderecos de um CPF a partir de cadastros (ITCD) e notas fiscais (NF-e).
    
    Tabelas Utilizadas:
    - itcd_prod.tri_itd_pessoa: Cadastro do ITCD (pessoa).
    - bi.fato_nfe_detalhe: Detalhes das NF-e (endereco de destino).

    Logica Principal:
    1. UNION ALL entre ITCD (cadastro) e NF-e (notas fiscais).
    2. Usa ROW_NUMBER para eliminar enderecos duplicados.
    3. Particiona por endereco completo (logradouro, numero, bairro, municipio).
    4. Ordena pela data mais recente (ordem_cronologica).
    5. Retorna apenas o registro mais recente de cada endereco unico.
*/

SELECT 
    origem, 
    ano_mes, 
    logradouro, 
    numero, 
    complemento, 
    bairro, 
    fone, 
    
    cep, 
    municipio, 
    uf, 
    chave_acesso,
    email
FROM (
    SELECT 
        t.*,
        -- Agrupa por endereco completo para evitar repeticoes entre fontes diferentes
        ROW_NUMBER() OVER (
            PARTITION BY 
                upper(trim(logradouro)), 
                upper(trim(numero)), 
                upper(trim(bairro)),
                upper(trim(municipio))
            ORDER BY 
                ordem_cronologica DESC NULLS LAST
        ) as rnk_geral
    FROM (
        -- Bloco 1: Cadastro ITCD
        SELECT 
            'ITCD' origem,
            null ano_mes,
            upper(t.tx_logradouro) logradouro,
            upper(t.tx_numero) numero,
            upper(t.tx_complemento) complemento,
            upper(t.tx_bairro) bairro,
            upper(t.tx_telefone) fone,
            
            upper(t.tx_cep) cep,
            upper(t.tx_cidade) municipio, 
            upper(t.tx_estado) uf,
            null chave_acesso,
            null email,
            CAST(NULL AS DATE) as ordem_cronologica
        FROM itcd_prod.tri_itd_pessoa t
        WHERE pk_pessoa = :CPF

        UNION ALL

        -- Bloco 2: Notas Fiscais (NFe)
        SELECT
            'NFE' ORIGEM,
            extract(year from dhemi)||'/'||extract(month from dhemi) ano_mes,
            upper(xlgr_dest) logradouro,
            upper(nro_dest) numero,
            upper(xcpl_dest) complemento,
            upper(xbairro_dest) bairro,
            upper(fone_dest) fone,
            
            upper(cep_dest) cep,
            upper(xmun_dest) municipio,
            upper(co_uf_dest) uf,
            t.chave_acesso,
            upper(t.email_dest) email,
            t.dhemi as ordem_cronologica
        FROM
            bi.fato_nfe_detalhe t
        WHERE t.co_destinatario = :CPF
    ) t
)
WHERE rnk_geral = 1
ORDER BY ano_mes DESC NULLS LAST
