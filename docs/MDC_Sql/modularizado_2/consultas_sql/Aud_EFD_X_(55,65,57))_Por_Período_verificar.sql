-- nesse mesmo perído apareceu saída não cruzada - verificar
--	Falta de registro de entrada de NF-e na EFD;
--	Cr�dito de ICMS na EFD maior que o destacado na NF-e;
--	Falta de registro de NF-e ou NFC-e de Sa�da na EFD;
--	D�bito de ICMS na EFD menor que o destacado na NF-e;
--	D�bito maior na EFD que justifica classifica��o material
--	D�bito de ICMS nas sa�das em per�odo diferente
--	Cr�dito de ENTRADA de XML n�o localizado
--  Cr�ditos (sendo tomador) e d�bitos de CT-e

--

with 
www as (select 1 ddd,
:CNPJ cnpj,
:DATA_INICIAL data1,
:DATA_FINAL data2                            from dual)

                        ,cte_ajuste as (  select chave_acesso,
                            INFPROT_CSTAT , CO_SERIE , CO_NCT, PREST_VTPREST , ICMS_VICMS , dhemi, EMIT_CO_CNPJ, CO_UFINI, CO_UFFIM,
                            case 
                            when CO_TOMADOR3 = '0' then REM_CNPJ_CPF
                            when CO_TOMADOR3 = '1' then EXP_CO_CNPJ_CPF
                            when CO_TOMADOR3 = '2' then RECEB_CNPJ_CPF 
                            when CO_TOMADOR3 = '3' then DEST_CNPJ_CPF 
                            else CO_TOMADOR4_CNPJ_CPF       end as CNPJ_CPF_TOMADOR from bi.fato_cte_detalhe )    

                         ,docs as (                        
                        select  INFPROT_CSTAT status,'Entrada' as operacao,  
                        chave_acesso, IDE_SERIE serie, nnf, TOT_VNF tot_doc, TOT_VICMS DOC_ICMS, dhemi, CO_UF_EMIT UF_IN, CO_UF_DEST UF_FIM, co_emitente, co_destinatario        
                        from bi.fato_nfe_detalhe join www on www.ddd=1  where dhemi BETWEEN data1 and data2 and (co_destinatario = cnpj AND co_emitente != cnpj AND CO_TP_NF = 1) AND INFPROT_CSTAT IN ('100','150') and seq_nitem = '1'
                        
                        
                        union all select  INFPROT_CSTAT status,'Entrada Propria' as operacao,  
                        chave_acesso, IDE_SERIE serie, nnf, TOT_VNF tot_doc, TOT_VICMS DOC_ICMS, dhemi, CO_UF_EMIT UF_IN, CO_UF_DEST UF_FIM, co_emitente, co_destinatario             
                        from bi.fato_nfe_detalhe join www on www.ddd=1  where dhemi BETWEEN data1 and data2 and ( co_emitente = cnpj AND CO_TP_NF = 0) AND INFPROT_CSTAT IN ('100','150') and seq_nitem = '1'
                        
                        union all select  INFPROT_CSTAT status,'Indicado como remetente' as operacao,  
                        chave_acesso, IDE_SERIE serie, nnf, TOT_VNF tot_doc, TOT_VICMS DOC_ICMS, dhemi, CO_UF_EMIT UF_IN, CO_UF_DEST UF_FIM, co_emitente, co_destinatario             
                        from bi.fato_nfe_detalhe join www on www.ddd=1  where dhemi BETWEEN data1 and data2 and (co_destinatario = cnpj AND co_emitente != cnpj AND CO_TP_NF = 0) AND INFPROT_CSTAT IN ('100','150')  and seq_nitem = '1'                    
                        
                        union all select  INFPROT_CSTAT status,'Saida 55' as operacao,  
                        chave_acesso, IDE_SERIE serie, nnf, TOT_VNF tot_doc, TOT_VICMS DOC_ICMS, dhemi, CO_UF_EMIT UF_IN, CO_UF_DEST UF_FIM, co_emitente, co_destinatario             
                        from bi.fato_nfe_detalhe join www on www.ddd=1  where dhemi BETWEEN data1 and data2 and (co_emitente = cnpj AND CO_TP_NF = 1) AND INFPROT_CSTAT IN ('100','150')   and seq_nitem = '1'
                        
                        union all select  INFPROT_CSTAT status, 'Saida 65' as operacao,  chave_acesso, IDE_SERIE serie, nnf, TOT_VNF tot_doc, TOT_VICMS DOC_ICMS, dhemi, null, null, co_emitente, co_destinatario            
                        from bi.fato_nfce_detalhe join www on www.ddd=1 where dhemi BETWEEN data1 and data2 and co_emitente = www.cnpj and seq_nitem = '1' AND INFPROT_CSTAT IN ('100','150')
                        
                        union all select  INFPROT_CSTAT status, (CASE WHEN (CNPJ_CPF_TOMADOR  = cnpj    and  EMIT_CO_CNPJ != cnpj )  THEN 'Tomador 57' WHEN EMIT_CO_CNPJ = cnpj  
                        THEN  'Saida 57'  ELSE 'outros' END) as operacao,  chave_acesso, CO_SERIE serie, CO_NCT, PREST_VTPREST tot_doc, ICMS_VICMS DOC_ICMS, dhemi , CO_UFINI UF_IN, CO_UFFIM  UF_FIM, EMIT_CO_CNPJ co_emitente, CNPJ_CPF_TOMADOR co_destinatario    
                        from cte_ajuste join www on www.ddd=1   where dhemi BETWEEN data1 and data2 and (CNPJ_CPF_TOMADOR = www.cnpj or EMIT_CO_CNPJ = www.cnpj) AND INFPROT_CSTAT IN ('100','150')) , 
                        
                        efd as (select  r0000.CNPJ, r0000.DT_INI efd_ref, r0000.DATA_ENTREGA, c100.CHV_NFE chave_efd, c100.VL_ICMS EFD_ICMS, c100.REG, c100.IND_OPER, c100.SER, c100.NUM_DOC, c100.COD_SIT, c100.COD_MOD
                        from sped.reg_c100 c100  join sped.reg_0000 r0000 on r0000.id = c100.REG_0000_ID  
                    INNER JOIN BI.DM_EFD_ARQUIVO_VALIDO ARQV ON c100.REG_0000_ID = ARQV.REG_0000_ID
                        join www on www.ddd=1                where         r0000.cnpj = www.cnpj  
                    union select  r0000.CNPJ, r0000.DT_INI efd_ref, r0000.DATA_ENTREGA, d100.CHV_CTE chave_efd, d100.VL_ICMS EFD_ICMS, d100.REG, d100.IND_OPER, d100.SER, d100.NUM_DOC, d100.COD_SIT, d100.COD_MOD
                        from sped.reg_d100 d100  join sped.reg_0000 r0000 on r0000.id = d100.REG_0000_ID  
                    INNER JOIN BI.DM_EFD_ARQUIVO_VALIDO ARQV ON d100.REG_0000_ID = ARQV.REG_0000_ID
                        join www on www.ddd=1                where         r0000.cnpj = www.cnpj  
),

