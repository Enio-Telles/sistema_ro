-- Origem: relatorio_fronteira.xml
-- Título no relatório: Nota(s) Fiscal(is)
-- Caminho no XML: Dossiê Fronteira 2.0 > Destinatário(s) > Nota(s) Fiscal(is)
-- Utilidade fiscal: Altíssima
-- Foco: Lista as notas fiscais do comando, com chave, datas, emitente, destinatário, UF, bases e valores de ICMS/ST.
-- Uso sugerido: É a consulta documental mais forte do relatório para provar a materialidade fiscal do comando e servir de ponte com lançamentos e cálculos.
-- Riscos/Limites: Não entra no item; para ressarcimento, classificação de mercadoria ou confronto de cálculo, precisa descer ao item.
-- Tabelas/fontes identificadas: sitafe.sitafe_nota_fiscal
-- Binds declarados: COMANDO, CO_CNPJ_CPF

SELECT
						:COMANDO COMANDO,
						t.it_nu_identificacao_nf ident_nf,
						t.it_nu_identificao_nf_e             chave_acesso,
						to_date(t.it_da_entrada, 'yyyymmdd') da_entrada,
						t.it_nu_cnpj_emitente_nf             co_emitente,
						t.it_co_uf_origem                    uf_emit,
						t.it_nucnpj_cpf_destino_nf           co_destinatario,
						t.it_co_uf_destino                   uf_dest,
						t.it_va_bc_icms                      bc_icms,
						t.it_va_icms                         va_icms,
						t.it_va_bc_icms_st                   bc_icms_st,
						t.it_va_icms_st                      va_icms_st,
						t.it_va_nf                           va_nf
					FROM
						sitafe.sitafe_nota_fiscal t
					where t.it_nu_comando = :COMANDO
						and t.it_nucnpj_cpf_destino_nf = :CO_CNPJ_CPF
