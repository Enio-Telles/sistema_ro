/*
    Análise da Consulta: CPF_NFCe.sql
    Objetivo: Extrair detalhes de Notas Fiscais ao Consumidor Eletrônicas (NFC-e) onde o CPF
    informado é o DESTINATÁRIO (consumidor final).
    
    Tabela Utilizada:
    - bi.fato_nfce_detalhe (t): Tabela fato com detalhes das NFC-e.
      Similar à NF-e, mas específica para vendas ao consumidor final.
      Colunas: co_destinatario, dhemi, co_emitente, prod_* (produtos), infprot_cstat.

    Lógica Principal:
    1. Filtra notas autorizadas (cstat 100, 150) para o CPF como consumidor.
    2. Calcula o valor do item: (valor produto + frete + seguro - desconto + outros).
    3. Usa GROUPING SETS para gerar múltiplos níveis de agregação.
    4. Estrutura idêntica à CPF_NF.sql, mas para NFC-e.
    
    Diferença NF-e vs NFC-e:
    - NF-e: Operações entre empresas (B2B) ou empresa-pessoa física com maior valor.
    - NFC-e: Vendas no varejo para consumidor final (substitui cupom fiscal).
*/

SELECT
      extract(year from t.dhemi) ano,                         -- Ano de emissão
      t.dhemi data,                                            -- Data/hora de emissão
      t.chave_acesso,                                          -- Chave de acesso (44 dígitos)
      t.co_emitente cnpj,                                      -- CNPJ do estabelecimento vendedor
      upper(t.xnome_emit) nome,                                -- Nome do estabelecimento
      upper(t.xlgr_emit) logradouro,                           -- Endereço do emitente
     upper(t.xbairro_emit) bairro,
      t.nro_emit numero,
     upper( t.xcpl_emit) complemento,
     upper( t.xmun_emit) municipio,
      t.co_uf_emit uf,
      upper(t.prod_xprod) produto,                 -- Descrição do produto
      t.prod_ucom und,                                         -- Unidade
      t.prod_qcom quant,                                       -- Quantidade
      -- Valor total do item (incluindo custos acessórios)
      sum((t.prod_vprod + t.prod_vfrete + t.prod_vseg - t.prod_vdesc + t.prod_voutro)) valor
  FROM
      bi.fato_nfce_detalhe t                                   -- Tabela de NFC-e (diferente de NF-e!)
 WHERE
            t.co_destinatario = :CPF                           -- CPF do consumidor
         AND t.infprot_cstat IN('100', '150')                  -- Notas autorizadas

-- GROUPING SETS: Agregações em múltiplos níveis
group by grouping sets (
      
      (),                                                      -- Total Geral
      (extract(year from t.dhemi)),                            -- Total por Ano
      (t.co_emitente, upper(t.xnome_emit)),                    -- Total por Emitente
      (t.co_uf_emit),                                          -- Total por UF
      (extract(year from t.dhemi),                             -- Detalhe completo
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

-- Ordenação: Totais primeiro, depois detalhes
order by case when ano is null and cnpj is null and uf is null and nome is null  then 1
      when ano is not null and cnpj is null and uf is null then 2
      when ano is not null and cnpj is not null and chave_acesso is not null then 3
      when ano is null and cnpj is null and uf is not null then 4 
      else 5 end, ano desc, data desc, valor desc
      

--dhemi desc