BASE   AS             (
 
                        select  d.status, d.operacao,  d.chave_acesso, d.SERIE, d.nnf, d.tot_doc, d.DOC_ICMS, efd.EFD_ICMS, (d.DOC_ICMS - efd.EFD_ICMS) diferenca, extract (year from efd.efd_ref)||'/'|| substr (efd.efd_ref, 4,2) efd_ref,  d.dhemi
                        ,(CASE WHEN SUBSTR (efd.efd_ref, 4, 5) = SUBSTR (d.dhemi, 4, 5)  THEN 'igual' WHEN efd.efd_ref is null THEN '(Confirmar Omissao na EFD)' ELSE 'diferente' END) AS data_efd_x_doc, SUBSTR (efd.data_entrega, 1, 17) EFD_DATA_ENTREGA, d.UF_IN, d.UF_FIM,
                        d.co_emitente, d.co_destinatario
                        from docs d left join efd on d.chave_acesso = efd.chave_efd join www on www.ddd=1                       
                       
                       
),
omissao_entrada  as (
                        SELECT 
                            chave_acesso FROM BASE 
                        WHERE 
                            operacao = 'Entrada'
                            and  data_efd_x_doc = '(Confirmar Omissao na EFD)' 
),    
ev_manifestacao_dest  as  (                       
                        
                select d.CHAVE_ACESSO, nsu_evento, EVENTO_TPEVENTO, EVENTO_DESCEVENTO, EVENTO_DHEVENTO 
                from omissao_entrada d
                join (select     NSU nsu_evento , CHAVE_ACESSO, EVENTO_DHEVENTO, EVENTO_TPEVENTO, EVENTO_DESCEVENTO from bi.DM_EVENTOS 
                                WHERE EVENTO_TPEVENTO in ('110111', '210220','210240', '210200', '210210')) ev   on ev.CHAVE_ACESSO = d.CHAVE_ACESSO
),

