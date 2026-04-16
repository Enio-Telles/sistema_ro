/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > Manifesto(s) > CTE(s)
ESTILO: Table
HABILITADA: true
BINDS:
 - CO_CNPJ_CPF | prompt=CO_CNPJ_CPF | default=NULL_VALUE
 - IT_NU_CHAVE_MDFE | prompt=IT_NU_CHAVE_MDFE | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
WITH chaves_nfe AS(
      SELECT
            bi.fato_nfe_detalhe.chave_acesso
        FROM
            bi.fato_nfe_detalhe
       WHERE
            (bi.fato_nfe_detalhe.co_destinatario = :CO_CNPJ_CPF)
                OR(bi.fato_nfe_detalhe.co_emitente = :CO_CNPJ_CPF)
       GROUP BY
            bi.fato_nfe_detalhe.chave_acesso
)
SELECT
      c.it_nu_chave_acesso,
      c.it_nu_ct,
      c.it_da_emissao,
      c.it_uf_inicio_prestacao,
      c.it_nu_cnpj_emitente,
      c.it_nu_inscricao_emitente,
      c.it_in_nome_emitente,
      c.it_in_fantasia_emitente,
      c.it_nu_cnpj_remetente,
      c.it_nu_cpf_remetente,
      c.it_nu_inscricao_remetente,
      c.it_in_nome_remetente,
      c.it_in_fantasia_remetente,
      c.it_tp_frete,
      c.it_va_total_frete,
      c.it_va_base_calculo,
      c.it_va_valor_icms,
      c.it_nu_placa_trator,
      c.it_nu_cpf_motorista,
      c.it_nu_cnpj_tomador
  FROM
      (
            SELECT DISTINCT
                  m.it_nu_chave_acesso
              FROM
                       sitafe.sitafe_mdfe_item m
                   INNER JOIN sitafe.sitafe_cte_itens    c ON m.it_nu_chave_acesso = c.it_nu_chave_cte
                   INNER JOIN chaves_nfe                 ch ON c.it_nu_chave_nfe = ch.chave_acesso
             WHERE
                  m.it_nu_chave_mdfe = :IT_NU_CHAVE_MDFE
      )                    g
        LEFT JOIN sitafe.sitafe_cte    c ON g.it_nu_chave_acesso = c.it_nu_chave_acesso
