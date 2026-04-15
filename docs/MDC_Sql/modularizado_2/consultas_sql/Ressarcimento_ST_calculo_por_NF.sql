
alter session set nls_numeric_characters='.,';

-- CTE (Common Table Expression) 'portalfiscal'
-- Objetivo: Ler o XML bruto da tabela 'bi.nfe_xml' e transformá-lo em colunas relacionais
with portalfiscal as (
  select a.chave_acesso,
         b.*
  from bi.nfe_xml a,
       -- A função XMLTABLE faz o parsing do XML
       xmltable(
         xmlnamespaces(default 'http://www.portalfiscal.inf.br/nfe'), -- Define o namespace padrão da NFe
         '//det' passing a.xml -- Define que vamos iterar sobre cada tag <det> (detalhe do item) no XML
         columns
           Prod_nItem           number       path '@nItem',      -- Número do item
           PROD_cProd           varchar2(74) path 'prod/cProd',  -- Código do produto
           
           -- Extração do valor do ICMS Substituto 
           icms_vICMSSubstituto number       path 'imposto/ICMS//vICMSSubstituto' default 0,
           
           -- Extração do valor do ICMS ST Retido 
           -- O '//' no path ajuda a encontrar a tag independentemente do grupo de tributação (ex: ICMSSN500, ICMS60, etc)
           icms_vICMSSTRet      number       path 'imposto/ICMS//vICMSSTRet' default 0
       ) b
  where a.chave_acesso in (
    -- Filtro por uma chave de acesso específica
    '13220404565289000570550020018829331210756494'
  )
)

-- Consulta Principal
-- Junta os dados extraídos do XML com a tabela de fatos 'bi.fato_nfe_detalhe'
select 
    d.chave_acesso "CHAVE_ACESSO ULTIMA ENTRADA",
    d.CO_UF_EMIT, 
    d.co_destinatario, 
    d.dhemi, 
    d.seq_nitem, 
    -- Cria uma chave única combinando Chave de Acesso + Número do Item
    d.chave_acesso || '-' || d.seq_nitem CHAVE_ITEM,
    d.PROD_CPROD, 
    d.PROD_XPROD, 
    d.PROD_NCM, 
    d.PROD_CEST, 
    d.PROD_QCOM, 
    d.PROD_UCOM,
    
    -- Cálculo do Valor Unitário Líquido (Produto + Frete + Seguro + Outras Despesas - Desconto - Desoneração) / Quantidade
    round( ( d.PROD_VPROD - d.ICMS_VICMSDESON + d.PROD_VFRETE + d.PROD_VSEG - d.PROD_VDESC + d.PROD_VOUTRO) / d.PROD_QCOM, 2 ) VALOR,
    
    d.CO_CFOP, 
    d.ICMS_ORIG, 
    d.ICMS_CST_A,
    d.ICMS_PICMS, 
    d.ICMS_PICMSST,
    
    -- Cálculos de impostos unitários baseados na tabela fato
    ROUND(d.ICMS_VBCST/d.PROD_QCOM, 2) BC_UNIT_ST,
    ROUND(d.ICMS_VICMSST/d.PROD_QCOM, 2) ICMS_ST_UNIT,
    ROUND(d.ICMS_VICMS/d.PROD_QCOM, 2) ICMS_P_UNIT,
    
    -- Cálculo envolvendo ST Retido e FCP (Fundo de Combate à Pobreza) baseado na tabela fato
    ROUND(d.ICMS_VBCSTRET/d.PROD_QCOM, 2) BC_UNIT_ST_RETIDO,
    ROUND(d.ICMS_VICMSSTRET/d.PROD_QCOM, 2) ST_UNIT_RETIDO,
    
    -- Cálculo usando o valor extraído diretamente do XML (da CTE acima)
    ROUND(x.icms_vICMSSubstituto/d.PROD_QCOM, 2) ICMS_P_UNIT_SUBSTITUTO,

    -- (Opcional/Sugerido) Cálculo usando o novo campo extraído da Imagem 2
    ROUND(x.icms_vICMSSTRet/d.PROD_QCOM, 2) ICMS_P_UNIT_ST_RETIDO_XML

from portalfiscal x
join bi.fato_nfe_detalhe d 
  on x.chave_acesso = d.chave_acesso 
  and x.PROD_nItem = d.PROD_nItem    -- Join pelo número do item
  and x.PROD_cProd = d.PROD_cProd    -- Join pelo código do produto para garantir unicidade