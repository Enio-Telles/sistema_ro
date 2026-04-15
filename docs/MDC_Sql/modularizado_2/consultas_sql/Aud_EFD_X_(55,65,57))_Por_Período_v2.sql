/* =========================================================================================
   AUDITORIA EFD x DOCUMENTOS ELETRÔNICOS (MODELOS 55, 65 E 57) - POR PERÍODO
   =========================================================================================
   Objetivo:
   - Confrontar documentos eletrônicos autorizados no BI (NF-e, NFC-e e CT-e)
     com os documentos escriturados na EFD;
   - Identificar omissões de escrituração;
   - Identificar divergências de ICMS entre XML/BI e EFD;
   - Identificar escrituração em período diferente da emissão;
   - Enriquecer omissões de entrada com eventos de manifestação do destinatário;
   - Identificar documentos escriturados na EFD sem correspondente localizado no BI/XML.

   Observações:
   - A consulta preserva a intenção fiscal da versão original.
   - Foram corrigidos pontos frágeis de robustez e consistência técnica.
========================================================================================= */

WITH
/* =========================================================================================
   1) PARÂMETROS
   -----------------------------------------------------------------------------------------
   Centraliza os parâmetros e padroniza:
   - CNPJ sem máscara;
   - datas inicial e final como DATE;
   - valores padrão para evitar dependência de conversões implícitas.
========================================================================================= */
parametros AS (
    SELECT
        REGEXP_REPLACE(TRIM(:CNPJ), '[^0-9]', '') AS cnpj,
        NVL(TO_DATE(:DATA_INICIAL, 'DD/MM/YYYY'), DATE '1900-01-01') AS data_inicial,
        NVL(TO_DATE(:DATA_FINAL,   'DD/MM/YYYY'), TRUNC(SYSDATE))    AS data_final
    FROM dual
),

/* =========================================================================================
   2) AJUSTE DO CT-e PARA IDENTIFICAR O TOMADOR EFETIVO
   -----------------------------------------------------------------------------------------
   No CT-e, o tomador pode variar conforme CO_TOMADOR3.
   Este bloco resolve o CNPJ/CPF efetivo do tomador para permitir:
   - identificar CT-e em que o contribuinte é tomador;
   - identificar CT-e em que o contribuinte é o emitente.
========================================================================================= */
cte_ajuste AS (
    SELECT
        c.chave_acesso,
        c.infprot_cstat,
        c.co_serie,
        c.co_nct,
        c.prest_vtprest,
        c.icms_vicms,
        c.dhemi,
        c.emit_co_cnpj,
        c.co_ufini,
        c.co_uffim,
        CASE
            WHEN c.co_tomador3 = '0' THEN c.rem_cnpj_cpf
            WHEN c.co_tomador3 = '1' THEN c.exp_co_cnpj_cpf
            WHEN c.co_tomador3 = '2' THEN c.receb_cnpj_cpf
            WHEN c.co_tomador3 = '3' THEN c.dest_cnpj_cpf
            ELSE c.co_tomador4_cnpj_cpf
        END AS cnpj_cpf_tomador
    FROM bi.fato_cte_detalhe c
),

