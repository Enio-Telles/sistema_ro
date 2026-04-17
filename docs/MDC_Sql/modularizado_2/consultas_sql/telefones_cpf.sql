--/*TAB_BASE FILTRA OS FONES E QUANTIDADE DE OCORRENCIAS DESSES FONES NAS NOTAS FISCAIS DO CPF MONITORADO*/--
WITH tab_base AS
    (SELECT fone_dest_a8, COUNT(*) AS ocorrencias
    FROM
        (SELECT fnf.fone_dest_a8
            FROM bi.fato_nfe_detalhe fnf
            WHERE fnf.co_destinatario = :cpf
                AND fnf.dhemi BETWEEN :data_inicial AND :data_final
                AND fnf.infprot_cstat IN ('100','150')
        UNION ALL
        SELECT regexp_replace(fnfce.fone_dest, '[^[:digit:]]', '') AS fone_dest_a8
        FROM bi.fato_nfce_detalhe fnfce
        WHERE fnfce.co_destinatario = :cpf
            AND fnfce.dhemi BETWEEN :data_inicial AND :data_final
            AND fnfce.infprot_cstat IN ('100','150')
            AND regexp_replace(fnfce.fone_dest, '[^[:digit:]]', '') IS NOT NULL
        )
    WHERE fone_dest_a8 IS NOT NULL
    AND NOT REGEXP_LIKE(fone_dest_a8, '^(\d)\1+$') --/*EXCLUS?O DE FONES COM TODOS OS D?GITOS IGUAIS*/
    GROUP BY fone_dest_a8
    )
--/*NOTAS FISCAIS DE TERCEIROS COM INFORMA??ES DE TELEFONE IGUAIS ?S DO CPF MONITORADO. S?O EXCLU?DAS AS NOTAS FISCAIS DESTINADAS AO PR?PRIO CPF, PARA FACILITAR A AN?LISE*/--
SELECT 'INF_CPF_MONIT:', TB.fone_dest_a8 AS fone_cpf_monit, TB.ocorrencias AS ocorrencias_fone,'INF_NOTAS_TERCEIROS:', fnd.dhemi, fnd.chave_acesso, fnd.nnf, fnd.ide_serie, fnd.co_emitente,
        fnd.xnome_emit, fnd.co_destinatario, fnd.xnome_dest, fnd.co_cad_icms_dest, fnd.xlgr_dest, fnd.nro_dest, fnd.xcpl_dest, fnd.xbairro_dest,
        (SELECT no_municipio FROM bi.dm_localidade WHERE fnd.co_cmun_dest = co_mun_ibge) AS xmun_dest, fnd.prod_xprod, fnd.prod_ucom, fnd.prod_qcom,
        fnd.prod_vprod + fnd.prod_vseg + fnd.prod_vfrete + fnd.prod_voutro - fnd.prod_vdesc AS vtot
FROM tab_base TB
LEFT JOIN bi.fato_nfe_detalhe fnd
    ON TB.fone_dest_a8 = fnd.fone_dest_a8
        AND fnd.dhemi BETWEEN :data_inicial AND :data_final
        AND fnd.infprot_cstat IN ('100','150')
        AND fnd.co_destinatario != :cpf
ORDER BY TB.ocorrencias DESC, nvl(vtot,0) DESC

;
