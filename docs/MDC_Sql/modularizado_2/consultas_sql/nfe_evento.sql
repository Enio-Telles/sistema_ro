WITH parametros AS (
    SELECT
        :CNPJ AS cnpj_filtro,
        TO_DATE(:data_inicial, 'DD/MM/YYYY') AS data_inicial,
        TO_DATE(:data_final, 'DD/MM/YYYY') AS data_final
    FROM DUAL
)
SELECT
    nfe.DHEMI,
    nfe.chave_acesso,
    nfe.co_destinatario,
    nfe.co_uf_dest,
    nfe.xnome_dest,
    nfe.co_indpres,
    --nfe.prod_vprod + nfe.prod_vfrete + nfe.prod_vseg + nfe.prod_voutro - nfe.prod_vdesc vlr_prod,
    ev.nsu AS nsu_evento,
    ev.evento_nseqevento AS nseq_evento,
    ev.evento_corgao,
    ev.evento_cnpj,
    ev.evento_cpf,
    ev.evento_dhevento,
    ev.evento_tpevento,
    ev.evento_descevento,
    ev.evento_nprot
FROM
    bi.fato_nfe_detalhe nfe
    LEFT JOIN bi.dm_eventos ev ON nfe.chave_acesso = ev.chave_acesso,
    parametros p
WHERE
    ((nfe.co_destinatario = p.cnpj_filtro) OR (nfe.co_emitente = p.cnpj_filtro))
    --AND nfe.dhemi BETWEEN p.data_inicial AND p.data_final
    AND nfe.INFPROT_CSTAT in (100,150)
ORDER BY
    nfe.chave_acesso, nfe.dhemi, ev.evento_dhevento, ev.nsu