/* =========================================================================================
   3) DOCUMENTOS DO BI / XML A SEREM AUDITADOS
   -----------------------------------------------------------------------------------------
   Consolida os documentos eletrônicos autorizados no BI, por papel do contribuinte:
   - Entrada de NF-e;
   - Entrada própria;
   - Indicado como remetente;
   - Saída NF-e (55);
   - Saída NFC-e (65);
   - CT-e (57) como tomador ou emitente.
========================================================================================= */
docs AS (

    /* -------------------------------------------------------------------------------------
       3.1) ENTRADAS DE NF-e
       Contribuinte = destinatário
       Emitente diferente do contribuinte
    ------------------------------------------------------------------------------------- */
    SELECT
        d.infprot_cstat AS status,
        'Entrada'       AS operacao,
        d.chave_acesso,
        d.ide_serie     AS serie,
        d.nnf,
        d.tot_vnf       AS tot_doc,
        d.tot_vicms     AS doc_icms,
        d.dhemi,
        d.co_uf_emit    AS uf_in,
        d.co_uf_dest    AS uf_fim,
        d.co_emitente,
        d.co_destinatario
    FROM bi.fato_nfe_detalhe d
    JOIN parametros p ON 1 = 1
    WHERE d.dhemi BETWEEN p.data_inicial AND p.data_final
      AND d.co_destinatario = p.cnpj
      AND d.co_emitente    <> p.cnpj
      AND d.co_tp_nf        = 1
      AND d.infprot_cstat  IN ('100', '150')
      AND d.seq_nitem       = '1'

    UNION ALL

    /* -------------------------------------------------------------------------------------
       3.2) ENTRADA PRÓPRIA
       Mantida conforme a lógica original da auditoria.
    ------------------------------------------------------------------------------------- */
    SELECT
        d.infprot_cstat AS status,
        'Entrada Propria' AS operacao,
        d.chave_acesso,
        d.ide_serie     AS serie,
        d.nnf,
        d.tot_vnf       AS tot_doc,
        d.tot_vicms     AS doc_icms,
        d.dhemi,
        d.co_uf_emit    AS uf_in,
        d.co_uf_dest    AS uf_fim,
        d.co_emitente,
        d.co_destinatario
    FROM bi.fato_nfe_detalhe d
    JOIN parametros p ON 1 = 1
    WHERE d.dhemi BETWEEN p.data_inicial AND p.data_final
      AND d.co_emitente     = p.cnpj
      AND d.co_tp_nf        = 0
      AND d.infprot_cstat  IN ('100', '150')
      AND d.seq_nitem       = '1'

    UNION ALL

    /* -------------------------------------------------------------------------------------
       3.3) INDICADO COMO REMETENTE
       Mantido exatamente conforme a lógica operacional original.
    ------------------------------------------------------------------------------------- */
    SELECT
        d.infprot_cstat AS status,
        'Indicado como remetente' AS operacao,
        d.chave_acesso,
        d.ide_serie     AS serie,
        d.nnf,
        d.tot_vnf       AS tot_doc,
        d.tot_vicms     AS doc_icms,
        d.dhemi,
        d.co_uf_emit    AS uf_in,
        d.co_uf_dest    AS uf_fim,
        d.co_emitente,
        d.co_destinatario
    FROM bi.fato_nfe_detalhe d
    JOIN parametros p ON 1 = 1
    WHERE d.dhemi BETWEEN p.data_inicial AND p.data_final
      AND d.co_destinatario = p.cnpj
      AND d.co_emitente    <> p.cnpj
      AND d.co_tp_nf        = 0
      AND d.infprot_cstat  IN ('100', '150')
      AND d.seq_nitem       = '1'

    UNION ALL

    /* -------------------------------------------------------------------------------------
       3.4) SAÍDAS NF-e (MODELO 55)
       Contribuinte = emitente
    ------------------------------------------------------------------------------------- */
    SELECT
        d.infprot_cstat AS status,
        'Saida 55'      AS operacao,
        d.chave_acesso,
        d.ide_serie     AS serie,
        d.nnf,
        d.tot_vnf       AS tot_doc,
        d.tot_vicms     AS doc_icms,
        d.dhemi,
        d.co_uf_emit    AS uf_in,
        d.co_uf_dest    AS uf_fim,
        d.co_emitente,
        d.co_destinatario
    FROM bi.fato_nfe_detalhe d
    JOIN parametros p ON 1 = 1
    WHERE d.dhemi BETWEEN p.data_inicial AND p.data_final
      AND d.co_emitente     = p.cnpj
      AND d.co_tp_nf        = 1
      AND d.infprot_cstat  IN ('100', '150')
      AND d.seq_nitem       = '1'

    UNION ALL

    /* -------------------------------------------------------------------------------------
       3.5) SAÍDAS NFC-e (MODELO 65)
       Contribuinte = emitente
    ------------------------------------------------------------------------------------- */
    SELECT
        n.infprot_cstat AS status,
        'Saida 65'      AS operacao,
        n.chave_acesso,
        n.ide_serie     AS serie,
        n.nnf,
        n.tot_vnf       AS tot_doc,
        n.tot_vicms     AS doc_icms,
        n.dhemi,
        NULL            AS uf_in,
        NULL            AS uf_fim,
        n.co_emitente,
        n.co_destinatario
    FROM bi.fato_nfce_detalhe n
    JOIN parametros p ON 1 = 1
    WHERE n.dhemi BETWEEN p.data_inicial AND p.data_final
      AND n.co_emitente     = p.cnpj
      AND n.infprot_cstat  IN ('100', '150')
      AND n.seq_nitem       = '1'

    UNION ALL

    /* -------------------------------------------------------------------------------------
       3.6) CT-e (MODELO 57)
       - Tomador 57: contribuinte é tomador e não é emitente;
       - Saida 57  : contribuinte é emitente.
    ------------------------------------------------------------------------------------- */
    SELECT
        c.infprot_cstat AS status,
        CASE
            WHEN c.cnpj_cpf_tomador = p.cnpj AND c.emit_co_cnpj <> p.cnpj THEN 'Tomador 57'
            WHEN c.emit_co_cnpj     = p.cnpj                               THEN 'Saida 57'
            ELSE 'outros'
        END AS operacao,
        c.chave_acesso,
        c.co_serie      AS serie,
        c.co_nct        AS nnf,
        c.prest_vtprest AS tot_doc,
        c.icms_vicms    AS doc_icms,
        c.dhemi,
        c.co_ufini      AS uf_in,
        c.co_uffim      AS uf_fim,
        c.emit_co_cnpj  AS co_emitente,
        c.cnpj_cpf_tomador AS co_destinatario
    FROM cte_ajuste c
    JOIN parametros p ON 1 = 1
    WHERE c.dhemi BETWEEN p.data_inicial AND p.data_final
      AND (c.cnpj_cpf_tomador = p.cnpj OR c.emit_co_cnpj = p.cnpj)
      AND c.infprot_cstat IN ('100', '150')
),

