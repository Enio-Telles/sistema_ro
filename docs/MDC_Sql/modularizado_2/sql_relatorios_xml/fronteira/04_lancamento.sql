-- Origem: relatorio_fronteira.xml
-- Título no relatório: Lançamento
-- Caminho no XML: Dossiê Fronteira 2.0 > Destinatário(s) > Nota(s) Fiscal(is) > Lançamento
-- Utilidade fiscal: Altíssima
-- Foco: Traz o lançamento da nota no SITAFE/Fronteira: guia, situação, valores, frete crédito, processo de suspensão e pendência.
-- Uso sugerido: Fundamental para provar se a nota efetivamente gerou lançamento, qual o valor, a situação e se há suspensão/pendência.
-- Riscos/Limites: É nível nota-lançamento; ainda precisa ser combinado com item e mercadoria quando o debate for ST por produto.
-- Tabelas/fontes identificadas: sitafe.sitafe_nf_lancamento
-- Binds declarados: IDENT_NF

SELECT
							it_nu_cpf_auditor         auditor,
							it_co_programa            co_progr,
							it_nu_terminal            terminal,
							it_in_tipo_lancamento     tipo_lanc,
							it_da_vencimento_original da_venc,
							it_co_produto             co_prod,
							it_nu_guia_lancamento     nu_guia,
							it_in_situacao            sit_lanc,
							it_va_bc_mercadoria,
							it_va_icms_total          va_icms_total,
							it_va_total_debito        va_total_debito,
							it_va_total_credito       va_total_credito,
							it_va_total_icms          va_total_icms,
							it_va_frete_credito       va_frete_credito,
							it_nu_processo_suspensao  proc_suspensao,
							it_nu_identificacao_ndf   ndf,
							it_in_pendencia           pendencia
						FROM
							sitafe.sitafe_nf_lancamento
						WHERE
							it_nu_identificacao_nf = :IDENT_NF
