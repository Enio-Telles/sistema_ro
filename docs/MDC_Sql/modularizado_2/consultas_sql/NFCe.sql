WITH parametros AS (
    SELECT
        :CNPJ AS cnpj_filtro,
        TO_DATE(:DATA_INI, 'DD/MM/YYYY') AS data_inicial,
        TO_DATE(:DATA_FIM, 'DD/MM/YYYY') AS data_final
    FROM DUAL
)
SELECT
    -- Lógica para definir o tipo de operação (Entrada/Saída) baseada no CNPJ filtro
    CASE
        WHEN d.co_destinatario = p.cnpj_filtro AND d.co_tp_nf = 1 THEN 'ENTRADA'
        WHEN d.co_destinatario = p.cnpj_filtro AND d.co_tp_nf = 0 THEN 'ENTRADA'
        WHEN d.co_emitente     = p.cnpj_filtro AND d.co_tp_nf = 0 THEN 'ENTRADA'
        WHEN d.co_emitente     = p.cnpj_filtro AND d.co_tp_nf = 1 THEN 'SAIDA'
        ELSE 'DESCONHECIDO'
    END AS entrada_saida,

    d.NSU, -- Número Sequencial Único (Controle de distribuição/banco de dados)
    d.CHAVE_ACESSO, -- Chave de Acesso da NF-e (ID: A03)
    d.PROD_NITEM, -- Número do item (1-990) (ID: H02)

    -- Grupo B. Identificação da Nota Fiscal eletrônica
    d.IDE_CO_CUF, -- Código da UF do emitente do Documento Fiscal (ID: B02)
    d.IDE_CO_INDPAG, -- Indicador da forma de pagamento (ID: B05)
    d.IDE_CO_MOD, -- Código do Modelo do Documento Fiscal (55=NFe, 65=NFCe) (ID: B06)
    d.IDE_SERIE, -- Série do Documento Fiscal (ID: B07)
    d.NNF, -- Número do Documento Fiscal (ID: B08)
    d.DHEMI, -- Data e hora de emissão do Documento Fiscal (ID: B09)
    d.CO_TP_NF, -- Tipo de Operação (0=Entrada; 1=Saída) (ID: B11)
    d.CO_IDDEST, -- Identificador de local de destino da operação (ID: B11a)
    d.CO_CMUN_FG, -- Código do Município de Ocorrência do Fato Gerador (ID: B12)
    d.CO_TPEMIS, -- Tipo de Emissão da NF-e (ID: B22)
    d.CO_FINNFE, -- Finalidade de emissão da NF-e (ID: B25)
    d.CO_INDFINAL, -- Indica operação com Consumidor final (ID: B25a)
    d.CO_INDPRES, -- Indicador de presença do comprador no estabelecimento (ID: B25b)

    -- Grupo C. Identificação do Emitente
    d.CO_EMITENTE, -- CNPJ/CPF do emitente (ID: C02/C02a)
    d.XNOME_EMIT, -- Razão Social ou Nome do emitente (ID: C03)
    d.XFANT_EMIT, -- Nome fantasia do emitente (ID: C04)
    d.CO_UF_EMIT, -- Sigla da UF do emitente (ID: C12)
    d.CO_CAD_ICMS_EMIT, -- Inscrição Estadual do Emitente (ID: C17)
    d.CO_CRT, -- Código de Regime Tributário (1=Simples Nacional, 3=Normal) (ID: C21)

    -- Endereço do Emitente (Grupo C05)
    d.XLGR_EMIT, -- Logradouro do emitente
    d.NRO_EMIT, -- Número do endereço do emitente
    d.XCPL_EMIT, -- Complemento do endereço do emitente
    d.XBAIRRO_EMIT, -- Bairro do emitente
    d.CO_CMUN_EMIT, -- Código do município do emitente
    d.XMUN_EMIT, -- Nome do município do emitente
    d.CEP_EMIT, -- Código do CEP do emitente
    d.CPAIS_EMIT, -- Código do País do emitente
    d.XPAIS_EMIT, -- Nome do País do emitente
    d.FONE_EMIT, -- Telefone do emitente

    -- Grupo E. Identificação do Destinatário
    d.CO_DESTINATARIO, -- CNPJ/CPF do destinatário (ID: E02/E03)
    d.XNOME_DEST, -- Razão Social ou nome do destinatário (ID: E04)
    d.CO_UF_DEST, -- Sigla da UF do destinatário (ID: E12)
    d.CO_INDIEDEST, -- Indicador da IE do Destinatário (ID: E16a)

    -- Endereço do Destinatário (Grupo E05)
    d.XLGR_DEST, -- Logradouro do destinatário
    d.NRO_DEST, -- Número do endereço do destinatário
    d.XCPL_DEST, -- Complemento do endereço do destinatário
    d.XBAIRRO_DEST, -- Bairro do destinatário
    d.CO_CMUN_DEST, -- Código do município do destinatário
    d.XMUN_DEST, -- Nome do município do destinatário
    d.CEP_DEST, -- Código do CEP do destinatário
    d.CPAIS_DEST, -- Código do País do destinatário
    d.XPAIS_DEST, -- Nome do País do destinatário
    d.FONE_DEST, -- Telefone do destinatário

    -- Grupo I. Produtos e Serviços
    d.PROD_CPROD, -- Código do produto ou serviço (ID: I02)
    d.PROD_CEAN, -- GTIN (EAN) do produto (ID: I03)
    d.PROD_XPROD, -- Descrição do produto ou serviço (ID: I04)
    d.PROD_NCM, -- Código NCM com 8 dígitos (ID: I05)
    d.CO_CFOP, -- Código Fiscal de Operações e Prestações (ID: I08)
    d.PROD_UCOM, -- Unidade Comercial (ID: I09)
    d.PROD_QCOM, -- Quantidade Comercial (ID: I10)
    d.PROD_VUNCOM, -- Valor Unitário de Comercialização (ID: I10a)
    d.PROD_VPROD, -- Valor Total Bruto dos Produtos ou Serviços (ID: I11)
    d.PROD_CEANTRIB, -- GTIN (EAN) da unidade tributável (ID: I12)
    d.PROD_UTRIB, -- Unidade Tributável (ID: I13)
    d.PROD_QTRIB, -- Quantidade Tributável (ID: I14)
    d.PROD_VUNTRIB, -- Valor Unitário de tributação (ID: I14a)
    d.PROD_VFRETE, -- Valor Total do Frete (Item) (ID: I15)
    d.PROD_VSEG, -- Valor Total do Seguro (Item) (ID: I16)
    d.PROD_VDESC, -- Valor do Desconto (Item) (ID: I17)
    d.PROD_VOUTRO, -- Outras despesas acessórias (Item) (ID: I17a)
    d.PROD_INDTOT, -- Indica se valor do Item compõe o valor total da NF-e (ID: I17b)

    -- Grupo N. Tributos ICMS
    d.ICMS_CSOSN, -- Código de Situação da Operação - Simples Nacional (ID: N12a)
    d.ICMS_CST, -- Tributação do ICMS (CST Normal) (ID: N12)
    d.ICMS_MODBC, -- Modalidade de determinação da BC do ICMS (ID: N13)
    d.ICMS_MODBCST, -- Modalidade de determinação da BC do ICMS ST (ID: N18)
    d.ICMS_MOTDESICMS, -- Motivo da desoneração do ICMS (ID: N28)
    d.ICMS_ORIG, -- Origem da mercadoria (ID: N11)
    d.ICMS_PBCOP, -- Percentual da BC operação própria (ID: N25)
    d.ICMS_PCREDSN, -- Alíquota aplicável de cálculo do crédito (Simples Nacional) (ID: N29)
    d.ICMS_PDIF, -- Percentual do diferimento (ID: N16b)
    d.ICMS_PICMS, -- Alíquota do imposto (ID: N16)
    d.ICMS_PICMSST, -- Alíquota do imposto do ICMS ST (ID: N22)
    d.ICMS_PMVAST, -- Percentual da margem de valor Adicionado do ICMS ST (ID: N19)
    d.ICMS_PREDBC, -- Percentual da Redução de BC (ID: N14)
    d.ICMS_PREDBCST, -- Percentual da Redução de BC do ICMS ST (ID: N20)
    d.ICMS_UFST, -- UF para qual é devido o ICMS ST (ID: N24)
    d.ICMS_VBC, -- Valor da BC do ICMS (ID: N15)
    d.ICMS_VBCST, -- Valor da BC do ICMS ST (ID: N21)
    d.ICMS_VBCSTDEST, -- Valor da BC do ICMS ST da UF destino (ID: N31)
    d.ICMS_VBCSTRET, -- Valor da BC do ICMS ST retido (ID: N26)
    d.ICMS_VCREDICMSSN, -- Valor crédito do ICMS (Simples Nacional) (ID: N30)
    d.ICMS_VICMS, -- Valor do ICMS (ID: N17)
    d.ICMS_VICMSDESON, -- Valor do ICMS desonerado (ID: N28a)
    d.ICMS_VICMSDIF, -- Valor do ICMS diferido (ID: N16c)
    d.ICMS_VICMSOP, -- Valor do ICMS da Operação (ID: N16a)
    d.ICMS_VICMSST, -- Valor do ICMS ST (ID: N23)
    d.ICMS_VICMSSTDEST, -- Valor do ICMS ST da UF destino (ID: N32)
    d.ICMS_VICMSSTRET, -- Valor do ICMS ST retido (ID: N27)

    -- Fundo de Combate à Pobreza (FCP)
    d.ICMS_VBCFCP, -- Valor da Base de Cálculo do FCP (ID: N17a)
    d.ICMS_PFCP, -- Percentual do FCP (ID: N17b)
    d.ICMS_VFCP, -- Valor do FCP (ID: N17c)
    d.ICMS_VBCFCPST, -- Valor da Base de Cálculo do FCP retido por ST (ID: N23a)
    d.ICMS_PFCPST, -- Percentual do FCP retido por ST (ID: N23b)
    d.ICMS_VFCPST, -- Valor do FCP retido por ST (ID: N23d)

    -- ICMS Interestadual (Difal)
    d.ICMS_VBCUFDEST, -- Valor da BC do ICMS na UF de destino (ID: NA03)
    d.ICMS_VBCFCPUFDEST, -- Valor da BC FCP na UF de destino (ID: NA04)
    d.ICMS_PFCPUFDEST, -- Percentual do FCP na UF de destino (ID: NA05)
    d.ICMS_PICMSUFDEST, -- Alíquota interna da UF de destino (ID: NA07)
    d.ICMS_PICMSINTER, -- Alíquota interestadual das UF envolvidas (ID: NA09)
    d.ICMS_PICMSINTERPART, -- Percentual provisório de partilha do ICMS Interestadual (ID: NA11)
    d.ICMS_VFCPUFDEST, -- Valor do FCP da UF de destino (ID: NA13)
    d.ICMS_VICMSUFDEST, -- Valor do ICMS Interestadual para a UF de destino (ID: NA15)
    d.ICMS_VICMSUFREMET, -- Valor do ICMS Interestadual para a UF do remetente (ID: NA17)

    -- Campos Adicionais ICMS
    d.ICMS_PST, -- Alíquota suportada pelo Consumidor Final (ID: N26a)
    d.ICMS_VBCFCPSTRET, -- Valor da BC do FCP retido anteriormente (ID: N27a)
    d.ICMS_PFCPSTRET, -- Percentual do FCP retido anteriormente (ID: N27b)
    d.ICMS_VFCPSTRET, -- Valor do FCP retido anteriormente (ID: N27d)
    d.ICMS_PREDBCEFET, -- Percentual de redução da base de cálculo efetiva (ID: N34)
    d.ICMS_VBCEFET, -- Valor da base de cálculo efetiva (ID: N35)
    d.ICMS_PICMSEFET, -- Alíquota do ICMS efetiva (ID: N36)
    d.ICMS_VICMSEFET, -- Valor do ICMS efetivo (ID: N37)

    -- Grupo W. Total da NF-e
    d.TOT_VBC, -- Base de Cálculo do ICMS (Total) (ID: W03)
    d.TOT_VICMS, -- Valor Total do ICMS (ID: W04)
    d.TOT_VICMSDESON, -- Valor Total do ICMS desonerado (ID: W04a)
    d.TOT_VBCST, -- Base de Cálculo do ICMS ST (Total) (ID: W05)
    d.TOT_VST, -- Valor Total do ICMS ST (ID: W06)
    d.TOT_VPROD, -- Valor Total dos produtos e serviços (ID: W07)
    d.TOT_VFRETE, -- Valor Total do Frete (ID: W08)
    d.TOT_VSEG, -- Valor Total do Seguro (ID: W09)
    d.TOT_VDESC, -- Valor Total do Desconto (ID: W10)
    d.TOT_VII, -- Valor Total do II (ID: W11)
    d.TOT_VIPI, -- Valor Total do IPI (ID: W12)
    d.TOT_VPIS, -- Valor do PIS (Total) (ID: W13)
    d.TOT_VCOFINS, -- Valor da COFINS (Total) (ID: W14)
    d.TOT_VOUTRO, -- Outras Despesas acessórias (Total) (ID: W15)
    d.TOT_VNF, -- Valor Total da NF-e (ID: W16)
    d.TOT_VTOTTRIB, -- Valor aproximado total de tributos (ID: W16a)
    d.TOT_VFCPUFDEST, -- Valor total do FCP da UF de destino (ID: W04c)
    d.TOT_VICMSUFDEST, -- Valor total do ICMS Interestadual para a UF de destino (ID: W04e)
    d.TOT_VICMSUFREMET, -- Valor total do ICMS Interestadual para a UF do remetente (ID: W04g)
    d.TOT_VFCP, -- Valor Total do FCP (ID: W04h)
    d.TOT_VFCPST, -- Valor Total do FCP retido por ST (ID: W06a)
    d.TOT_VFCPSTRET, -- Valor Total do FCP retido anteriormente por ST (ID: W06b)
    d.TOT_VIPIDEVOL, -- Valor Total do IPI devolvido (ID: W12a)

    -- Campos de Controle e Auditoria
    d.INFPROT_CSTAT, -- Código do status da resposta (100=Autorizado, 150=Autorizado fora de prazo)
    d.ICMS_CSOSN_A, -- CSOSN Apurado (Interno BI)
    d.ICMS_CST_A, -- CST Apurado (Interno BI)
    d.DT_GRAVACAO, -- Data de gravação do registro (Interno BI)
    d.SEQ_NITEM, -- Sequencial do item (Interno BI)
    d.DHEMI_HORA, -- Hora da emissão (Extraído de DHEMI)
    d.STATUS_CARGA_CAMPO_FCP, -- Status de carga (Interno BI)
    d.PROD_CEST -- Código Especificador da Substituição Tributária (ID: 105c)

FROM bi.fato_nfce_detalhe d,
    parametros p
WHERE
    d.dhemi BETWEEN p.data_inicial AND p.data_final
    AND (d.co_destinatario = p.cnpj_filtro OR d.co_emitente = p.cnpj_filtro)
    AND d.INFPROT_CSTAT in (100,150)
    --AND PROD_CPROD LIKE '%226052'
    -- AND ENTRADA_SAIDA
ORDER BY
    d.dhemi ASC,
    d.nsu ASC,
    d.nnf ASC,
    d.prod_nitem ASC;
