-- Origem: relatorio_fronteira.xml
-- Título no relatório: Destinatário(s)
-- Caminho no XML: Dossiê Fronteira 2.0 > Destinatário(s)
-- Utilidade fiscal: Alta
-- Foco: Concentra destinatários por comando, com valor total de mercadorias.
-- Uso sugerido: Mostra quem efetivamente recebe as mercadorias vinculadas ao comando e o peso econômico por destinatário.
-- Riscos/Limites: Usa valor itemizado de sitafe_nfe_item; diferenças de qualidade do cadastro do destinatário afetam município/UF.
-- Tabelas/fontes identificadas: sitafe.sitafe_nota_fiscal, sitafe.sitafe_nfe_item, bi.dm_pessoa, bi.dm_localidade
-- Binds declarados: COMANDO

SELECT
:COMANDO COMANDO,
t.it_nucnpj_cpf_destino_nf co_cnpj_cpf,
'<html><b>'||p.no_razao_social nome,
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
group by t.it_nucnpj_cpf_destino_nf, p.no_razao_social, l.no_municipio, l.co_uf
ORDER BY total desc
