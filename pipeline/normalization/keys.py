from __future__ import annotations

import re
from typing import Any


def only_digits(value: Any) -> str:
    if value is None:
        return ""
    return re.sub(r"\D+", "", str(value))


def normalize_cnpj(value: Any) -> str:
    digits = only_digits(value)
    return digits.zfill(14) if digits else ""


def normalize_cpf(value: Any) -> str:
    digits = only_digits(value)
    return digits.zfill(11) if digits else ""


def normalize_ie(value: Any) -> str:
    return only_digits(value)


def normalize_text(value: Any) -> str:
    if value is None:
        return ""
    return re.sub(r"\s+", " ", str(value)).strip()


def build_codigo_fonte(cnpj_emitente: Any, codigo_produto_original: Any) -> str:
    cnpj = normalize_cnpj(cnpj_emitente)
    codigo = normalize_text(codigo_produto_original)
    return f"{cnpj}|{codigo}" if cnpj or codigo else ""


def build_id_linha_origem(source: str, payload: dict[str, Any]) -> str:
    if source in {"nfe", "nfce"}:
        chave = normalize_text(payload.get("chave_acesso"))
        num_item = normalize_text(payload.get("num_item"))
        return f"{source}|{chave}|{num_item}"
    if source == "c170":
        reg_0000_id = normalize_text(payload.get("reg_0000_id"))
        num_doc = normalize_text(payload.get("num_doc"))
        num_item = normalize_text(payload.get("num_item"))
        return f"c170|{reg_0000_id}|{num_doc}|{num_item}"
    if source == "bloco_h":
        inventario_id = normalize_text(payload.get("inventario_id") or payload.get("bloco_h_id"))
        cod_item = normalize_text(payload.get("cod_item"))
        return f"bloco_h|{inventario_id}|{cod_item}"
    raise ValueError(f"Fonte não suportada para id_linha_origem: {source}")
