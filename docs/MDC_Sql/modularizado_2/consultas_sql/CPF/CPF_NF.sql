/*
    Análise da Consulta: CPF_NF.sql
    Objetivo: Extrair detalhes de Notas Fiscais Eletrônicas (NF-e) onde o CPF informado
    é o DESTINATÁRIO da mercadoria.

    Tabela Utilizada:
    - bi.fato_nfe_detalhe (t): Tabela fato com detalhes das NF-e.
      Colunas Chave: co_destinatario (CPF/CNPJ destino), dhemi (data emissão),
      co_emitente (CNPJ emitente), prod_* (dados do produto), infprot_cstat (status).

    Lógica Principal:
    1. Filtra notas autorizadas (cstat 100, 150) para o CPF como destinatário.
    2. Calcula o valor do item: (valor produto + frete + seguro - desconto + outros).
    3. Usa GROUPING SETS para gerar múltiplos níveis de agregação:
       - Total Geral (sem agrupamento)
       - Total por Ano
       - Total por Emitente (CNPJ/Nome)
       - Total por UF do Emitente
       - Detalhe completo (linha a linha por item)
    4. Ordena priorizando totais gerais, depois por ano, data e valor.
*/

SELECT
      extract(year from t.dhemi) ano,                         -- Ano de emissão da NF-e
      t.dhemi data,                                            -- Data/hora de emissão
      t.chave_acesso,                                          -- Chave de acesso da NF-e (44 dígitos)
      t.co_emitente cnpj,                                      -- CNPJ do emitente
      upper(t.xnome_emit) nome,                                -- Razão social do emitente
      upper(t.xlgr_emit) logradouro,                           -- Endereço do emitente
     upper(t.xbairro_emit) bairro,
      t.nro_emit numero,
     upper( t.xcpl_emit) complemento,
     upper( t.xmun_emit) municipio,
      t.co_uf_emit uf,                                         -- UF do emitente
      upper(t.prod_xprod) produto,                 -- Descrição do produto (HTML bold)
      t.prod_ucom und,                                         -- Unidade comercial
      t.prod_qcom quant,                                       -- Quantidade comercializada
      -- Cálculo do valor total do item
      sum((t.prod_vprod + t.prod_vfrete + t.prod_vseg - t.prod_vdesc + t.prod_voutro)) valor
  FROM
      bi.fato_nfe_detalhe t
 WHERE
            t.co_destinatario = :CPF                           -- Filtro pelo CPF do destinatário
         AND t.infprot_cstat IN('100', '150')                  -- Apenas notas autorizadas

-- GROUPING SETS: Gera agregações em múltiplos níveis em uma única query
group by grouping sets (

      (),                                                      -- Nível 1: Total Geral (tudo NULL)
      (extract(year from t.dhemi)),                            -- Nível 2: Total por Ano
      (t.co_emitente, upper(t.xnome_emit)),                    -- Nível 3: Total por Emitente
      (t.co_uf_emit),                                          -- Nível 4: Total por UF
      (extract(year from t.dhemi),                             -- Nível 5: Detalhe completo
       t.dhemi,
       t.chave_acesso,
       t.co_emitente,
       upper(t.xnome_emit),
       upper(t.xlgr_emit),
       upper(t.xbairro_emit),
       t.nro_emit,
       upper(t.xcpl_emit),
       upper(t.xmun_emit),
       t.co_uf_emit,
       upper(t.prod_xprod),
       t.prod_ucom,
       t.prod_qcom)

      )

-- Ordenação hierárquica: Totais primeiro, depois detalhes
order by case when ano is null and cnpj is null and uf is null and nome is null  then 1  -- Total Geral
      when ano is not null and cnpj is null and uf is null then 2                         -- Total Ano
      when ano is not null and cnpj is not null and chave_acesso is not null then 3       -- Detalhe
      when ano is null and cnpj is null and uf is not null then 4                         -- Total UF
      else 5 end, ano desc, data desc, valor desc


--dhemi desc
