-- Origem: EFD_master.xml
-- Título no relatório: Apuração E110
-- Caminho no XML: EFD Master 2.0 > Apuração E110
-- Utilidade fiscal: Altíssima
-- Foco: Fechamento consolidado da apuração própria de ICMS: débitos, créditos, ajustes, saldo, deduções, recolher e saldo a transportar.
-- Uso sugerido: Fechamento macro da conta gráfica do imposto próprio; base para confrontar com E111 e arrecadação.
-- Riscos/Limites: Não mostra origem documental; deve ser lido junto com C197, E111, C100/C170 e arrecadação.
-- Tabelas/fontes identificadas: bi.fato_efd_sumarizada, bi.dm_pessoa
-- Binds declarados: CNPJ_CPF, INFO, DATA_INICIAL, DATA_FINAL

SELECT
    '<html><b>'||:CNPJ_CPF "CNPJ",
    '<html><b>'||p.no_razao_social "Nome",
    '<html><b>'||:INFO "Período da pesquisa",
   '<html><p style="color:red">'||lpad(TRIM(to_char(SUM(t.vl_tot_debitos), '999G999G999G990D00')), length(MAX(SUM(t.vl_tot_debitos))
                                                                        OVER()) + 6)      "V. Total Débitos - Saídas",
   '<html><p style="color:red">'||lpad(TRIM(to_char(SUM(t.vl_aj_debitos), '999G999G999G990D00')), length(MAX(SUM(t.vl_aj_debitos))
                                                                        OVER()) + 6)      "V. Total Aj. a Déb. Doc Fisc",
   '<html><p style="color:red">'||lpad(TRIM(to_char(SUM(t.vl_tot_aj_debitos), '999G999G999G990D00')), length(MAX(SUM(t.vl_tot_aj_debitos))
                                                                        OVER()) + 6)      "V. Total dos Aj. a Débito",
   '<html><p style="color:red">'||lpad(TRIM(to_char(SUM(t.vl_estornos_cred), '999G999G999G990D00')), length(MAX(SUM(t.vl_estornos_cred))
                                                                        OVER()) + 6)      "V. Total dos Aj.  Est. Créd.",
   '<html><p style="color:blue">'||lpad(TRIM(to_char(SUM(t.vl_tot_creditos), '999G999G999G990D00')), length(MAX(SUM(t.vl_tot_creditos))
                                                                        OVER()) + 6)      "V. Total Créditos - Entradas",
   '<html><p style="color:blue">'||lpad(TRIM(to_char(SUM(t.vl_aj_creditos), '999G999G999G990D00')), length(MAX(SUM(t.vl_aj_creditos))
                                                                        OVER()) + 6)      "V. Total Aj. Créd. Doc Fisc.",
   '<html><p style="color:blue">'||lpad(TRIM(to_char(SUM(t.vl_tot_aj_creditos), '999G999G999G990D00')), length(MAX(SUM(t.vl_tot_aj_creditos))
                                                                        OVER()) + 6)      "V. Total dos Aj. a Crédito",
   '<html><p style="color:blue">'||lpad(TRIM(to_char(SUM(t.vl_estornos_deb), '999G999G999G990D00')), length(MAX(SUM(t.vl_estornos_deb))
                                                                        OVER()) + 6)      "V. Total dos Aj.  Est. Déb.",
   '<html><p style="color:blue">'||lpad(TRIM(to_char(SUM(t.vl_sld_credor_ant), '999G999G999G990D00')), length(MAX(SUM(t.vl_sld_credor_ant))
                                                                        OVER()) + 6)      "V. Sld. Cred. Per Ant.",
   '<html>'||lpad(TRIM(to_char(SUM(t.vl_sld_apurado), '999G999G999G990D00')), length(MAX(SUM(t.vl_sld_apurado))
                                                                        OVER()) + 6)      "V. Saldo Devedor Apurado",
    '<html>'||lpad(TRIM(to_char(SUM(t.vl_tot_ded), '999G999G999G990D00')), length(MAX(SUM(t.vl_tot_ded))
                                                                        OVER()) + 6)      "V. Total de Deduções",
   '<html><b style="color:red">'||lpad(TRIM(to_char(SUM(t.vl_recolher), '999G999G999G990D00')), length(MAX(SUM(t.vl_recolher))
                                                                        OVER()) + 6)      "V. Total de ICMS a Recolher",
   '<html><b style="color:blue">'||lpad(TRIM(to_char(SUM(t.vl_sld_credor_transportar), '999G999G999G990D00')), length(MAX(SUM(t.vl_sld_credor_transportar))
                                                                        OVER()) + 6)      "V. Sld. Cred. a Transp.",
    '<html>'||lpad(TRIM(to_char(SUM(t.vl_deb_esp), '999G999G999G990D00')), length(MAX(SUM(t.vl_deb_esp))
                                                                        OVER()) + 6)      "V. Rec. Extra-Apuração"

FROM
    bi.fato_efd_sumarizada t
left join bi.dm_pessoa p on t.CO_CNPJ_CPF_DECLARANTE = p.co_cnpj_cpf

WHERE
        t.co_cnpj_cpf_declarante = :CNPJ_CPF
    AND t.da_referencia between :DATA_INICIAL and :DATA_FINAL
    AND t.registro = 'E110'
group by p.no_razao_social
