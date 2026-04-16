/*
===============================================================================
MDC 23 - ORQUESTRAÇÃO DE REFERÊNCIA
-------------------------------------------------------------------------------
Objetivo
- Mostrar como materializar o núcleo mínimo comum em views ou tabelas temporárias.
- Esta orquestração não executa tudo sozinha; ela documenta a sequência.
===============================================================================
*/

/* Exemplo de materialização sugerida:

CREATE VIEW mdc_parametros                       AS <00_parametros_canonicos.sql>;
CREATE VIEW mdc_contribuinte                     AS <01_contribuinte_localidade_base.sql>;
CREATE VIEW mdc_efd_reg0000                      AS <02_efd_reg0000_ultima_entrega_base.sql>;
CREATE VIEW mdc_efd_participantes                AS <03_efd_participantes_0150_base.sql>;
CREATE VIEW mdc_efd_produtos                     AS <04_efd_produtos_0200_0220_base.sql>;
CREATE VIEW mdc_efd_c100                         AS <05_efd_c100_documentos_base.sql>;
CREATE VIEW mdc_efd_c170                         AS <06_efd_c170_itens_base.sql>;
CREATE VIEW mdc_efd_c176                         AS <07_efd_c176_ressarcimento_base.sql>;
CREATE VIEW mdc_efd_h                            AS <08_efd_h005_h010_h020_inventario_base.sql>;
CREATE VIEW mdc_efd_c197                         AS <09_efd_c197_ajustes_documentais_base.sql>;
CREATE VIEW mdc_efd_apuracao                     AS <10_efd_apuracao_e110_e210_base.sql>;
CREATE VIEW mdc_efd_ajustes_apuracao             AS <11_efd_ajustes_e111_e220_base.sql>;
CREATE VIEW mdc_docs_bi                          AS <12_bi_documentos_55_65_57_base.sql>;
CREATE VIEW mdc_xml_nfe_extras                   AS <13_bi_xml_nfe_campos_extras_base.sql>;
CREATE VIEW mdc_sitafe_nota_item_calculo         AS <14_sitafe_nota_item_calculo_base.sql>;
CREATE VIEW mdc_sitafe_lancamento_pagamento      AS <15_sitafe_lancamento_pagamento_base.sql>;
CREATE VIEW mdc_dim_codigos                      AS <16_dimensoes_fiscais_cfop_ajustes_base.sql>;
CREATE VIEW mdc_dim_ncm_cest_sefin               AS <17_dimensoes_fiscais_ncm_cest_sefin_base.sql>;
CREATE VIEW mdc_arrecadacao_pendencias           AS <18_arrecadacao_pendencias_base.sql>;
CREATE VIEW mdc_cte_rateio                       AS <19_cte_rateio_frete_base.sql>;
CREATE VIEW mdc_dossie_cadastro                  AS <20_dossie_cadastro_conta_corrente_base.sql>;
CREATE VIEW mdc_dossie_historico                 AS <21_dossie_historico_societario_regime_base.sql>;
CREATE VIEW mdc_dossie_acao_fiscal               AS <22_dossie_acao_fiscal_base.sql>;

Famílias derivadas suportadas:
- Ressarcimento C176 / V4 / pós-2022
- Mudança de tributação e inventário (Bloco H)
- Fronteira até 2022 e após 2022
- Fronteira completo (conciliação BI x SITAFE)
- Auditoria EFD x documentos 55/65/57
- Relatórios XML EFD Master e Dossiê Fronteira
- Núcleo fiscal-cadastral dos dossiês XML de contribuinte e pessoa física
*/
SELECT 'Ver README e minimo_denominador_comum.md' AS orientacao FROM dual;
