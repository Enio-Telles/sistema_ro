/*
===============================================================================
MUDANÇA DE TRIBUTAÇÃO ST - MÓDULO 24
RANKING DA ÚLTIMA ENTRADA ANTERIOR AO INVENTÁRIO
-------------------------------------------------------------------------------
Objetivo:
- localizar, para cada item inventariado e para cada data de inventário,
  a compra mais recente anterior à fotografia do estoque.

Observação:
- este ranking mede rastreabilidade documental, não imposto juridicamente
  suportado no estoque.
===============================================================================
*/
SELECT
    est.cod_item_normalizado,
    est.dt_inv,
    ent.dt_doc AS data_ultima_compra,
    ent.vl_unit_entrada,
    ent.chave_acesso,
    ent.cfop,
    ent.co_uf_emit,
    ent.co_uf_dest,
    ROW_NUMBER() OVER (
        PARTITION BY est.cod_item_normalizado, est.dt_inv
        ORDER BY ent.dt_doc DESC, ent.nsu DESC
    ) AS rn
FROM estoque_bloco_h est
JOIN entradas_sped ent
  ON est.cod_item_normalizado = ent.cod_item_normalizado
WHERE ent.dt_doc <= est.dt_inv;