/* =========================================================================================
   4) BASE ESCRITURADA NA EFD
   -----------------------------------------------------------------------------------------
   Consolida os documentos escriturados em:
   - C100 (NF-e / NFC-e);
   - D100 (CT-e).
   Usa apenas arquivos considerados válidos pela dimensão BI.DM_EFD_ARQUIVO_VALIDO.
========================================================================================= */
efd AS (

    /* -------------------------------------------------------------------------------------
       4.1) C100 - documentos fiscais modelos 55 e 65
    ------------------------------------------------------------------------------------- */
    SELECT
        r.cnpj,
        r.dt_ini         AS efd_ref,
        r.data_entrega,
        c.chv_nfe        AS chave_efd,
        c.vl_icms        AS efd_icms,
        c.reg,
        c.ind_oper,
        c.ser,
        c.num_doc,
        c.cod_sit,
        c.cod_mod
    FROM sped.reg_c100 c
    JOIN sped.reg_0000 r
      ON r.id = c.reg_0000_id
    JOIN bi.dm_efd_arquivo_valido a
      ON a.reg_0000_id = c.reg_0000_id
    JOIN parametros p
      ON r.cnpj = p.cnpj
    WHERE c.cod_mod IN ('55', '65')

    UNION ALL

    /* -------------------------------------------------------------------------------------
       4.2) D100 - CT-e modelo 57
    ------------------------------------------------------------------------------------- */
    SELECT
        r.cnpj,
        r.dt_ini         AS efd_ref,
        r.data_entrega,
        d.chv_cte        AS chave_efd,
        d.vl_icms        AS efd_icms,
        d.reg,
        d.ind_oper,
        d.ser,
        d.num_doc,
        d.cod_sit,
        d.cod_mod
    FROM sped.reg_d100 d
    JOIN sped.reg_0000 r
      ON r.id = d.reg_0000_id
    JOIN bi.dm_efd_arquivo_valido a
      ON a.reg_0000_id = d.reg_0000_id
    JOIN parametros p
      ON r.cnpj = p.cnpj
    WHERE d.cod_mod = '57'
),

/* =========================================================================================
   5) CRUZAMENTO PRINCIPAL: DOCUMENTO DO BI/XML x ESCRITURAÇÃO EFD
   -----------------------------------------------------------------------------------------
   Chave principal do confronto: chave de acesso.
   Resultado:
   - se existe na EFD;
   - em qual período foi escriturado;
   - se há diferença de ICMS;
   - se o período da escrituração coincide com o da emissão.
========================================================================================= */
base AS (
    SELECT
        d.status,
        d.operacao,
        d.chave_acesso,
        d.serie,
        d.nnf,
        d.tot_doc,
        d.doc_icms,
        e.efd_icms,
        (d.doc_icms - e.efd_icms) AS diferenca,
        TO_CHAR(e.efd_ref, 'YYYY/MM') AS efd_ref,
        d.dhemi,
        CASE
            WHEN e.efd_ref IS NULL THEN '(Confirmar Omissao na EFD)'
            WHEN TRUNC(e.efd_ref, 'MM') = TRUNC(d.dhemi, 'MM') THEN 'igual'
            ELSE 'diferente'
        END AS data_efd_x_doc,
        TO_CHAR(e.data_entrega, 'DD/MM/YYYY HH24:MI:SS') AS efd_data_entrega,
        d.uf_in,
        d.uf_fim,
        d.co_emitente,
        d.co_destinatario
    FROM docs d
    LEFT JOIN efd e
      ON e.chave_efd = d.chave_acesso
),

