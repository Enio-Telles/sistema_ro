from __future__ import annotations

import hashlib
from typing import Any

from pipeline.normalization.keys import normalize_text


def _hash_key(*parts: Any) -> str:
    normalized = "|".join(normalize_text(part) for part in parts)
    return hashlib.sha1(normalized.encode("utf-8")).hexdigest()[:16]


def build_mercadoria_id(gtin: Any, ncm: Any, cest: Any, descr_padrao: Any) -> str:
    return f"MERC_{_hash_key(gtin, ncm, cest, descr_padrao)}"


def build_apresentacao_id(unid_ref: Any, embalagem: Any, conteudo: Any) -> str:
    return f"APR_{_hash_key(unid_ref, embalagem, conteudo)}"


def choose_match_rule(gtin: Any, ncm: Any, cest: Any, descr_padrao: Any) -> str:
    if normalize_text(gtin):
        return "gtin"
    if normalize_text(ncm) and normalize_text(cest):
        return "ncm_cest_descricao"
    if normalize_text(descr_padrao):
        return "descricao_fallback"
    return "descricao_fallback"
