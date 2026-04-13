from __future__ import annotations

from typing import TypedDict


class MovEstoqueRow(TypedDict, total=False):
    id_agrupado: str
    mercadoria_id: str
    apresentacao_id: str
    id_linha_origem: str
    codigo_fonte: str
    fonte: str
    tipo_operacao: str
    dt_doc: str
    dt_e_s: str
    unid: str
    unid_ref: str
    fator: float
    qtd: float
    q_conv: float
    vl_item: float
    preco_unit: float
    saldo_estoque_anual: float
    entr_desac_anual: float
    custo_medio_anual: float
    saldo_estoque_periodo: float
    entr_desac_periodo: float
    custo_medio_periodo: float
