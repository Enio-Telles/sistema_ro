/*
    Dossiê Unificado: Endereços Físicos + Vínculos Empresariais
    Objetivo: Listar endereços pessoais do CPF e endereços das empresas onde ele é sócio.
    Parametro: :CPF
*/

WITH 
-- =============================================================================
-- BLOCO 1: FONTES PESSOAIS (Consulta Original de Endereços)
-- =============================================================================

-- 1. DETRAN
detran AS (
    SELECT
        'DETRAN' as fonte,
        t.data as ordem_cronologica,
        to_char(EXTRACT(YEAR FROM t.data)|| '/' || EXTRACT(MONTH FROM t.data)) as periodo,
        UPPER(t.endereco) as endereco,
        UPPER(t.numero) as numero,
        UPPER(t.complemento) as complemento,
        UPPER(t.bairro) as bairro,
        UPPER(m.it_no_municipio) as municipio,
        UPPER(m.it_sg_uf) as uf,
        t.cep,
        t.ddd || '-' || t.telefone as telefone,
        NULL as email
    FROM detran.log_cadastro t
    LEFT JOIN sitafe.sitafe_municipio_ipva m ON t.municipio = m.it_co_municipio_ant
    WHERE substr(numero_devedor, 1, 11) = :CPF
),

-- 2. TSE
tse AS (
    SELECT
        'TSE' as fonte,
        t.dt_eleicao as ordem_cronologica,
        to_char(EXTRACT(YEAR FROM t.dt_eleicao) || '/' || EXTRACT(MONTH FROM t.dt_eleicao)) as periodo,
        NULL as endereco, 
        NULL as numero, 
        NULL as complemento, 
        NULL as bairro,
        UPPER(t.nm_ue) as municipio,
        UPPER(t.sg_uf) as uf,
        NULL as cep, 
        NULL as telefone,
        t.nm_email as email
    FROM bi.dm_candidatos t
    WHERE t.nr_cpf_candidato = :CPF
),

-- 3. SITAFE (Pessoa Física)
sitafe AS (
    SELECT
        'SITAFE' as fonte,
        to_date(t.it_da_transacao, 'YYYYMMDD') as ordem_cronologica,
        to_char(EXTRACT(YEAR FROM to_date(t.it_da_transacao, 'YYYYMMDD')) || '/' || EXTRACT(MONTH FROM to_date(t.it_da_transacao, 'YYYYMMDD'))) as periodo,
        UPPER(t.it_tx_logradouro_corresp) as endereco,
        NULL as numero, 
        NULL as complemento,
        UPPER(t.it_no_bairro_corresp) as bairro,
        UPPER(l.no_municipio) as municipio,
        UPPER(l.co_uf) as uf,
        t.it_co_cep_corresp as cep,
        t.it_nu_ddd_corresp || '-' || t.it_nu_telefone_corresp as telefone,
        t.it_co_correio_eletro_corresp as email
    FROM sitafe.sitafe_pessoa t
    LEFT JOIN bi.dm_localidade l ON t.it_co_municipio_corresp = l.co_municipio
    WHERE substr(t.gr_identificacao, 2) = :CPF
),

-- 4. CRC
crc AS (
    SELECT
        'CRC' as fonte,
        t.CREATED_AT as ordem_cronologica,
        to_char(EXTRACT(YEAR FROM t.CREATED_AT) || '/' || EXTRACT(MONTH FROM t.CREATED_AT)) as periodo,
        UPPER(e.tipo_logradouro || ' ' || e.logradouro) as endereco,
        UPPER(e.numero) as numero,
        UPPER(e.complemento) as complemento,
        UPPER(e.bairro) as bairro,
        UPPER(e.cidade) as municipio, 
        UPPER(e.uf) as uf,
        e.cep,
        e.telefone,
        e.email
    FROM app_crc.contadores t
    LEFT JOIN app_crc.enderecos e ON t.id = e.contador_id
    WHERE t.cpf_cnpj = :CPF
),

-- 5. ITCD
itcd AS (
    SELECT 
        'ITCD' as fonte,
        CAST(NULL AS DATE) as ordem_cronologica,
        NULL as periodo,
        UPPER(t.tx_logradouro) as endereco,
        UPPER(t.tx_numero) as numero,
        UPPER(t.tx_complemento) as complemento,
        UPPER(t.tx_bairro) as bairro,
        UPPER(t.tx_cidade) as municipio, 
        UPPER(t.tx_estado) as uf,
        UPPER(t.tx_cep) as cep,
        UPPER(t.tx_telefone) as telefone,
        NULL as email
    FROM itcd_prod.tri_itd_pessoa t
    WHERE pk_pessoa = :CPF
),

