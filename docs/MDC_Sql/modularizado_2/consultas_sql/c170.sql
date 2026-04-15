WITH PARAMETROS AS (
    SELECT 
        :CNPJ AS cnpj_filtro,
        TO_DATE(:data_inicial, 'DD/MM/YYYY') AS dt_ini_filtro,
        TO_DATE(:data_final,   'DD/MM/YYYY') AS dt_fim_filtro,
        /* Se data limite nula, usa sysdate */
        NVL(TO_DATE(:data_limite_processamento, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_corte,
        /* Novo parâmetro de filtro de item (opcional) */
        :codigo_item AS cod_item_filtro
    FROM dual
),

ARQUIVOS_RANKING AS (
    SELECT
        r.id as reg_0000_id,
        r.cnpj,
        r.cod_fin,
        r.dt_ini,
        r.dt_fin,
        r.data_entrega,
        p.dt_corte,
        /* Propaga o filtro de item para usar no WHERE principal */
        p.cod_item_filtro,
        /* Lógica de Versionamento */
        ROW_NUMBER() OVER (
            PARTITION BY r.cnpj, r.dt_ini 
            ORDER BY r.data_entrega DESC
        ) AS rn       
    FROM sped.reg_0000 r
    JOIN PARAMETROS p ON r.cnpj = p.cnpj_filtro
    WHERE 
        r.data_entrega <= p.dt_corte 
        AND r.dt_ini BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro
)

SELECT
    TO_CHAR(arq.data_entrega, 'DD/MM/YYYY') AS dt_ultima_entrega,
    arq.cod_fin,
    CASE arq.cod_fin
        WHEN '0' THEN 'Remessa do arquivo original'
        WHEN '1' THEN 'Remessa do arquivo substituto'
        ELSE 'Outros'
    END AS descricao_fin,

    EXTRACT(YEAR FROM arq.dt_ini)            AS Ano_efd,
    TO_CHAR(arq.dt_ini, 'MM/YYYY')           AS periodo_efd,
    
    c100.reg                                 AS c100_reg,
    c100.cod_sit,
    CASE c100.cod_sit
        WHEN '00' THEN 'Documento regular'
        WHEN '01' THEN 'Escrituração extemporânea de documento regular'
        WHEN '02' THEN 'Documento cancelado'
        WHEN '03' THEN 'Escrituração extemporânea de documento cancelado'
        WHEN '04' THEN 'NF-e, NFC-e ou CT-e - denegado'
        WHEN '05' THEN 'NF-e, NFC-e ou CT-e - Numeração inutilizada'
        WHEN '06' THEN 'Documento Fiscal Complementar'
        WHEN '07' THEN 'Escrituração extemporânea de documento complementar'
        WHEN '08' THEN 'Documento Fiscal emitido com base em Regime Especial ou Norma Específica'
        ELSE 'Código desconhecido'
    END AS descricao_cod_sit,
    
    c100.ind_oper,
    CASE
        WHEN c100.ind_oper = 0 THEN 'ENTRADA'
        WHEN c100.ind_oper = 1 THEN 'SAÍDA'
    END AS Oper,
    
    c100.IND_EMIT,
    CASE
        WHEN c100.IND_EMIT = 0 THEN 'Emissão própria'
        WHEN c100.IND_EMIT = 1 THEN 'Terceiros'
    END AS Descricao_IND_EMIT,
    
    c100.chv_nfe,
    c100.num_doc,
    c100.cod_part,
    
    CASE 
        WHEN c100.dt_doc IS NOT NULL AND REGEXP_LIKE(c100.dt_doc, '^\d{8}$')
        THEN TO_DATE(c100.dt_doc, 'DDMMYYYY')
        ELSE NULL
    END AS dt_doc,
    CASE 
        WHEN c100.dt_e_s IS NOT NULL AND REGEXP_LIKE(c100.dt_e_s, '^\d{8}$')
        THEN TO_DATE(c100.dt_e_s, 'DDMMYYYY')
        ELSE NULL
    END AS dt_e_s,

    c170.reg                                 AS c170_reg,
    c170.num_item,
    c170.cod_item,
    
    /* NOVA COLUNA CALCULADA COD */
    replace(replace(replace(LTRIM(c170.cod_item, '0'), ' ',''), '.', ''),'-','') AS COD,

    r0200.cod_barra,
    r0200.descr_item,
    c170.descr_compl,
    r0200.tipo_item,
    CASE
        WHEN r0200.tipo_item = '00' THEN 'Mercadoria para Revenda'
        WHEN r0200.tipo_item = '01' THEN 'Matéria-prima'
        WHEN r0200.tipo_item = '02' THEN 'Embalagem'
        WHEN r0200.tipo_item = '03' THEN 'Produto em Processo'
        WHEN r0200.tipo_item = '04' THEN 'Produto Acabado'
        WHEN r0200.tipo_item = '05' THEN 'Subproduto'
        WHEN r0200.tipo_item = '06' THEN 'Produto Intermediário'
        WHEN r0200.tipo_item = '07' THEN 'Material de Uso e Consumo'
        WHEN r0200.tipo_item = '08' THEN 'Ativo Imobilizado'
        WHEN r0200.tipo_item = '09' THEN 'Serviços'
        WHEN r0200.tipo_item = '10' THEN 'Outros insumos'
        WHEN r0200.tipo_item = '99' THEN 'Outras'
        ELSE 'Tipo Desconhecido'
    END AS Descricao_tipo_item,
    
    r0200.cod_gen,
    CASE
        WHEN r0200.cod_gen = '00' THEN 'Serviço'
        WHEN r0200.cod_gen = '01' THEN 'Animais vivos'
        WHEN r0200.cod_gen = '02' THEN 'Carnes e miudezas, comestíveis'
        WHEN r0200.cod_gen = '03' THEN 'Peixes e crustáceos, moluscos e os outros invertebrados aquáticos'
        WHEN r0200.cod_gen = '04' THEN 'Leite e laticínios, ovos de aves e outros produtos comestíveis de origem animal'
        WHEN r0200.cod_gen = '05' THEN 'Outros produtos de origem animal'
        WHEN r0200.cod_gen = '06' THEN 'Plantas vivas e produtos de floricultura'
        WHEN r0200.cod_gen = '07' THEN 'Produtos hortícolas, raízes e tubérculos comestíveis'
        WHEN r0200.cod_gen = '08' THEN 'Frutas, cascas de cítricos e de melões'
        WHEN r0200.cod_gen = '09' THEN 'Café, chá, mate e especiarias'
        WHEN r0200.cod_gen = '10' THEN 'Cereais'
        WHEN r0200.cod_gen = '11' THEN 'Produtos da indústria de moagem'
        WHEN r0200.cod_gen = '12' THEN 'Sementes e frutos oleaginosos'
        WHEN r0200.cod_gen = '13' THEN 'Gomas, resinas e extratos vegetais'
        WHEN r0200.cod_gen = '14' THEN 'Matérias para entrançar e outros produtos vegetais'
        WHEN r0200.cod_gen = '15' THEN 'Gorduras de origem animal ou vegetal'
        WHEN r0200.cod_gen = '16' THEN 'Preparações de carne e outros produtos de origem animal'
        WHEN r0200.cod_gen = '17' THEN 'Açúcares e produtos de confeitaria'
        WHEN r0200.cod_gen = '18' THEN 'Cacau e suas preparações'
        WHEN r0200.cod_gen = '19' THEN 'Preparações à base de cereais e produtos de pastelaria'
        WHEN r0200.cod_gen = '20' THEN 'Preparações de produtos hortícolas, frutas ou outras partes de plantas'
        WHEN r0200.cod_gen = '21' THEN 'Preparações alimentícias diversas'
        WHEN r0200.cod_gen = '22' THEN 'Bebidas, líquidos alcoólicos e vinagres'
        WHEN r0200.cod_gen = '23' THEN 'Resíduos e desperdícios das indústrias alimentares'
        WHEN r0200.cod_gen = '24' THEN 'Fumo (tabaco) e seus sucedâneos'
        WHEN r0200.cod_gen = '25' THEN 'Sal, enxofre, terras e pedras'
        WHEN r0200.cod_gen = '26' THEN 'Minérios, escórias e cinzas'
        WHEN r0200.cod_gen = '27' THEN 'Combustíveis minerais e óleos minerais'
        WHEN r0200.cod_gen = '28' THEN 'Produtos químicos inorgânicos'
        WHEN r0200.cod_gen = '29' THEN 'Produtos químicos orgânicos'
        WHEN r0200.cod_gen = '30' THEN 'Produtos farmacêuticos'
        WHEN r0200.cod_gen = '31' THEN 'Adubos ou fertilizantes'
        WHEN r0200.cod_gen = '32' THEN 'Extratos tanantes e tintas de escrever'
        WHEN r0200.cod_gen = '33' THEN 'Óleos essenciais e resinoides'
        WHEN r0200.cod_gen = '34' THEN 'Sabões, agentes orgânicos de superfície e produtos semelhantes'
        WHEN r0200.cod_gen = '35' THEN 'Matérias albuminóides e enzimas'
        WHEN r0200.cod_gen = '36' THEN 'Pólvoras e explosivos'
        WHEN r0200.cod_gen = '37' THEN 'Produtos para fotografia e cinematografia'
        WHEN r0200.cod_gen = '38' THEN 'Produtos diversos das indústrias químicas'
        WHEN r0200.cod_gen = '39' THEN 'Plásticos e suas obras'
        WHEN r0200.cod_gen = '40' THEN 'Borracha e suas obras'
        WHEN r0200.cod_gen = '41' THEN 'Peles, exceto a peleteria'
        WHEN r0200.cod_gen = '42' THEN 'Obras de couro'
        WHEN r0200.cod_gen = '43' THEN 'Peleteria'
        WHEN r0200.cod_gen = '44' THEN 'Madeira, carvão vegetal e obras de madeira'
        WHEN r0200.cod_gen = '45' THEN 'Cortiça e suas obras'
        WHEN r0200.cod_gen = '46' THEN 'Obras de espartaria ou cestaria'
        WHEN r0200.cod_gen = '47' THEN 'Pastas de madeira e celulose'
        WHEN r0200.cod_gen = '48' THEN 'Papel e cartão'
        WHEN r0200.cod_gen = '49' THEN 'Livros, jornais e impressos'
        WHEN r0200.cod_gen = '50' THEN 'Seda'
        WHEN r0200.cod_gen = '51' THEN 'Lã e pelos finos'
        WHEN r0200.cod_gen = '52' THEN 'Algodão'
        WHEN r0200.cod_gen = '53' THEN 'Outras fibras têxteis vegetais'
        WHEN r0200.cod_gen = '54' THEN 'Filamentos sintéticos ou artificiais'
        WHEN r0200.cod_gen = '55' THEN 'Fibras sintéticas ou artificiais descontínuas'
        WHEN r0200.cod_gen = '56' THEN 'Pastas ("ouates"), feltros e falsos tecidos'
        WHEN r0200.cod_gen = '57' THEN 'Tapetes e outros revestimentos para pavimentos'
        WHEN r0200.cod_gen = '58' THEN 'Tecidos especiais, tecidos tufados'
        WHEN r0200.cod_gen = '59' THEN 'Tecidos impregnados'
        WHEN r0200.cod_gen = '60' THEN 'Tecidos de malha'
        WHEN r0200.cod_gen = '61' THEN 'Vestuário e acessórios de malha'
        WHEN r0200.cod_gen = '62' THEN 'Vestuário e acessórios, exceto de malha'
        WHEN r0200.cod_gen = '63' THEN 'Outros artefatos têxteis'
        WHEN r0200.cod_gen = '64' THEN 'Calçados e artefatos semelhantes'
        WHEN r0200.cod_gen = '65' THEN 'Chapéus e artefatos de uso semelhante'
        WHEN r0200.cod_gen = '66' THEN 'Guarda-chuvas, bengalas e semelhantes'
        WHEN r0200.cod_gen = '67' THEN 'Penas e penugem preparadas'
        WHEN r0200.cod_gen = '68' THEN 'Produtos cerâmicos'
        WHEN r0200.cod_gen = '69' THEN 'Obras de pedra'
        WHEN r0200.cod_gen = '70' THEN 'Vidro e suas obras'
        WHEN r0200.cod_gen = '71' THEN 'Pérolas naturais ou cultivadas'
        WHEN r0200.cod_gen = '72' THEN 'Ferro fundido, ferro ou aço'
        WHEN r0200.cod_gen = '73' THEN 'Obras de ferro fundido'
        WHEN r0200.cod_gen = '74' THEN 'Cobre e suas obras'
        WHEN r0200.cod_gen = '75' THEN 'Níquel e suas obras'
        WHEN r0200.cod_gen = '76' THEN 'Alumínio e suas obras'
        WHEN r0200.cod_gen = '77' THEN '[Reservado]'
        WHEN r0200.cod_gen = '78' THEN 'Chumbo e suas obras'
        WHEN r0200.cod_gen = '79' THEN 'Zinco e suas obras'
        WHEN r0200.cod_gen = '80' THEN 'Estanho e suas obras'
        WHEN r0200.cod_gen = '81' THEN 'Outros metais comuns'
        WHEN r0200.cod_gen = '82' THEN 'Ferramentas e utensílios'
        WHEN r0200.cod_gen = '83' THEN 'Obras diversas de metais comuns'
        WHEN r0200.cod_gen = '84' THEN 'Máquinas, aparelhos e material elétrico'
        WHEN r0200.cod_gen = '85' THEN 'Veículos automóveis'
        WHEN r0200.cod_gen = '86' THEN 'Aeronaves e aparelhos espaciais'
        WHEN r0200.cod_gen = '87' THEN 'Instrumentos e aparelhos'
        WHEN r0200.cod_gen = '88' THEN 'Embarcações e estruturas flutuantes'
        WHEN r0200.cod_gen = '89' THEN 'Instrumentos musicais'
        WHEN r0200.cod_gen = '90' THEN 'Instrumentos e aparelhos ópticos'
        WHEN r0200.cod_gen = '91' THEN 'Aparelhos de relojoaria'
        WHEN r0200.cod_gen = '92' THEN 'Armas e munições'
        WHEN r0200.cod_gen = '93' THEN 'Brinquedos'
        WHEN r0200.cod_gen = '94' THEN 'Móveis'
        WHEN r0200.cod_gen = '95' THEN 'Obras de arte e coleções'
        WHEN r0200.cod_gen = '96' THEN 'Diversos'
        WHEN r0200.cod_gen = '97' THEN 'Reservado'
        WHEN r0200.cod_gen = '98' THEN 'Operações especiais'
        WHEN r0200.cod_gen = '99' THEN 'Outros Diversos'
        ELSE 'Código Desconhecido'
    END AS descricao_cod_gen,
    
    r0200.cod_ncm,
    r0200.cest,
    REGEXP_SUBSTR(r0200.cest, '^\d{2}') AS segmento_cest,
    cest_segmento.no_segmento,
    
    c170.cfop,
    cfop.DESCRICAO_CFOP,
    c170.cod_nat,
    cod_nat.DESCR_NAT AS descricao_cod_nat,
    c170.cst_icms,
    cst.DESC_CST AS descricao_cst_icms,
    c170.aliq_icms,
    
    c170.ind_mov,
    CASE
        WHEN c170.ind_mov = 0 THEN 'Mov. Física SIM'
        WHEN c170.ind_mov = 1 THEN 'Mov. Física NÃO'
    END AS Descricao_ind_mov,
    
    r0200.unid_inv,
    c170.unid,
    c170.qtd,
    c170.vl_item,
    c170.vl_desc,
    c170.vl_bc_icms,
    c170.vl_icms,
    c170.vl_bc_icms_st,
    c170.aliq_st,
    c170.vl_icms_st,
    c170.cst_ipi,
    c170.cod_enq,
    c170.vl_bc_ipi,
    c170.aliq_ipi,
    c170.vl_ipi,
    c170.cod_cta,
    c170.VL_ABAT_NT

FROM sped.reg_c170 c170
INNER JOIN ARQUIVOS_RANKING arq 
    ON arq.reg_0000_id = c170.reg_0000_id

INNER JOIN sped.reg_c100 c100 
    ON c100.id = c170.reg_c100_id

LEFT JOIN sped.reg_0200 r0200 
    ON r0200.reg_0000_id = c170.reg_0000_id 
    AND r0200.cod_item = c170.cod_item

LEFT JOIN BI.DM_CFOP cfop 
    ON cfop.CO_CFOP = c170.cfop
LEFT JOIN BI.DM_CST cst 
    ON cst.CO_CST = c170.cst_icms
LEFT JOIN SPED.REG_0400 cod_nat 
    ON cod_nat.COD_NAT = c170.cod_nat
    AND arq.reg_0000_id = cod_nat.reg_0000_id
LEFT JOIN BI.DM_CEST_SEGMENTO cest_segmento
    ON REGEXP_SUBSTR(r0200.cest, '^\d{2}') = cest_segmento.cod_segmento    

WHERE arq.rn = 1
  /* FILTRO DINÂMICO DE COD */
  AND (
        arq.cod_item_filtro IS NULL 
        OR replace(replace(replace(LTRIM(c170.cod_item, '0'), ' ',''), '.', ''),'-','') = arq.cod_item_filtro
      )
ORDER BY arq.dt_ini, c100.num_doc, c170.num_item;