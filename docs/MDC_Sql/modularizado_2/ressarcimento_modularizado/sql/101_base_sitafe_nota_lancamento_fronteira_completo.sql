/* ============================================================================
   101_base_sitafe_nota_lancamento_fronteira_completo.sql
   ----------------------------------------------------------------------------
   Objetivo:
   - localizar a nota do BI no SITAFE;
   - abrir o lançamento vinculado;
   - trazer guia, receita, valores e situação do pagamento.

   Dependência lógica:
   - 100_parametros_origem_nfe_fronteira_completo.sql
============================================================================ */

WITH origem_nfe AS (
    SELECT * FROM origem_nfe_fronteira_completo
),
base_lancamento AS (
    SELECT
        nf.it_nu_identificao_nf_e AS chave_acesso,
        nf.it_nu_identificacao_nf,
        nl.it_nu_identificacao_ndf,
        nl.it_nu_guia_lancamento,
        nl.it_da_entrada,
        nl.it_co_comando,
        l.it_co_receita,
        l.it_co_situacao_lancamento,
        l.it_va_principal_original,
        l.it_va_total_pgto_efetuado
    FROM sitafe.sitafe_nota_fiscal nf
    JOIN sitafe.sitafe_nf_lancamento nl
      ON nl.it_nu_identificacao_nf = nf.it_nu_identificacao_nf
    JOIN sitafe.sitafe_lancamento l
      ON l.it_nu_guia_lancamento = nl.it_nu_guia_lancamento
)
SELECT
    o.*,
    b.it_nu_identificacao_nf,
    b.it_nu_identificacao_ndf,
    b.it_nu_guia_lancamento,
    b.it_da_entrada,
    b.it_co_comando,
    b.it_co_receita,
    b.it_co_situacao_lancamento,
    b.it_va_principal_original,
    b.it_va_total_pgto_efetuado
FROM origem_nfe o
JOIN base_lancamento b
  ON b.chave_acesso = o.chave_acesso;