/* =========================================================================================
   6) OMISSÕES DE ENTRADA
   -----------------------------------------------------------------------------------------
   Isola as entradas que existem no BI/XML, mas não foram localizadas na EFD.
========================================================================================= */
omissao_entrada AS (
    SELECT
        b.chave_acesso
    FROM base b
    WHERE b.operacao = 'Entrada'
      AND b.data_efd_x_doc = '(Confirmar Omissao na EFD)'
),

/* =========================================================================================
   7) EVENTOS DE MANIFESTAÇÃO DO DESTINATÁRIO
   -----------------------------------------------------------------------------------------
   Enriquecimento das omissões de entrada com eventos da NF-e:
   - ciência da operação;
   - confirmação;
   - desconhecimento;
   - operação não realizada;
   - etc.
========================================================================================= */
ev_manifestacao_dest AS (
    SELECT
        o.chave_acesso,
        ev.nsu_evento,
        ev.evento_tpevento,
        ev.evento_descevento,
        ev.evento_dhevento
    FROM omissao_entrada o
    JOIN (
        SELECT
            e.nsu AS nsu_evento,
            e.chave_acesso,
            e.evento_dhevento,
            e.evento_tpevento,
            e.evento_descevento
        FROM bi.dm_eventos e
        WHERE e.evento_tpevento IN ('110111', '210220', '210240', '210200', '210210')
    ) ev
      ON ev.chave_acesso = o.chave_acesso
),

/* =========================================================================================
   8) ÚLTIMO EVENTO POR NOTA
   -----------------------------------------------------------------------------------------
   Seleciona o evento mais recente da manifestação, usando o maior NSU.
========================================================================================= */
max_ev_nota AS (
    SELECT
        e.chave_acesso,
        MAX(e.nsu_evento) AS max_nsu_evento
    FROM ev_manifestacao_dest e
    GROUP BY e.chave_acesso
),

max_ev_nota_descricao AS (
    SELECT
        m.chave_acesso,
        e.evento_descevento || ' (' || e.evento_dhevento || ')' AS evento
    FROM max_ev_nota m
    JOIN ev_manifestacao_dest e
      ON e.chave_acesso = m.chave_acesso
     AND e.nsu_evento   = m.max_nsu_evento
),

/* =========================================================================================
   9) LOOKUP GERAL DO BI/XML
   -----------------------------------------------------------------------------------------
   Base auxiliar para a segunda parte da auditoria:
   documentos que estão na EFD, mas não foram localizados no conjunto principal "docs".
   Aqui o lookup é simétrico e cobre:
   - NF-e;
   - NFC-e;
   - CT-e.
========================================================================================= */
bi_lookup AS (

    /* -------------------------------------------------------------------------------------
       9.1) NF-e
    ------------------------------------------------------------------------------------- */
    SELECT
        d.chave_acesso,
        d.infprot_cstat AS status,
        d.ide_serie     AS serie,
        d.nnf,
        d.tot_vnf       AS tot_doc,
        d.tot_vicms     AS doc_icms,
        d.dhemi,
        d.co_uf_emit    AS uf_in,
        d.co_uf_dest    AS uf_fim,
        d.co_emitente,
        d.co_destinatario
    FROM bi.fato_nfe_detalhe d
    WHERE d.seq_nitem      = '1'
      AND d.infprot_cstat IN ('100', '150')

    UNION ALL

    /* -------------------------------------------------------------------------------------
       9.2) NFC-e
    ------------------------------------------------------------------------------------- */
    SELECT
        n.chave_acesso,
        n.infprot_cstat AS status,
        n.ide_serie     AS serie,
        n.nnf,
        n.tot_vnf       AS tot_doc,
        n.tot_vicms     AS doc_icms,
        n.dhemi,
        NULL            AS uf_in,
        NULL            AS uf_fim,
        n.co_emitente,
        n.co_destinatario
    FROM bi.fato_nfce_detalhe n
    WHERE n.seq_nitem      = '1'
      AND n.infprot_cstat IN ('100', '150')

    UNION ALL

    /* -------------------------------------------------------------------------------------
       9.3) CT-e
    ------------------------------------------------------------------------------------- */
    SELECT
        c.chave_acesso,
        c.infprot_cstat AS status,
        c.co_serie      AS serie,
        c.co_nct        AS nnf,
        c.prest_vtprest AS tot_doc,
        c.icms_vicms    AS doc_icms,
        c.dhemi,
        c.co_ufini      AS uf_in,
        c.co_uffim      AS uf_fim,
        c.emit_co_cnpj  AS co_emitente,
        c.cnpj_cpf_tomador AS co_destinatario
    FROM cte_ajuste c
    WHERE c.infprot_cstat IN ('100', '150')
),

