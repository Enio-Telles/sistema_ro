from __future__ import annotations

from pipeline.fisconforme.service import read_fisconforme_result


def get_fisconforme_overview(cnpj: str) -> dict:
    return read_fisconforme_result(cnpj)
