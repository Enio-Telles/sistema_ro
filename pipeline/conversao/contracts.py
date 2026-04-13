from __future__ import annotations

from typing import Literal, TypedDict


TipoFator = Literal["estrutural", "preco", "manual", "fallback"]


class FatorConversao(TypedDict, total=False):
    id_agrupado: str
    mercadoria_id: str
    apresentacao_id: str
    unid: str
    unid_ref: str
    fator: float
    tipo_fator: TipoFator
    confianca_fator: float
    fonte_fator: str
    justificativa_fator: str
    fator_manual: float
    unid_ref_manual: str
    versao_regra: str