/* =========================================================================================
   10) DOCUMENTOS ESCRITURADOS NA EFD SEM CORRESPONDENTE NO CONJUNTO "DOCS"
   -----------------------------------------------------------------------------------------
   Este é o cruzamento reverso:
   - parte da EFD;
   - procura a chave no conjunto documental principal do BI/XML;
   - se não encontra, sinaliza como "EFD não cruzada".
========================================================================================= */
docs_n_cruzados AS (
    SELECT
        TO_CHAR(e.efd_ref, 'YYYY/MM') AS efd_ref,
        TO_CHAR(e.data_entrega, 'DD/MM/YYYY HH24:MI:SS') AS efd_data_entrega,
        e.chave_efd,
        e.efd_icms,
        e.ind_oper,
        e.cod_mod,
        e.reg,
        e.ser,
        e.num_doc,
        e.cod_sit,
        e.efd_ref AS efd_ref_data
    FROM efd e
    JOIN parametros p ON 1 = 1
    WHERE e.efd_ref BETWEEN p.data_inicial AND p.data_final
      AND e.chave_efd IS NOT NULL
      AND NOT EXISTS (
          SELECT 1
          FROM docs d
          WHERE d.chave_acesso = e.chave_efd
      )
)

/* =========================================================================================
   11) RESULTADO FINAL
   -----------------------------------------------------------------------------------------
   PARTE A:
   - documentos do BI/XML confrontados com a EFD.
   PARTE B:
   - documentos da EFD sem correspondente no conjunto principal do BI/XML.
========================================================================================= */
SELECT
    b.status,
    b.operacao,
    b.chave_acesso,
    b.serie,
    b.nnf,
    b.tot_doc,
    b.doc_icms,
    b.efd_icms,
    b.diferenca,
    CASE
        WHEN b.diferenca < 0 THEN 'NEGAT'
        WHEN b.diferenca > 0 THEN 'POSIT'
        ELSE 'NULA'
    END AS tipo_dif,
    b.efd_ref,
    b.dhemi,
    b.data_efd_x_doc || NVL2(mev.evento, ' - ' || mev.evento, NULL) AS data_efd_x_doc,
    b.efd_data_entrega,
    b.uf_in,
    b.uf_fim,
    b.co_emitente,
    b.co_destinatario
FROM base b
LEFT JOIN max_ev_nota_descricao mev
  ON mev.chave_acesso = b.chave_acesso

UNION ALL

SELECT
    bl.status,
    CASE
        WHEN nc.ind_oper = 0 THEN '_Entrada_EFD_N_Cruzada'
        ELSE '_Saída_EFD_N_Cruzada'
    END AS operacao,
    nc.chave_efd AS chave_acesso,
    bl.serie,
    bl.nnf,
    bl.tot_doc,
    bl.doc_icms,
    nc.efd_icms,
    (bl.doc_icms - nc.efd_icms) AS diferenca,
    CASE
        WHEN (bl.doc_icms - nc.efd_icms) < 0 THEN 'NEGAT'
        WHEN (bl.doc_icms - nc.efd_icms) > 0 THEN 'POSIT'
        ELSE 'NULA'
    END AS tipo_dif,
    nc.efd_ref,
    bl.dhemi,
    CASE
        WHEN bl.chave_acesso IS NULL THEN '(Documento da EFD sem correspondente no BI/XML)'
        WHEN TRUNC(nc.efd_ref_data, 'MM') = TRUNC(bl.dhemi, 'MM') THEN 'igual'
        ELSE 'diferente'
    END AS data_efd_x_doc,
    nc.efd_data_entrega,
    bl.uf_in,
    bl.uf_fim,
    bl.co_emitente,
    bl.co_destinatario
FROM docs_n_cruzados nc
LEFT JOIN bi_lookup bl
  ON bl.chave_acesso = nc.chave_efd

ORDER BY 1 DESC, 2, 13;