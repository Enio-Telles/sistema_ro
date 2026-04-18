-- Origem: EFD_master.xml
-- Título no relatório: C100
-- Caminho no XML: EFD Master 2.0 > C100
-- Utilidade fiscal: Altíssima
-- Foco: Extrai documentos C100 dos arquivos mais recentes por período para o contribuinte.
-- Uso sugerido: Drill documental essencial para reconciliar apuração, entradas/saídas, omissões, duplicidades e cruzamento com BI/XML.
-- Riscos/Limites: Escolhe a última entrega por período; em trabalhos históricos convém documentar a regra de seleção do arquivo.
-- Tabelas/fontes identificadas: sped.reg_c100, sped.reg_0000
-- Binds declarados: CNPJ, data_inicial, data_final

SELECT
	--c100.ID,
    --c100.REG_0000_ID,
    --c100.REG,
    c100.IND_OPER,
    c100.IND_EMIT,
    CASE
        WHEN c100.IND_EMIT = 0 THEN '0 - Emissão Própria'
        WHEN c100.IND_EMIT = 1 THEN '1 - Terceiros'
    END AS IND_EMIT_DESC,
    c100.COD_PART,
    c100.COD_MOD,
    c100.COD_SIT,
    c100.SER,
    c100.NUM_DOC,
    c100.CHV_NFE,
    TO_DATE(c100.DT_DOC, 'DDMMYYYY') dt_doc,
    TO_DATE(c100.DT_E_S, 'DDMMYYYY') dt_e_s,
    --c100.DT_DOC,
    --c100.DT_E_S,
    c100.VL_DOC,
    c100.IND_PGTO,
    c100.VL_DESC,
    c100.VL_ABAT_NT,
    c100.VL_MERC,
    c100.IND_FRT,
    c100.VL_FRT,
    c100.VL_SEG,
    c100.VL_OUT_DA,
    c100.VL_BC_ICMS,
    c100.VL_ICMS,
    c100.VL_BC_ICMS_ST,
    c100.VL_ICMS_ST,
    c100.VL_IPI,
    c100.VL_PIS,
    c100.VL_COFINS,
    c100.VL_PIS_ST,
    c100.VL_COFINS_ST,
    c100.CREATED_AT,
    c100.UPDATED_AT
FROM sped.reg_c100 c100
    INNER JOIN (
        SELECT reg_0000_a.id
        FROM sped.reg_0000 reg_0000_a
        INNER JOIN (
            SELECT
                reg_0000_b.dt_ini AS Periodo,
                MAX(CAST(reg_0000_b.data_entrega AS DATE)) AS Entrega
            FROM sped.reg_0000 reg_0000_b
            WHERE reg_0000_b.cnpj = :CNPJ
                AND reg_0000_b.dt_ini BETWEEN :data_inicial AND :data_final
            GROUP BY reg_0000_b.dt_ini
            ORDER BY reg_0000_b.dt_ini
        ) datas
        ON reg_0000_a.dt_ini = datas.Periodo
            AND CAST(reg_0000_a.data_entrega AS DATE) = datas.Entrega
        WHERE reg_0000_a.cnpj = :CNPJ
    ) datas_cnpj
    ON c100.reg_0000_id = datas_cnpj.id
