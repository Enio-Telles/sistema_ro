/*
    Analise da Consulta: CPF_empresa_DIMP.sql
    Objetivo: Comparar valores de operacoes com cartao (DIMP) vs valores de saidas fiscais (NF-e/NFC-e)
    para identificar possiveis divergencias ou omissoes de faturamento.
    
    Tabelas Utilizadas:
    - bi.mpg_f_detalhe_operacao: Dados de operacoes com maquinas de cartao (DIMP).
      Colunas: cnpj_cpf, dt_op (data operacao), valor.
    - BI.fato_nfe_nfce_sumarizada: Dados sumarizados de NF-e e NFC-e.
      Colunas: co_emitente, da_referencia, co_tp_nf (1=saida), prod_* (valores).

    Logica Principal:
    1. CTE "cartao": Agrega operacoes de cartao por periodo (ano/mes).
    2. CTE "saidas": Agrega vendas fiscais (NF-e/NFC-e de saida) por periodo.
    3. LEFT JOIN: Cruza os dois conjuntos para comparar valores.
    4. "excesso_valor": Calcula a diferenca (cartao - fiscal) para detectar omissoes.

    Uso Tipico:
    - Fiscalizacao de empresas para verificar se todo faturamento (cartao) foi declarado.
    - Valores de cartao maiores que fiscais indicam possivel omissao de receita.
*/

with 
        cartao as (
        select case
                when ano is null and periodo is null 
                  then 'S TOTAL GERAL'
                when ano is not null and periodo is null 
                  then 'S Total no ano ' || ano
                when ano is not null and periodo is not null 
                  then '----Total no periodo ' || periodo
               end                                                                      info,
               operacoes,
               cartao                                                                   cartao
        from(
        select extract(year from dt_op)                                                 ano,
               extract(year from dt_op)||'/'||lpad(extract(month from dt_op),2,'0')     periodo,
               count(*)                                                                 operacoes,
               sum(valor)                                                               cartao
        from bi.mpg_f_detalhe_operacao
        where cnpj_cpf = :CO_CNPJ_CPF
        group by grouping sets 
                ( ( ),
                    (extract(year from dt_op)), 
                        (extract(year from dt_op), extract(year from dt_op)||'/'||lpad(extract(month from dt_op),2,'0'))
                )
             )
        order by ano desc, periodo desc
        ),

        saidas as (
        select case
                when ano is null and periodo is null 
                  then 'S TOTAL GERAL'
                when ano is not null and periodo is null 
                  then 'S Total no ano ' || ano
                when ano is not null and periodo is not null 
                  then '----Total no periodo ' || periodo
               end                                                                                      info,
               nfe_nfce                                                                                 nfe_nfce
        from(
        select extract(year from da_referencia)                                                 ano,
               extract(year from da_referencia)||'/'||lpad(extract(month from da_referencia),2,'0')     periodo,
               sum(prod_vprod+prod_vfrete+prod_vseg+prod_voutro-prod_vdesc)             nfe_nfce
        from BI.fato_nfe_nfce_sumarizada
        where co_emitente = :CO_CNPJ_CPF
        and co_tp_nf = 1
        group by grouping sets 
                ( ( ),
                    (extract(year from da_referencia)), 
                        (extract(year from da_referencia), extract(year from da_referencia)||'/'||lpad(extract(month from da_referencia),2,'0'))
                )
             )
        order by ano desc, periodo desc
        )
        select nvl(cartao.info,saidas.info)                                                                             info,
               cartao.operacoes                                                                                         operacoes_cartao,
               lpad(trim(to_char(cartao.cartao, '999G999G999G990D00')), length(max(cartao.cartao) over()) + 7)          valor_cartao,
               lpad(trim(to_char(saidas.nfe_nfce , '999G999G999G990D00')), length(max(saidas.nfe_nfce) over()) + 7)     valor_nfe_nfce,
               case when substr(nvl(cartao.info,saidas.info),1,1) = 'S' 
                     then lpad(trim(to_char('-')),
                               length(max(cartao.cartao) over()) + 7)
                    when nvl(cartao.cartao,0) - nvl(saidas.nfe_nfce,0) > 0 
                     then lpad(trim(to_char(nvl(cartao.cartao,0)-nvl(saidas.nfe_nfce,0),'999G999G999G990D00')),
                               length(max(nvl(cartao.cartao,0)) over()) + 7)
                    else lpad(to_char('-'),
                              length(max(cartao.cartao) over()) + 7)
                    end                                                                                                 excesso_valor 
        from cartao
        left join saidas
               on cartao.info = saidas.info
