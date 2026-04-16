/* ============================================================================
   sql_basicas/16_base_sitafe_fronteira_lancamentos.sql
   ----------------------------------------------------------------------------
   Objetivo:
   - criar uma base compartilhada do lançamento de fronteira/SITAFE por nota;
   - separar nota fiscal, vínculo com lançamento e situação do pagamento.

   Uso recomendado:
   - trilhas de auditoria de Fronteira;
   - lastro de ressarcimento e de antecipação;
   - reconciliação NFe x SITAFE.

   Observação:
   - esta base não decide direito creditório;
   - ela apenas prova a existência do lançamento e do pagamento/situação.
============================================================================ */

WITH parametros AS (
    SELECT :cnpj AS cnpj_filtro FROM dual
),
nota_fiscal_sitafe AS (
    SELECT
        nf.it_nu_identificao_nf_e AS chave_acesso,
        nf.it_nu_identificacao_nf,
        nf.it_nucnpj_cpf_destino_nf
    FROM sitafe.sitafe_nota_fiscal nf
    JOIN parametros p
      ON nf.it_nucnpj_cpf_destino_nf = p.cnpj_filtro
),
nf_lancamento AS (
    SELECT
        nl.it_nu_identificacao_nf,
        nl.it_nu_identificacao_ndf,
        nl.it_nu_guia_lancamento,
        nl.it_da_entrada,
        nl.it_co_comando,
        nl.it_nu_cnpj_cpf_destino_nf
    FROM sitafe.sitafe_nf_lancamento nl
    JOIN parametros p
      ON nl.it_nu_cnpj_cpf_destino_nf = p.cnpj_filtro
),
lancamento AS (
    SELECT
        l.it_nu_guia_lancamento,
        l.it_co_receita,
        l.it_co_situacao_lancamento,
        l.it_va_principal_original,
        l.it_va_total_pgto_efetuado
    FROM sitafe.sitafe_lancamento l
)
SELECT
    nf.chave_acesso,
    nf.it_nu_identificacao_nf,
    nl.it_nu_identificacao_ndf,
    nl.it_nu_guia_lancamento,
    nl.it_da_entrada,
    nl.it_co_comando,
    l.it_co_receita,
    l.it_co_situacao_lancamento,
    l.it_va_principal_original,
    l.it_va_total_pgto_efetuado
FROM nota_fiscal_sitafe nf
JOIN nf_lancamento nl
  ON nl.it_nu_identificacao_nf = nf.it_nu_identificacao_nf
LEFT JOIN lancamento l
  ON l.it_nu_guia_lancamento = nl.it_nu_guia_lancamento;
