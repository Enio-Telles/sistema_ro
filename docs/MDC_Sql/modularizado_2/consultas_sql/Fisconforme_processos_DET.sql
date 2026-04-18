SELECT
    p.num_processo,
    p.cpf_cnpj_contribuinte,
    p.nome,
    p.ie,
    a.malhas_id,
    a.periodo,
    p.delegacia,
    p.id_sistema,
    p.cod_sistema,
    dp.auditor_id,
    to_char(dp.created_at, 'dd/mm/yyyy')        mes_abertura,
    sysdate,
    ( dp.created_at - sysdate )                  data_distribuicao
FROM
    app_pendencia.pendencias                a,
    processo_det.processos                  p,
    processo_det.distribuicoes_processos    dp,
    processo_det.movimentacoes_processos    mp
WHERE
        a.id = p.id_sistema
    AND ( dp.processo_id = p.id
          AND dp.created_at = (
        SELECT
            MAX(x.created_at)
        FROM
            processo_det.distribuicoes_processos x
        WHERE
            p.id = x.processo_id
    ) )
    AND ( mp.distribuicao_processo_id = dp.id
          AND mp.created_at = (
        SELECT
            MAX(m.created_at)
        FROM
            processo_det.movimentacoes_processos m
        WHERE
            dp.id = m.distribuicao_processo_id
    ) )
    AND p.status_processo_id IN ( 1, 2, 5 )
    AND p.cod_sistema = 2
    AND dp.auditor_id IS NULL
ORDER BY
    dp.created_at