-- 6. CV115 (Energia/Telecom)
cv115 AS (
    SELECT
        CASE WHEN cv115.modelo = '06' THEN 'CV115 - ENERGIA'
             WHEN cv115.modelo = '21' THEN 'CV115 - COMUNICACAO'
             WHEN cv115.modelo = '22' THEN 'CV115 - TELECOM'
        END as fonte,
        to_date(cv115.dt_emissao, 'yyyymmdd') as ordem_cronologica,
        substr(cv115.dt_emissao, 1, 4) || '/' || substr(cv115.dt_emissao, 5, 2) as periodo,
        UPPER(cv115.logradouro) as endereco,
        UPPER(cv115.numero_end) as numero,
        UPPER(cv115.complemento) as complemento,
        UPPER(cv115.bairro) as bairro,
        UPPER(cv115.municipio) as municipio,
        UPPER(cv115.uf) as uf,
        cv115.cep,
        cv115.telefone,
        '' as email
    FROM novo_sisconv.dados_cadastrais cv115 
    WHERE cv115.cpf_cnpj like '%' || :CPF
),

-- 7. NFE
nfe AS (
    SELECT
        'NFE' as fonte,
        t.dhemi as ordem_cronologica,
        extract(year from dhemi)||'/'||extract(month from dhemi) as periodo,
        UPPER(xlgr_dest) as endereco,
        UPPER(nro_dest) as numero,
        UPPER(xcpl_dest) as complemento,
        UPPER(xbairro_dest) as bairro,
        UPPER(xmun_dest) as municipio,
        UPPER(co_uf_dest) as uf,
        UPPER(cep_dest) as cep,
        UPPER(fone_dest) as telefone,
        UPPER(t.email_dest) as email,
        t.chave_acesso
    FROM bi.fato_nfe_detalhe t
    WHERE t.co_destinatario = :CPF
),

-- 8. NFC-e
nfce AS (
    SELECT
        'NFC-e' as fonte,
        t.dhemi as ordem_cronologica,
        extract(year from dhemi)||'/'||extract(month from dhemi) as periodo,
        UPPER(t.xlgr_dest) as endereco,
        UPPER(t.nro_dest) as numero,
        UPPER(t.xcpl_dest) as complemento,
        UPPER(t.xbairro_dest) as bairro,
        UPPER(t.xmun_dest) as municipio,
        UPPER(t.co_uf_dest) as uf,
        UPPER(t.cep_dest) as cep,
        UPPER(t.fone_dest) as telefone,
        NULL as email,
        t.chave_acesso
    FROM bi.fato_nfce_detalhe t
    WHERE t.co_destinatario = :CPF
),

-- 9. DIMP (Nova Fonte Solicitada)
dimp AS (
    SELECT
        'DIMP' as fonte,
        CAST(NULL AS DATE) as ordem_cronologica,
        NULL as periodo,
        UPPER(t."END") as endereco,
        NULL as numero,
        -- Coloca o Nome Fantasia e CNPJ vinculado no complemento para dar contexto
        UPPER(t.n_fant) || ' (VINC: ' || t.cnpj || ')' as complemento,
        NULL as bairro,
        -- Tenta converter o código do município para nome para padronizar com as outras fontes
        COALESCE(UPPER(l.no_municipio), CAST(t.cod_mun AS VARCHAR(50))) as municipio,
        UPPER(t.uf) as uf,
        t.cep,
        t.fone_cont as telefone,
        t.email_cont as email
    FROM dimp.reg0100s t
    LEFT JOIN bi.dm_localidade l ON t.cod_mun = l.co_municipio
    WHERE t.cpf = :CPF
),

