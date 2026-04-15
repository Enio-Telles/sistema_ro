/* ==========================================================================================
   CONSULTA ÚNICA - OMISSÃO DE ESCRITURAÇÃO DE NF-e / NFC-e NA EFD ICMS/IPI
   ==========================================================================================
   Objetivo
   -------
   Identificar notas fiscais eletrônicas autorizadas na base BI que NÃO constam no Registro
   C100 da versão válida da EFD do contribuinte, considerando:

   1) CNPJ auditado;
   2) período consultado;
   3) data limite de processamento da EFD (visão "até a data de corte");
   4) competência correta do documento.

   Diferenciais desta abordagem
   ----------------------------
   - Evita duplicidade da nota ao buscar somente 1 linha por documento nas tabelas detalhadas.
   - Usa a última EFD válida por período (retificadora mais recente até a data de corte).
   - Diferencia:
       * ESCRITURADA_NO_PERIODO
       * ESCRITURADA_FORA_DO_PERIODO
       * OMISSA
   - O filtro final retorna apenas OMISSA.

   Observação importante
   ---------------------
   Se você quiser tratar "escriturada fora do período" como erro separado, basta remover o
   filtro final e analisar a coluna STATUS_ESCRITURACAO.
   ========================================================================================== */

WITH
PARAMETROS AS (
    SELECT
        REGEXP_REPLACE(TRIM(:CNPJ), '[^0-9]', '') AS cnpj_filtro,
        TO_DATE(:DATA_INICIAL, 'DD/MM/YYYY') AS dt_ini_filtro,
        TO_DATE(:DATA_FINAL,   'DD/MM/YYYY') AS dt_fim_filtro,
        NVL(TO_DATE(:DATA_LIMITE_PROCESSAMENTO, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_corte
    FROM dual
),

/* ------------------------------------------------------------------------------------------
   1) EFD válida por período
   - Mantém apenas o último arquivo entregue para cada DT_INI do contribuinte até a data de
     corte informada.
   ------------------------------------------------------------------------------------------ */
ARQUIVOS_VALIDOS AS (
    SELECT
        x.reg_0000_id,
        x.cnpj,
        x.dt_ini,
        x.dt_fin
    FROM (
        SELECT
            r.id AS reg_0000_id,
            r.cnpj,
            r.dt_ini,
            r.dt_fin,
            ROW_NUMBER() OVER (
                PARTITION BY r.cnpj, r.dt_ini
                ORDER BY r.data_entrega DESC, r.id DESC
            ) AS rn
        FROM sped.reg_0000 r
        INNER JOIN PARAMETROS p
            ON r.cnpj = p.cnpj_filtro
        WHERE r.data_entrega <= p.dt_corte
          AND r.dt_ini <= p.dt_fim_filtro
          AND r.dt_fin >= p.dt_ini_filtro
    ) x
    WHERE x.rn = 1
),

/* ------------------------------------------------------------------------------------------
   2) Chaves escrituradas na EFD válida
   - Captura o C100 da EFD válida.
   - Mantém dados úteis para auditoria futura (IND_OPER, DT_DOC, DT_E_S, COD_SIT).
   ------------------------------------------------------------------------------------------ */
C100_EFD_VALIDO AS (
    SELECT /*+ MATERIALIZE */ DISTINCT
        a.dt_ini,
        a.dt_fin,
        c.chv_nfe,
        c.ind_oper,
        c.dt_doc,
        c.dt_e_s,
        c.cod_sit
    FROM ARQUIVOS_VALIDOS a
    INNER JOIN sped.reg_c100 c
        ON c.reg_0000_id = a.reg_0000_id
    WHERE c.chv_nfe IS NOT NULL
),

/* ------------------------------------------------------------------------------------------
   3) Documentos da base governamental em granularidade de documento
   - Busca apenas 1 linha por documento nas tabelas detalhadas (SEQ_NITEM = '1').
   - Isso evita multiplicar a nota pela quantidade de itens.
   - A DT_REFERENCIA é a data usada para confrontar a competência da EFD.
   ------------------------------------------------------------------------------------------ */
DOCS_GOVERNO_BASE AS (

    /* 3.1) NF-e em que o contribuinte é emitente */
    SELECT
        d.chave_acesso,
        '55' AS modelo,
        'BI_NFE_EMITENTE' AS origem_documento,
        d.dhemi AS dt_emissao,
        d.dhsaient AS dt_entrada_saida,
        TRUNC(GREATEST(d.dhemi, NVL(d.dhsaient, d.dhemi))) AS dt_referencia,
        d.co_emitente,
        d.co_destinatario,
        d.co_tp_nf,
        CASE
            WHEN d.co_tp_nf = 1 THEN 'SAIDA'
            WHEN d.co_tp_nf = 0 THEN 'ENTRADA'
            ELSE 'NAO_CLASSIFICADO'
        END AS fluxo_cnpj,
        d.nnf,
        d.ide_serie AS serie,
        d.infprot_cstat,
        d.tot_vnf AS valor_nota,
        d.tot_vicms AS valor_icms,
        1 AS prioridade_origem
    FROM bi.fato_nfe_detalhe d
    INNER JOIN PARAMETROS p
        ON d.co_emitente = p.cnpj_filtro
    WHERE d.infprot_cstat IN ('100', '150')
      AND d.seq_nitem = '1'
      AND TRUNC(GREATEST(d.dhemi, NVL(d.dhsaient, d.dhemi)))
          BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro

    UNION ALL

    /* 3.2) NF-e em que o contribuinte é destinatário */
    SELECT
        d.chave_acesso,
        '55' AS modelo,
        'BI_NFE_DESTINATARIO' AS origem_documento,
        d.dhemi AS dt_emissao,
        d.dhsaient AS dt_entrada_saida,
        TRUNC(GREATEST(d.dhemi, NVL(d.dhsaient, d.dhemi))) AS dt_referencia,
        d.co_emitente,
        d.co_destinatario,
        d.co_tp_nf,
        CASE
            WHEN d.co_tp_nf = 1 THEN 'ENTRADA'
            WHEN d.co_tp_nf = 0 THEN 'SAIDA'
            ELSE 'NAO_CLASSIFICADO'
        END AS fluxo_cnpj,
        d.nnf,
        d.ide_serie AS serie,
        d.infprot_cstat,
        d.tot_vnf AS valor_nota,
        d.tot_vicms AS valor_icms,
        2 AS prioridade_origem
    FROM bi.fato_nfe_detalhe d
    INNER JOIN PARAMETROS p
        ON d.co_destinatario = p.cnpj_filtro
    WHERE d.infprot_cstat IN ('100', '150')
      AND d.seq_nitem = '1'
      AND TRUNC(GREATEST(d.dhemi, NVL(d.dhsaient, d.dhemi)))
          BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro

    UNION ALL

    /* 3.3) NFC-e emitida pelo contribuinte */
    SELECT
        d.chave_acesso,
        '65' AS modelo,
        'BI_NFCE_EMITENTE' AS origem_documento,
        d.dhemi AS dt_emissao,
        CAST(NULL AS DATE) AS dt_entrada_saida,
        TRUNC(d.dhemi) AS dt_referencia,
        d.co_emitente,
        d.co_destinatario,
        d.co_tp_nf,
        'SAIDA' AS fluxo_cnpj,
        d.nnf,
        d.ide_serie AS serie,
        d.infprot_cstat,
        d.tot_vnf AS valor_nota,
        d.tot_vicms AS valor_icms,
        3 AS prioridade_origem
    FROM bi.fato_nfce_detalhe d
    INNER JOIN PARAMETROS p
        ON d.co_emitente = p.cnpj_filtro
    WHERE d.infprot_cstat IN ('100', '150')
      AND d.seq_nitem = '1'
      AND TRUNC(d.dhemi) BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro
),

/* ------------------------------------------------------------------------------------------
   4) Deduplicação defensiva
   - Em condições normais cada chave já deve aparecer uma única vez.
   - Esta etapa protege contra cenários anômalos e duplicidades residuais.
   ------------------------------------------------------------------------------------------ */
DOCS_GOVERNO AS (
    SELECT
        z.chave_acesso,
        z.modelo,
        z.origem_documento,
        z.dt_emissao,
        z.dt_entrada_saida,
        z.dt_referencia,
        z.co_emitente,
        z.co_destinatario,
        z.co_tp_nf,
        z.fluxo_cnpj,
        z.nnf,
        z.serie,
        z.infprot_cstat,
        z.valor_nota,
        z.valor_icms
    FROM (
        SELECT
            b.*,
            ROW_NUMBER() OVER (
                PARTITION BY b.chave_acesso
                ORDER BY b.prioridade_origem
            ) AS rn
        FROM DOCS_GOVERNO_BASE b
        WHERE b.chave_acesso IS NOT NULL
    ) z
    WHERE z.rn = 1
),

/* ------------------------------------------------------------------------------------------
   5) Conjuntos auxiliares da EFD
   ------------------------------------------------------------------------------------------ */
CHAVES_EFD_TODAS AS (
    SELECT /*+ MATERIALIZE */ DISTINCT
        e.chv_nfe
    FROM C100_EFD_VALIDO e
),

CHAVES_EFD_NO_PERIODO_CORRETO AS (
    SELECT /*+ MATERIALIZE */ DISTINCT
        d.chave_acesso
    FROM DOCS_GOVERNO d
    INNER JOIN C100_EFD_VALIDO e
        ON e.chv_nfe = d.chave_acesso
       AND d.dt_referencia BETWEEN e.dt_ini AND e.dt_fin
),

/* ------------------------------------------------------------------------------------------
   6) Classificação da escrituração
   - ESCRITURADA_NO_PERIODO  : encontrada no C100 da competência correta
   - ESCRITURADA_FORA_DO_PERIODO : encontrada em outra competência válida
   - OMISSA                  : não encontrada em nenhuma EFD válida até a data de corte
   ------------------------------------------------------------------------------------------ */
NOTAS_CLASSIFICADAS AS (
    SELECT
        d.modelo,
        d.fluxo_cnpj,
        d.origem_documento,
        d.chave_acesso,
        d.dt_referencia,
        d.dt_emissao,
        d.dt_entrada_saida,
        d.serie,
        d.nnf,
        d.co_emitente,
        d.co_destinatario,
        d.co_tp_nf,
        d.infprot_cstat,
        d.valor_nota,
        d.valor_icms,
        CASE
            WHEN ep.chave_acesso IS NOT NULL THEN 'ESCRITURADA_NO_PERIODO'
            WHEN et.chv_nfe     IS NOT NULL THEN 'ESCRITURADA_FORA_DO_PERIODO'
            ELSE 'OMISSA'
        END AS status_escrituracao
    FROM DOCS_GOVERNO d
    LEFT JOIN CHAVES_EFD_NO_PERIODO_CORRETO ep
        ON ep.chave_acesso = d.chave_acesso
    LEFT JOIN CHAVES_EFD_TODAS et
        ON et.chv_nfe = d.chave_acesso
)

/* ------------------------------------------------------------------------------------------
   Resultado final
   - Retorna apenas omissão real.
   - Para análise ampliada, remova o WHERE e observe STATUS_ESCRITURACAO.
   ------------------------------------------------------------------------------------------ */
SELECT
    n.status_escrituracao,
    n.modelo,
    n.fluxo_cnpj,
    n.origem_documento,
    n.chave_acesso,
    n.dt_referencia,
    n.dt_emissao,
    n.dt_entrada_saida,
    n.serie,
    n.nnf,
    n.co_emitente,
    n.co_destinatario,
    n.co_tp_nf,
    n.infprot_cstat,
    n.valor_nota,
    n.valor_icms
FROM NOTAS_CLASSIFICADAS n
WHERE n.status_escrituracao = 'OMISSA'
ORDER BY n.dt_referencia, n.modelo, n.chave_acesso;
