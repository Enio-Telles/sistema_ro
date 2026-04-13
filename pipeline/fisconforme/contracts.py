from __future__ import annotations

from typing import TypedDict


class FisconformeConsultaResult(TypedDict, total=False):
    cnpj: str
    dados_cadastrais: dict
    malhas: list[dict]
    from_cache_cadastral: bool
    from_cache_malhas: bool
    error: str | None


class FisconformeNotificacaoPayload(TypedDict, total=False):
    cnpj: str
    dsf: str
    dsf_id: str
    auditor: str
    cargo_titulo: str
    matricula: str
    contato: str
    orgao_origem: str
    output_dir: str