-- =============================================================================
-- BLOCO 2: EMPRESAS VINCULADAS (Nova Consulta Integrada)
-- =============================================================================
empresas_vinculadas AS (
    SELECT
        t.co_cnpj_cpf || '_' || UPPER(t.no_razao_social) as fonte,
        t.da_inicio_atividade as ordem_cronologica,
        to_char(t.da_inicio_atividade, 'YYYY/MM') as periodo,
        
        -- Endereço da empresa
        UPPER(t.DESC_ENDERECO) as endereco,
        NULL as numero, -- Geralmente embutido no DESC_ENDERECO na tabela bi.dm_pessoa
        
        -- CONSOLIDAÇÃO DE DADOS DA EMPRESA NO COMPLEMENTO
        'CNPJ: ' || t.co_cnpj_cpf || ' | RAZÃO: ' || UPPER(t.no_razao_social) || 
        CASE WHEN vencido.total_divida > 0 
             THEN ' | DÍVIDA: R$ ' || TRIM(to_char(vencido.total_divida, '999G999G990D00'))
             ELSE ' | SEM DÍVIDA ATIVA'
        END as complemento,
        
        UPPER(t.BAIRRO) as bairro,
        UPPER(localid.no_municipio) as municipio,
        UPPER(localid.co_uf) as uf,
        NULL as cep,
        NULL as telefone,
        NULL as email,
        NULL as chave_acesso
    FROM bi.dm_pessoa t
    
    -- Filtro de Sócio (traz apenas empresas onde o :CPF é sócio)
    INNER JOIN (
        SELECT DISTINCT substr(h.gr_identificacao, 2) AS cnpj_empresa
        FROM sitafe.sitafe_historico_socio soc
        INNER JOIN sitafe.sitafe_historico_contribuinte h ON soc.it_nu_fac = h.it_nu_fac
        WHERE substr(soc.gr_identificacao, 2) = :CPF
    ) socios ON t.co_cnpj_cpf = socios.cnpj_empresa
    
    LEFT JOIN bi.dm_localidade localid ON t.co_municipio = localid.co_municipio
    
    -- Subquery de Dívida da Empresa
    LEFT JOIN (
        SELECT
            v.co_cnpj_cpf,
            SUM(v.va_principal + v.va_multa + v.va_juros + v.va_acrescimo) AS total_divida
        FROM bi.fato_lanc_arrec_sum v
        WHERE v.vencido = 3 AND v.id_situacao = '01'
        GROUP BY v.co_cnpj_cpf
    ) vencido ON t.co_cnpj_cpf = vencido.co_cnpj_cpf
),

-- =============================================================================
-- BLOCO 3: UNIÃO E CONSOLIDAÇÃO
-- =============================================================================

uniao AS (
    SELECT fonte, ordem_cronologica, periodo, endereco, numero, complemento, bairro, municipio, uf, cep, telefone, email, NULL as chave_acesso FROM detran
    UNION ALL SELECT fonte, ordem_cronologica, periodo, endereco, numero, complemento, bairro, municipio, uf, cep, telefone, email, NULL FROM tse
    UNION ALL SELECT fonte, ordem_cronologica, periodo, endereco, numero, complemento, bairro, municipio, uf, cep, telefone, email, NULL FROM sitafe
    UNION ALL SELECT fonte, ordem_cronologica, periodo, endereco, numero, complemento, bairro, municipio, uf, cep, telefone, email, NULL FROM crc
    UNION ALL SELECT fonte, ordem_cronologica, periodo, endereco, numero, complemento, bairro, municipio, uf, cep, telefone, email, NULL FROM itcd
    UNION ALL SELECT fonte, ordem_cronologica, periodo, endereco, numero, complemento, bairro, municipio, uf, cep, telefone, email, NULL FROM cv115
    UNION ALL SELECT fonte, ordem_cronologica, periodo, endereco, numero, complemento, bairro, municipio, uf, cep, telefone, email, chave_acesso FROM nfe
    UNION ALL SELECT fonte, ordem_cronologica, periodo, endereco, numero, complemento, bairro, municipio, uf, cep, telefone, email, chave_acesso FROM nfce
    UNION ALL SELECT fonte, ordem_cronologica, periodo, endereco, numero, complemento, bairro, municipio, uf, cep, telefone, email, NULL FROM dimp
    UNION ALL SELECT fonte, ordem_cronologica, periodo, endereco, numero, complemento, bairro, municipio, uf, cep, telefone, email, NULL FROM empresas_vinculadas
),

-- Ranking e Deduplicação Final
final AS (
    SELECT 
        u.*,
        ROW_NUMBER() OVER (
            PARTITION BY 
                UPPER(TRIM(u.endereco)), 
                UPPER(TRIM(u.numero)), 
                UPPER(TRIM(u.bairro)),
                UPPER(TRIM(u.municipio))
            ORDER BY u.ordem_cronologica DESC NULLS LAST
        ) as rnk_geral
    FROM uniao u
)

SELECT 
    fonte, 
    periodo, 
    endereco, 
    numero, 
    complemento, 
    bairro, 
    municipio, 
    uf, 
    cep, 
    telefone, 
    email,
    chave_acesso
FROM final
WHERE rnk_geral = 1
ORDER BY 
    ordem_cronologica DESC NULLS LAST