max_ev_nota  as   (
                    select CHAVE_ACESSO, max (nsu_evento) max_nsu_evento
                    from ev_manifestacao_dest
                    group by CHAVE_ACESSO
),
max_ev_nota_descricao  as (
                            select mev.CHAVE_ACESSO,  ev.EVENTO_DESCEVENTO||' ('||ev.EVENTO_DHEVENTO||')' EVENTO
                            from  max_ev_nota  mev
                            join ev_manifestacao_dest ev on mev.CHAVE_ACESSO = ev.CHAVE_ACESSO and mev.MAX_NSU_EVENTO = ev.nsu_evento
)
,

docs_n_cruzados  as     ( 
                        select  extract (year from efd.efd_ref)||'/'|| substr (efd.efd_ref, 4,2) EFD_REF, SUBSTR (DATA_ENTREGA, 1, 17) EFD_DATA_ENTREGA, chave_efd, EFD_ICMS, IND_OPER, COD_MOD, REG,  SER, NUM_DOC , COD_SIT    
from efd
join www on www.ddd=1
where 
    efd_ref between data1 and data1
    and chave_efd not in ( select chave_acesso from docs )

)


select 
    STATUS, OPERACAO, b.CHAVE_ACESSO, SERIE, NNF, TOT_DOC, DOC_ICMS, EFD_ICMS, DIFERENCA, case when DIFERENCA < 0 then 'NEGAT' when DIFERENCA > 0 then 'POSIT' ELSE 'NULA' END  TIPO_DIF,
    EFD_REF, DHEMI, DATA_EFD_X_DOC||nvl2 (EVENTO,' - '||EVENTO, null) DATA_EFD_X_DOC , EFD_DATA_ENTREGA, UF_IN, UF_FIM, CO_EMITENTE, CO_DESTINATARIO 

from BASE b    
left join max_ev_nota_descricao mev on mev.CHAVE_ACESSO = b.CHAVE_ACESSO


union all

select 
    INFPROT_CSTAT status, case when IND_OPER = 0 then '_Entrada_EFD_N_Cruzada' else '_Saída_EFD_N_Cruzada' end  as OPERACAO, nc.chave_efd,  IDE_SERIE , nnf, TOT_VNF , TOT_VICMS , nc.EFD_ICMS,
    (TOT_VICMS - nc.EFD_ICMS) DIFERENCA, case when(TOT_VICMS - nc.EFD_ICMS) < 0 then 'NEGAT' when (TOT_VICMS - nc.EFD_ICMS) > 0 then 'POSIT' ELSE 'NULA' END  TIPO_DIF, EFD_REF, DHEMI,
    CASE WHEN SUBSTR (nc.efd_ref, 4, 5) = SUBSTR (d.dhemi, 4, 5)  THEN 'igual' ELSE 'diferente' END AS DATA_EFD_X_DOC, EFD_DATA_ENTREGA, CO_UF_EMIT UF_IN, CO_UF_DEST UF_FIM, 
    co_emitente, co_destinatario          

from docs_n_cruzados nc
join bi.fato_nfe_detalhe d on d.chave_acesso = nc.chave_efd
where d.seq_nitem = '1'


order by 1 desc, 2, 13