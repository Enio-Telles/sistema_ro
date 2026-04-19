from __future__ import annotations

from typing import Literal, TypedDict


MatchRule = Literal["gtin", "gtin_tributavel", "marca_descricao_conteudo", "ncm_cest_descricao", "descricao_fallback"]


class MercadoriaCanonica(TypedDict, total=False):
    mercadoria_id: str
    apresentacao_id: str
    id_agrupado: str
    id_agrupado_final: str
    codigo_fonte: str
    id_linha_origem: str
    descr_padrao: str
    lista_descricoes: list[str]
    lista_desc_compl: list[str]
    lista_itens_agrupados: list[str]
    ids_origem_agrupamento: list[str]
    ncm_padrao: str
    cest_padrao: str
    gtin_padrao: str
    origem_agrupamento: str
    regra_agrupamento: str
    versao_agrupamento: str
    tem_override_manual: bool
    match_rule: MatchRule
    match_confidence: float
    match_version: str
