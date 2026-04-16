-- Origem: relatorio_fronteira.xml
-- Título no relatório: Mercadoria
-- Caminho no XML: Dossiê Fronteira 2.0 > Mercadoria
-- Utilidade fiscal: Alta
-- Foco: Agrupa mercadorias do comando por descrição, NCM e unidade, com quantidade e valor.
-- Uso sugerido: Ótimo resumo da cesta de produtos do comando e excelente apoio para triagem de NCM/ST e risco de classificação.
-- Riscos/Limites: Descrição/NCM agregados não substituem prova item a item quando houver mercadoria heterogênea com mesma descrição.
-- Tabelas/fontes identificadas: sitafe.sitafe_nfe_item, sitafe.sitafe_nota_fiscal
-- Binds declarados: COMANDO

SELECT
t.it_no_produto, t.it_co_ncm, t.it_un_comercial, sum(t.it_qt_comercial) quant, sum(t.it_va_produto) total
  FROM
      sitafe.sitafe_nfe_item t
where t.it_nu_chave_acesso in(select IT_NU_IDENTIFICAO_NF_E from sitafe.sitafe_nota_fiscal n
                                                            where n.it_nu_comando = :COMANDO)
group by t.it_no_produto, t.it_co_ncm, t.it_un_comercial

order by sum(t.it_va_produto) desc
