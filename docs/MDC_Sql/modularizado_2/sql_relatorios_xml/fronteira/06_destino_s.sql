-- Origem: relatorio_fronteira.xml
-- Título no relatório: Destino(s)
-- Caminho no XML: Dossiê Fronteira 2.0 > Destino(s)
-- Utilidade fiscal: Média/Alta
-- Foco: Agrupa o comando por município/UF de destino, somando valor de mercadorias.
-- Uso sugerido: Boa camada geográfica para detectar redistribuição, concentração regional e coerência logística.
-- Riscos/Limites: É consulta analítica de apoio; raramente decide sozinha uma conclusão tributária.
-- Tabelas/fontes identificadas: sitafe.sitafe_nota_fiscal, sitafe.sitafe_nfe_item, bi.dm_pessoa, bi.dm_localidade
-- Binds declarados: COMANDO

SELECT
l.no_municipio,
l.co_uf,
lpad(TRIM(to_char(sum(it_va_produto), '999G999G999G990D00')), length(MAX(sum(it_va_produto))
                                                                                                         OVER()) + 6)
 total

FROM
    sitafe.sitafe_nota_fiscal t
left join sitafe.sitafe_nfe_item it on t.it_nu_identificao_nf_e = it.it_nu_chave_acesso
left join bi.dm_pessoa p on t.it_nucnpj_cpf_destino_nf = p.co_cnpj_cpf
left join bi.dm_localidade l on p.co_municipio = l.co_municipio
where it_nu_comando = :COMANDO
group by l.no_municipio, l.co_uf
ORDER BY total desc
