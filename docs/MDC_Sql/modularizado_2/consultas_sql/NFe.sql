/*
 * CONSULTA ESPELHO: bi.fato_nfe_detalhe
 * Comentários baseados no MOC 7.0 Anexo I - Leiaute e Regras de Validação
 * * ATUALIZAÇÃO:
 * 1. Tratamento de datas nulas (desde o início até ao dia de hoje)
 * 2. Otimização do filtro WHERE para melhor utilização de índices na base de dados
 */

WITH parametros AS (
    SELECT
        :CNPJ AS cnpj_filtro,

        -- Se :DATA_INICIAL for nulo, assume 01/01/2006 (início histórico da NF-e)
        COALESCE(TO_DATE(:DATA_INICIAL, 'DD/MM/YYYY'), TO_DATE('01/01/2006', 'DD/MM/YYYY')) AS data_inicial,

        -- Se :DATA_FINAL for nulo, assume o momento atual (SYSDATE).
        -- Nota: Adicionado "+ 1 - 1/86400" (lógica Oracle) para garantir que apanha até às 23:59:59 do dia de hoje.
        -- Se não for Oracle, pode usar CURRENT_TIMESTAMP ou similar.
        COALESCE(TO_DATE(:DATA_FINAL, 'DD/MM/YYYY'), TRUNC(SYSDATE) + 1 - 1/86400) AS data_final

    FROM DUAL
)
SELECT
    CASE
        -- CNPJ consultado é o EMITENTE
        WHEN d.co_emitente = p.cnpj_filtro AND d.co_tp_nf = 1 THEN '1 - SAIDA'
        WHEN d.co_emitente = p.cnpj_filtro AND d.co_tp_nf = 0 THEN '0 - ENTRADA'

        -- CNPJ consultado é o DESTINATÁRIO
        WHEN d.co_destinatario = p.cnpj_filtro AND d.co_tp_nf = 1 THEN '0 - ENTRADA'
        WHEN d.co_destinatario = p.cnpj_filtro AND d.co_tp_nf = 0 THEN '1 - SAIDA'

        ELSE 'INDEFINIDO'
    END AS tipo_operacao,
    d.NSU, -- Numero Sequencial Unico (Controle Interno/Chave Primaria do DW)
    d.CHAVE_ACESSO, -- A03: Chave de Acesso da NF-e (44 digitos)
    d.PROD_NITEM, -- H02: Numero do item do Pedido (1-990)
    d.IDE_CO_CUF, -- B02: Codigo da UF do emitente do Documento Fiscal
    d.IDE_CO_INDPAG, -- B05: Indicador da forma de pagamento (Campo descontinuado na v4.0, mantido por historico)
    d.IDE_CO_MOD, -- B06: Codigo do Modelo do Documento Fiscal (55 ou 65)
    d.IDE_SERIE, -- B07: Serie do Documento Fiscal
    d.NNF, -- B08: Numero do Documento Fiscal
    d.DHEMI, -- B09: Data e hora de emissao do Documento Fiscal
    d.DHSAIENT, -- B10: Data e hora de Saida ou da Entrada da Mercadoria/Produto
    d.CO_TP_NF, -- B11: Tipo de Operacao (0-Entrada / 1-Saida)
    d.CO_IDDEST, -- B11a: Identificador de local de destino da operacao (1-Interna / 2-Interestadual / 3-Exterior)
    d.CO_CMUN_FG, -- B12: Codigo do Municipio de Ocorrencia do Fato Gerador
    d.CO_TPEMIS, -- B22: Tipo de Emissao da NF-e (1-Normal, etc.)
    d.CO_FINNFE, -- B25: Finalidade de emissao da NF-e (1-Normal, 2-Complementar, 3-Ajuste, 4-Devolucao)
    d.CO_INDFINAL, -- B25a: Indica operacao com Consumidor final (0-Normal / 1-Consumidor final)
    d.CO_INDPRES, -- B25b: Indicador de presenca do comprador (1-Presencial, 2-Internet, etc.)
    d.CO_EMITENTE, -- C02: CNPJ do emitente
    d.XNOME_EMIT, -- C03: Razao Social ou Nome do emitente
    d.XFANT_EMIT, -- C04: Nome fantasia do emitente
    d.CO_UF_EMIT, -- C12: Sigla da UF do Emitente
    d.CO_CAD_ICMS_EMIT, -- C17: Inscricao Estadual do Emitente
    d.CO_CAD_ICMS_ST, -- C18: Inscricao Estadual do Substituto Tributario
    d.CO_CRT, -- C21: Codigo de Regime Tributario (1-Simples Nacional, 3-Regime Normal)
    d.XLGR_EMIT, -- C06: Logradouro do endereco do emitente
    d.NRO_EMIT, -- C07: Numero do endereco do emitente
    d.XCPL_EMIT, -- C08: Complemento do endereco do emitente
    d.XBAIRRO_EMIT, -- C09: Bairro do endereco do emitente
    d.CO_CMUN_EMIT, -- C10: Codigo do municipio do emitente
    d.XMUN_EMIT, -- C11: Nome do municipio do emitente
    d.CEP_EMIT, -- C13: CEP do endereco do emitente
    d.CPAIS_EMIT, -- C14: Codigo do Pais do emitente
    d.XPAIS_EMIT, -- C15: Nome do Pais do emitente
    d.FONE_EMIT, -- C16: Telefone do emitente
    d.CNAE_EMIT, -- C20: CNAE fiscal do emitente
    d.CO_DESTINATARIO, -- E02/E03: CNPJ ou CPF do destinatario
    d.XNOME_DEST, -- E04: Razao Social ou nome do destinatario
    d.CO_UF_DEST, -- E12: Sigla da UF do destinatario
    d.CO_INDIEDEST, -- E16a: Indicador da IE do Destinatario (1-Contribuinte, 2-Isento, 9-Nao Contribuinte)
    d.CO_CAD_ICMS_DEST, -- E17: Inscricao Estadual do Destinatario
    d.XLGR_DEST, -- E06: Logradouro do endereco do destinatario
    d.NRO_DEST, -- E07: Numero do endereco do destinatario
    d.XCPL_DEST, -- E08: Complemento do endereco do destinatario
    d.XBAIRRO_DEST, -- E09: Bairro do endereco do destinatario
    d.CO_CMUN_DEST, -- E10: Codigo do municipio do destinatario
    d.XMUN_DEST, -- E11: Nome do municipio do destinatario
    d.CEP_DEST, -- E13: CEP do endereco do destinatario
    d.CPAIS_DEST, -- E14: Codigo do Pais do destinatario
    d.XPAIS_DEST, -- E15: Nome do Pais do destinatario
    d.FONE_DEST, -- E16: Telefone do destinatario
    d.PROD_CPROD, -- I02: Codigo do produto ou servico
    d.PROD_CEAN, -- I03: GTIN (Global Trade Item Number) do produto
    d.PROD_XPROD, -- I04: Descricao do produto ou servico
    d.PROD_NCM, -- I05: Codigo NCM (Nomenclatura Comum do Mercosul)
    d.PROD_CEST, -- I05c: Codigo CEST (Codigo Especificador da Substituicao Tributaria)
    d.PROD_EXTIPI, -- I06: Codigo EX da TIPI (Tabela de Incidencia do IPI)
    d.CO_CFOP, -- I08: Codigo Fiscal de Operacoes e Prestacoes
    d.PROD_UCOM, -- I09: Unidade Comercial
    d.PROD_QCOM, -- I10: Quantidade Comercial
    d.PROD_VUNCOM, -- I10a: Valor Unitario de Comercializacao
    d.PROD_VPROD, -- I11: Valor Total Bruto dos Produtos ou Servicos
    d.PROD_CEANTRIB, -- I12: GTIN (Global Trade Item Number) da unidade tributavel
    d.PROD_UTRIB, -- I13: Unidade Tributavel
    d.PROD_QTRIB, -- I14: Quantidade Tributavel
    d.PROD_VUNTRIB, -- I14a: Valor Unitario de tributacao
    d.PROD_VFRETE, -- I15: Valor Total do Frete do item
    d.PROD_VSEG, -- I16: Valor Total do Seguro do item
    d.PROD_VDESC, -- I17: Valor do Desconto do item
    d.PROD_VOUTRO, -- I17a: Outras despesas acessorias do item
    d.PROD_INDTOT, -- I17b: Indica se valor do Item compoe o valor total da NF-e (1-Sim, 0-Nao)
    d.ICMS_CSOSN, -- N12a: Codigo de Situacao da Operacao - Simples Nacional
    d.ICMS_CST, -- N12: Codigo da Situacao Tributaria do ICMS
    d.ICMS_MODBC, -- N13: Modalidade de determinacao da BC do ICMS
    d.ICMS_MODBCST, -- N18: Modalidade de determinacao da BC do ICMS ST
    d.ICMS_MOTDESICMS, -- N28: Motivo da desoneracao do ICMS
    d.ICMS_ORIG, -- N11: Origem da mercadoria
    d.ICMS_PBCOP, -- N25: Percentual da BC operacao propria
    d.ICMS_PCREDSN, -- N29: Aliquota aplicavel de calculo do credito (Simples Nacional)
    d.ICMS_PDIF, -- N16b: Percentual do diferimento
    d.ICMS_PICMS, -- N16: Aliquota do ICMS
    d.ICMS_PICMSST, -- N22: Aliquota do ICMS ST
    d.ICMS_PMVAST, -- N19: Percentual da Margem de Valor Adicionado do ICMS ST
    d.ICMS_PREDBC, -- N14: Percentual da Reducao de BC do ICMS
    d.ICMS_PREDBCST, -- N20: Percentual da Reducao de BC do ICMS ST
    d.ICMS_UFST, -- N24: UF para qual e devido o ICMS ST
    d.ICMS_VBC, -- N15: Valor da Base de Calculo do ICMS
    d.ICMS_VBCST, -- N21: Valor da Base de Calculo do ICMS ST
    d.ICMS_VBCSTDEST, -- N31: Valor da BC do ICMS ST da UF destino
    d.ICMS_VBCSTRET, -- N26: Valor da BC do ICMS ST retido anteriormente
    d.ICMS_VCREDICMSSN, -- N30: Valor credito do ICMS (Simples Nacional)
    d.ICMS_VICMS, -- N17: Valor do ICMS
    d.ICMS_VICMSDESON, -- N28a: Valor do ICMS desonerado
    d.ICMS_VICMSDIF, -- N16c: Valor do ICMS diferido
    d.ICMS_VICMSOP, -- N16a: Valor do ICMS da Operacao
    d.ICMS_VICMSST, -- N23: Valor do ICMS ST
    d.ICMS_VICMSSTDEST, -- N32: Valor do ICMS ST da UF destino
    d.ICMS_VICMSSTRET, -- N27: Valor do ICMS ST retido anteriormente
    d.IPI_CLENQ, -- O02: Classe de enquadramento do IPI (cigarros/bebidas)
    d.IPI_CNPJPROD, -- O03: CNPJ do produtor da mercadoria
    d.IPI_CSELO, -- O04: Codigo do selo de controle IPI
    d.IPI_QSELO, -- O05: Quantidade de selo de controle
    d.IPI_CENQ, -- O06: Codigo de Enquadramento Legal do IPI
    d.IPI_CST, -- O09: Codigo da situacao tributaria do IPI
    d.IPI_VBC, -- O10: Valor da BC do IPI
    d.IPI_PIPI, -- O13: Aliquota do IPI
    d.IPI_QUNID, -- O11: Quantidade total na unidade padrao para tributacao
    d.IPI_VUNID, -- O12: Valor por Unidade Tributavel
    d.IPI_VIPI, -- O14: Valor do IPI
    d.II_VBC, -- P02: Valor BC do Imposto de Importacao
    d.II_VDESPADU, -- P03: Valor despesas aduaneiras
    d.II_VII, -- P04: Valor Imposto de Importacao
    d.II_VIOF, -- P05: Valor Imposto sobre Operacoes Financeiras
    d.VEIC_PROD_TPOP, -- J02: Tipo da operacao (Venda concessionaria, Faturamento direto, etc.)
    d.VEIC_PROD_CHASSI, -- J03: Chassi do veiculo
    d.VEIC_PROD_CCOR, -- J04: Codigo da Cor (montadora)
    d.VEIC_PROD_XCOR, -- J05: Descricao da Cor
    d.VEIC_PROD_POT, -- J06: Potencia Motor (CV)
    d.VEIC_PROD_CILIN, -- J07: Cilindradas
    d.VEIC_PROD_PESOL, -- J08: Peso Liquido
    d.VEIC_PROD_PESOB, -- J09: Peso Bruto
    d.VEIC_PROD_NSERIE, -- J10: Serial (serie)
    d.VEIC_PROD_TPCOMB, -- J11: Tipo de combustivel
    d.VEIC_PROD_NMOTOR, -- J12: Numero de Motor
    d.VEIC_PROD_CMT, -- J13: Capacidade Maxima de Tracao
    d.VEIC_PROD_DIST, -- J14: Distancia entre eixos
    d.VEIC_PROD_ANOMOD, -- J16: Ano Modelo de Fabricacao
    d.VEIC_PROD_ANOFAB, -- J17: Ano de Fabricacao
    d.VEIC_PROD_TPPINT, -- J18: Tipo de Pintura
    d.VEIC_PROD_TPVEIC, -- J19: Tipo de Veiculo (utilizar tabela RENAVAM)
    d.VEIC_PROD_ESPVEIC, -- J20: Especie de Veiculo (Passageiro, Carga, etc.)
    d.VEIC_PROD_VIN, -- J21: Condicao do VIN (R-Remarcado, N-Normal)
    d.VEIC_PROD_CONDVEIC, -- J22: Condicao do Veiculo (1-Acabado, 2-Inacabado, etc.)
    d.VEIC_PROD_CMOD, -- J23: Codigo Marca Modelo (tabela RENAVAM)
    d.VEIC_PROD_CCORDENATRAN, -- J24: Codigo da Cor (DENATRAN)
    d.VEIC_PROD_LOTA, -- J25: Capacidade maxima de lotacao
    d.VEIC_PROD_TPREST, -- J26: Restricao (0-Nao ha, 1-Alienacao, etc.)
    d.COMB_CPRODANP, -- LA02: Codigo de produto da ANP
    d.COMB_PMIXGN, -- LA03: Percentual de Gas Natural para o produto GLP
    d.COMB_CODIF, -- LA04: Codigo de autorizacao / registro do CODIF
    d.COMB_QTEMP, -- LA05: Quantidade de combustivel faturada a temperatura ambiente
    d.COMB_UFCONS, -- LA06: Sigla da UF de consumo
    d.TOT_VBC, -- W03: Base de Calculo do ICMS (Total da NF)
    d.TOT_VICMS, -- W04: Valor Total do ICMS (Total da NF)
    d.TOT_VICMSDESON, -- W04a: Valor Total do ICMS desonerado (Total da NF)
    d.TOT_VBCST, -- W05: Base de Calculo do ICMS ST (Total da NF)
    d.TOT_VST, -- W06: Valor Total do ICMS ST (Total da NF)
    d.TOT_VPROD, -- W07: Valor Total dos produtos e servicos (Total da NF)
    d.TOT_VFRETE, -- W08: Valor Total do Frete (Total da NF)
    d.TOT_VSEG, -- W09: Valor Total do Seguro (Total da NF)
    d.TOT_VDESC, -- W10: Valor Total do Desconto (Total da NF)
    d.TOT_VII, -- W11: Valor Total do II (Total da NF)
    d.TOT_VIPI, -- W12: Valor Total do IPI (Total da NF)
    d.TOT_VPIS, -- W13: Valor do PIS (Total da NF)
    d.TOT_VCOFINS, -- W14: Valor da COFINS (Total da NF)
    d.TOT_VOUTRO, -- W15: Outras Despesas acessorias (Total da NF)
    d.TOT_VNF, -- W16: Valor Total da NF-e (Total da NF)
    d.TOT_VTOTTRIB, -- W16a: Valor aproximado total de tributos (Total da NF)
    d.INFPROT_CSTAT, -- Codigo de status da resposta de processamento da SEFAZ (Controle Interno)
    d.VERSAO, -- A02: Versao do leiaute da NF-e
    d.PROD_INDESCALA, -- I05d: Indicador de Escala Relevante (S/N)
    d.PROD_CNPJFAB, -- I05e: CNPJ do Fabricante da Mercadoria
    d.PROD_CBENEF, -- I05f: Codigo de Beneficio Fiscal na UF
    d.ICMS_VBCFCP, -- N17a: Valor da Base de Calculo do FCP
    d.ICMS_PFCP, -- N17b: Percentual do Fundo de Combate a Pobreza (FCP)
    d.ICMS_VFCP, -- N17c: Valor do Fundo de Combate a Pobreza (FCP)
    d.ICMS_VBCFCPST, -- N23a: Valor da Base de Calculo do FCP retido por ST
    d.ICMS_PFCPST, -- N23b: Percentual do FCP retido por ST
    d.ICMS_VFCPST, -- N23d: Valor do FCP retido por ST
    d.ICMS_VBCUFDEST, -- NA03: Valor da BC do ICMS na UF de destino
    d.ICMS_VBCFCPUFDEST, -- NA04: Valor da BC FCP na UF de destino
    d.ICMS_PFCPUFDEST, -- NA05: Percentual do FCP na UF de destino
    d.ICMS_PICMSUFDEST, -- NA07: Aliquota interna da UF de destino
    d.ICMS_PICMSINTER, -- NA09: Aliquota interestadual das UF envolvidas
    d.ICMS_PICMSINTERPART, -- NA11: Percentual provisorio de partilha do ICMS Interestadual
    d.ICMS_VFCPUFDEST, -- NA13: Valor do FCP da UF de destino
    d.ICMS_VICMSUFDEST, -- NA15: Valor do ICMS Interestadual para a UF de destino
    d.ICMS_VICMSUFREMET, -- NA17: Valor do ICMS Interestadual para a UF do remetente
    d.ICMS_PST, -- N26a: Aliquota suportada pelo Consumidor Final
    d.ICMS_VBCFCPSTRET, -- N27a: Valor da BC do FCP retido anteriormente
    d.ICMS_PFCPSTRET, -- N27b: Percentual do FCP retido anteriormente por ST
    d.ICMS_VFCPSTRET, -- N27d: Valor do FCP retido anteriormente por ST
    d.ICMS_PREDBCEFET, -- N34: Percentual de reducao da base de calculo efetiva
    d.ICMS_VBCEFET, -- N35: Valor da base de calculo efetiva
    d.ICMS_PICMSEFET, -- N36: Aliquota do ICMS efetiva
    d.ICMS_VICMSEFET, -- N37: Valor do ICMS efetivo
    d.MED_CPRODANVISA, -- K01a: Codigo de Produto da ANVISA (Medicamentos)
    d.MED_VPMC, -- K06: Preco maximo consumidor (Medicamentos)
    d.TOT_VFCPUFDEST, -- W04c: Valor total do ICMS relativo Fundo de Combate a Pobreza (FCP) da UF de destino
    d.TOT_VICMSUFDEST, -- W04e: Valor total do ICMS Interestadual para a UF de destino
    d.TOT_VICMSUFREMET, -- W04g: Valor total do ICMS Interestadual para a UF do remetente
    d.TOT_VFCP, -- W04h: Valor Total do FCP (Fundo de Combate a Pobreza)
    d.TOT_VFCPST, -- W06a: Valor Total do FCP retido por substituicao tributaria
    d.TOT_VFCPSTRET, -- W06b: Valor Total do FCP retido anteriormente por ST
    d.TOT_VIPIDEVOL, -- W12a: Valor Total do IPI devolvido
    d.ICMS_CST_A, -- Controle interno ou campo duplicado de CST
    d.ICMS_CSOSN_A, -- Controle interno ou campo duplicado de CSOSN
    d.DT_GRAVACAO, -- Data de gravacao do registro no DW (Controle Interno)
    d.SEQ_NITEM, -- Sequencial do item (Controle Interno)
    d.COFINS_VCOFINS, -- S11: Valor da COFINS (Item)
    d.COFINS_VBC, -- S07: Valor da Base de Calculo da COFINS
    d.COFINS_PCOFINS, -- S08: Aliquota da COFINS (em percentual)
    d.PIS_VPIS, -- Q09: Valor do PIS (Item)
    d.PIS_VBC, -- Q07: Valor da Base de Calculo do PIS
    d.PIS_PPIS, -- Q08: Aliquota do PIS (em percentual)
    d.DHEMI_HORA, -- Hora da emissao extraida de DHEMI (Controle Interno)
    d.STATUS_CARGA_CAMPO_FCP, -- Status de carga ETL para campos FCP (Controle Interno)
    d.STATUS_CARGA_CAMPO_REM_DEST, -- Status de carga ETL para campos Remetente/Destinatario (Controle Interno)
    d.IN_VERSAO, -- Versao da integracao/carga (Controle Interno)
    d.EMAIL_DEST, -- E19: E-mail do destinatario
    d.CO_INDIEDEST_, -- Copia ou auxiliar de E16a (Indicador da IE do Destinatario)
    d.FONE_DEST_A8 -- Variacao ou auxiliar de E16 (Telefone do destinatario)

FROM
    bi.fato_nfe_detalhe d,
    parametros p
WHERE
    /* * OTIMIZAÇÃO: A utilização de funções matemáticas (GREATEST, COALESCE) no campo de data da tabela de factos
     * invalida o uso de índices ("Index Scan"). Ao separar em duas condições de OR, a base de dados
     * pode usar os índices tanto da Emissão como da Saída.
     */
    (
        (d.dhemi BETWEEN p.data_inicial AND p.data_final)
        OR
        (d.dhsaient BETWEEN p.data_inicial AND p.data_final)
    )
    AND (d.co_destinatario = p.cnpj_filtro OR d.co_emitente = p.cnpj_filtro)
    AND INFPROT_CSTAT in (100,150)
