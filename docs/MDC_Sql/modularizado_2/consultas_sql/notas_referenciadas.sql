SELECT DISTINCT
              a.chave_acesso,
              a.co_cfop,
              a.tot_vnf,
              a.tot_vicms,
              g.chave nf_referenciada,
              g.modelo,
              g.valor,
              g.icms

        FROM
                bi.fato_nfe_detalhe a
                LEFT JOIN bi.dm_nfe_referenciada b ON a.chave_acesso = b.chave_acesso
                LEFT JOIN (SELECT
                        e.dfe_referenciado chave,
                        f.ide_co_mod modelo,
                        f.tot_vnf valor,
                        f.tot_vicms icms
                    FROM
                        bi.dm_nfe_referenciada e
                        LEFT JOIN bi.fato_nfce_detalhe f ON e.dfe_referenciado = f.chave_acesso
                    WHERE
                         f.dhemi BETWEEN :inicio AND :fim
                         AND f.INFPROT_CSTAT IN ('100','150')
                UNION
                         SELECT
                        e1.dfe_referenciado chave,
                        f1.ide_co_mod modelo,
                        f1.tot_vnf valor,
                        f1.tot_vicms icms
                    FROM
                        bi.dm_nfe_referenciada e1
                        LEFT JOIN bi.fato_nfe_detalhe f1 ON e1.dfe_referenciado = f1.chave_acesso
                    WHERE
                         f1.dhemi BETWEEN :inicio AND :fim
                         AND f1.INFPROT_CSTAT IN ('100','150')) g ON b.dfe_referenciado = g.chave
        WHERE

                ((a.co_destinatario = :CNPJ) -- and d.co_tp_nf = 1)
			OR		( a.co_emitente = :CNPJ) -- and d.co_tp_nf = 0)
				)
                AND (
                    a.dhemi BETWEEN :inicio and :fim
                    OR a.DHSAIENT BETWEEN :inicio and :fim
                    )
               -- AND a.INFPROT_CSTAT IN ('100','150')
                AND g.chave <> ' '
