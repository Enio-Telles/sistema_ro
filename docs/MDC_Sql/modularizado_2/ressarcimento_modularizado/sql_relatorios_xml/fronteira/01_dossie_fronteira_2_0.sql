-- Origem: relatorio_fronteira.xml
-- Título no relatório: Dossiê Fronteira 2.0
-- Caminho no XML: Dossiê Fronteira 2.0
-- Utilidade fiscal: Altíssima
-- Foco: Porta de entrada do dossiê, localizando comando de Fronteira por comando, motorista, placa, emitente, destinatário ou chave.
-- Uso sugerido: Excelente para começar investigação logística-fiscal de entrada interestadual, principalmente quando ainda não se conhece o número do comando.
-- Riscos/Limites: O desenho usa unions por múltiplas chaves; em casos com muito reaproveitamento de placa/CPF pode trazer universo mais amplo que o desejado.
-- Tabelas/fontes identificadas: sitafe.sitafe_comando, sitafe.sitafe_nota_fiscal
-- Binds declarados: NU_COMANDO, CPF_MOTORISTA, PLACA_TRATOR, CNPJ_DESTINATARIO, CNPJ_EMITENTE, CHAVE_ACESSO

SELECT
      t.it_nu_comando comando,
      t.it_da_transacao data_trans,
      t.it_cpf_motorista cpf_motorista,
      t.it_nu_placa_tracao placa,
      t.it_nu_placa_reboque1 placa_reb_1,
      t.it_nu_placa_reboque2 placa_reb_2,
      t.it_qtd_nota quant_nfs,
      t.it_qtd_conhecimento quant_conhec,
      t.it_da_liberacao da_liberacao,
      t.it_cpf_auditor_liberacao auditor,
      t.it_cgc_transportadora cnpj_transp,
      t.it_proprietario_veiculo cnpj_cpf_prop_veic
  FROM
      sitafe.sitafe_comando t
 WHERE
       t.it_nu_comando  IN(SELECT IT_NU_COMANDO FROM(
                                                SELECT
                                                      t.it_nu_comando
                                                  FROM
                                                      sitafe.sitafe_comando t
                                                 WHERE
                                                     t.it_nu_comando = case when :NU_COMANDO is null then '99999999999999999999' else :NU_COMANDO end

                                                UNION

                                                SELECT
                                                      t.it_nu_comando
                                                  FROM
                                                      sitafe.sitafe_comando t
                                                 WHERE
                                                     t.it_cpf_motorista = case when :CPF_MOTORISTA is null then '99999999999999999999' else :CPF_MOTORISTA end

                                                UNION

                                                SELECT
                                                      t.it_nu_comando
                                                  FROM
                                                      sitafe.sitafe_comando t
                                                 WHERE
                                                     t.it_nu_placa_tracao = case when :PLACA_TRATOR is null then '99999999999999999999' else :PLACA_TRATOR end

                                                UNION

                                                SELECT
                                                      it_nu_comando
                                                  FROM
                                                      sitafe.sitafe_nota_fiscal f
                                                 WHERE
                                                       f.it_nucnpj_cpf_destino_nf = case when :CNPJ_DESTINATARIO is null then '99999999999999999999' else :CNPJ_DESTINATARIO end

                                                UNION

                                                SELECT
                                                      it_nu_comando
                                                  FROM
                                                      sitafe.sitafe_nota_fiscal f
                                                 WHERE
                                                       f.IT_NU_CNPJ_EMITENTE_NF = case when :CNPJ_EMITENTE is null then '99999999999999999999' else :CNPJ_EMITENTE end

                                                UNION

                                                SELECT
                                                      it_nu_comando
                                                  FROM
                                                      sitafe.sitafe_nota_fiscal f
                                                 WHERE
                                                       f.IT_NU_IDENTIFICAO_NF_E = case when :CHAVE_ACESSO is null then '99999999999999999999' else :CHAVE_ACESSO end))


ORDER BY t.it_da_liberacao desc
