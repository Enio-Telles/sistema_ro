WITH
chaves  as (
                select chave_acesso chaves from bi.fato_nfe_detalhe
                where
                seq_nitem = 1
                and chave_acesso  in (

'35250216603091000190550020000587271087614010'

)),
 nf_lcto AS (
                      SELECT
                        nf.it_nu_identificao_nf_e           AS nf_chave,
                        nfl.it_nu_guia_lancamento           AS guia_lcto,
                        l.stt_lcto                          AS stt_lcto,
                        nfl.it_in_status                    AS status_nf_lcto,
                        SUBSTR(nfl.it_nu_guia_lancamento,5,2) AS tp_cod,
                        nfl.it_va_total_icms                AS vl_calc_nf,
                        l.it_va_principal_original          AS vl_calc_lcto
                      FROM sitafe.sitafe_nf_lancamento nfl
                      JOIN sitafe.sitafe_nota_fiscal nf  ON nf.it_nu_identificacao_nf = nfl.it_nu_identificacao_nf
                      LEFT JOIN (
                                    SELECT
                                      it_nu_guia_lancamento,
                                      it_va_principal_original,
                                      it_co_situacao_lancamento AS stt_lcto
                                    FROM sitafe.sitafe_lancamento
                                    WHERE it_nu_parcela = '00'
                                  ) l    ON l.it_nu_guia_lancamento = nfl.it_nu_guia_lancamento
                      WHERE nf.it_nu_identificao_nf_e in (select chaves from chaves)
),
nf_lcto_tp_lcto AS (
                      SELECT
                        nf_chave,
                        guia_lcto,
                        stt_lcto,
                        status_nf_lcto,
                        CASE tp_cod
                          WHEN '11' THEN 'ST'
                          WHEN '12' THEN 'AT'
                          WHEN '16' THEN 'DA'
                          ELSE 'OUTROS'  END AS tp_lcto,
                        vl_calc_nf,
                        vl_calc_lcto
                      FROM nf_lcto
),
nf_lcto_linhas_unicas AS (
                      SELECT
                        nf_chave AS nf,
                        LISTAGG(    CASE
                                    WHEN status_nf_lcto <> 'C'                THEN tp_lcto || '_' || guia_lcto || ' (' || stt_lcto || ')'
                                    END, '; '    ) WITHIN GROUP (ORDER BY tp_lcto || '_' || guia_lcto) AS guia_lcto_atual,

                        LISTAGG(    CASE WHEN status_nf_lcto <> 'C'           THEN tp_lcto || '_' || TO_CHAR(vl_calc_nf,   'FM999G999G999G990D00')
                                    END, '; '    ) WITHIN GROUP (ORDER BY vl_calc_nf)||' ' AS calc_nf,

                        LISTAGG(    CASE WHEN status_nf_lcto <> 'C'           THEN tp_lcto || '_' || TO_CHAR(vl_calc_lcto, 'FM999G999G999G990D00')
                                    END, '; '    ) WITHIN GROUP (ORDER BY vl_calc_lcto)||' ' AS calc_lcto,

                        LISTAGG(      CASE WHEN status_nf_lcto = 'C'           THEN tp_lcto || '_' || guia_lcto || ' (' || stt_lcto || ')'
                                    END, '; '    ) WITHIN GROUP (ORDER BY tp_lcto || '_' || guia_lcto) AS guia_lcto_anterior

                      FROM nf_lcto_tp_lcto
                      GROUP BY nf_chave
)


SELECT
  TRIM(d.it_nu_chave_acesso)             AS chv_nfe,
  TRIM(d.it_nu_item)                     AS n_item,
  nf.PROD_CPROD                          AS cprod,
  nf.PROD_XPROD                          AS descricao,
  nf.PROD_NCM,
  nf.PROD_CEST,
  NVL(d.it_co_rotina_calculo, 'sem calculo') AS rotina_item,

  d.it_vl_icms                            AS calc_item,
  a.calc_nf,
  a.calc_lcto,
  a.guia_lcto_atual,
  a.guia_lcto_anterior

FROM sitafe.sitafe_nfe_calculo_item d
JOIN bi.fato_nfe_detalhe nf  ON nf.chave_acesso = d.it_nu_chave_acesso AND nf.prod_nitem   = d.it_nu_item
LEFT JOIN nf_lcto_linhas_unicas a  ON a.nf = d.it_nu_chave_acesso
WHERE d.it_nu_chave_acesso in (select nf_chave from nf_lcto)
