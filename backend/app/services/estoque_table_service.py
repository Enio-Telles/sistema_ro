from __future__ import annotations

from dataclasses import dataclass
from io import StringIO
from typing import Any

import polars as pl
from fastapi import HTTPException
from starlette.datastructures import QueryParams

from backend.app.services.datasets import dataset_ref
from pipeline.io.parquet_store import load_parquet


DATASETS_ESTOQUE = {
    "mov_estoque",
    "aba_mensal",
    "aba_anual",
    "aba_periodos",
    "estoque_resumo",
    "estoque_alertas",
}

LIMITE_PADRAO = 100
LIMITE_MAXIMO = 500


@dataclass(frozen=True)
class ConsultaTabela:
    offset: int
    limit: int
    sort_by: str | None
    sort_dir: str
    search: str | None
    columns: list[str] | None
    filtros: dict[str, str]


def _normalizar_lista_colunas(columns: str | None) -> list[str] | None:
    if not columns:
        return None
    resultado = [col.strip() for col in columns.split(",") if col.strip()]
    return resultado or None


def _parse_int(value: str | None, default: int, *, min_value: int, max_value: int | None = None) -> int:
    if value in (None, ""):
        return default
    try:
        parsed = int(value)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Parametro numerico invalido.") from exc
    if parsed < min_value:
        raise HTTPException(status_code=400, detail="Parametro numerico fora da faixa permitida.")
    if max_value is not None and parsed > max_value:
        return max_value
    return parsed


def _parse_consulta(query_params: QueryParams) -> ConsultaTabela:
    sort_dir = (query_params.get("sort_dir") or "asc").lower()
    if sort_dir not in {"asc", "desc"}:
        raise HTTPException(status_code=400, detail="sort_dir deve ser asc ou desc.")

    filtros = {
        key.removeprefix("filter__"): value
        for key, value in query_params.multi_items()
        if key.startswith("filter__") and value.strip()
    }

    return ConsultaTabela(
        offset=_parse_int(query_params.get("offset"), 0, min_value=0),
        limit=_parse_int(query_params.get("limit"), LIMITE_PADRAO, min_value=1, max_value=LIMITE_MAXIMO),
        sort_by=query_params.get("sort_by"),
        sort_dir=sort_dir,
        search=(query_params.get("search") or "").strip() or None,
        columns=_normalizar_lista_colunas(query_params.get("columns")),
        filtros=filtros,
    )


def _validar_dataset(dataset: str) -> None:
    if dataset not in DATASETS_ESTOQUE:
        raise HTTPException(status_code=404, detail="Dataset de estoque nao suportado nesta superficie.")


def _validar_colunas(df: pl.DataFrame, columns: list[str] | None) -> None:
    if not columns:
        return
    invalidas = [col for col in columns if col not in df.columns]
    if invalidas:
        raise HTTPException(
            status_code=400,
            detail={"message": "Colunas solicitadas nao existem no dataset.", "invalid_columns": invalidas},
        )


def _coluna_texto(nome_coluna: str) -> pl.Expr:
    return pl.col(nome_coluna).cast(pl.Utf8, strict=False).fill_null("")


def _aplicar_filtros(df: pl.DataFrame, filtros: dict[str, str]) -> tuple[pl.DataFrame, list[dict[str, str]]]:
    aplicados: list[dict[str, str]] = []
    resultado = df
    for coluna, valor in filtros.items():
        if coluna not in resultado.columns:
            raise HTTPException(
                status_code=400,
                detail={"message": "Filtro usa coluna inexistente.", "invalid_column": coluna},
            )
        valor_normalizado = valor.strip().lower()
        resultado = resultado.filter(_coluna_texto(coluna).str.to_lowercase().str.contains(valor_normalizado, literal=True))
        aplicados.append({"column": coluna, "value": valor, "mode": "contains"})
    return resultado, aplicados


def _aplicar_busca(df: pl.DataFrame, search: str | None, columns: list[str]) -> tuple[pl.DataFrame, dict[str, Any] | None]:
    if not search:
        return df, None
    termo = search.lower()
    exprs = [_coluna_texto(coluna).str.to_lowercase().str.contains(termo, literal=True) for coluna in columns]
    if not exprs:
        return df, {"term": search, "columns": []}
    return df.filter(pl.any_horizontal(exprs)), {"term": search, "columns": columns}


def _aplicar_ordenacao(df: pl.DataFrame, sort_by: str | None, sort_dir: str) -> tuple[pl.DataFrame, dict[str, str] | None]:
    if not sort_by:
        return df, None
    if sort_by not in df.columns:
        raise HTTPException(
            status_code=400,
            detail={"message": "sort_by usa coluna inexistente.", "invalid_column": sort_by},
        )
    return (
        df.sort(sort_by, descending=sort_dir == "desc", nulls_last=True),
        {"column": sort_by, "direction": sort_dir},
    )


def _serializar_colunas(df: pl.DataFrame, columns: list[str]) -> list[dict[str, str]]:
    schema = df.schema
    return [{"name": coluna, "dtype": str(schema[coluna])} for coluna in columns]


def _load_dataset(cnpj: str, dataset: str) -> pl.DataFrame | None:
    ref = dataset_ref(cnpj=cnpj, layer="gold", name=dataset)
    return load_parquet(ref)


def consultar_tabela_estoque(cnpj: str, dataset: str, query_params: QueryParams) -> dict[str, Any]:
    _validar_dataset(dataset)
    consulta = _parse_consulta(query_params)
    df = _load_dataset(cnpj, dataset)
    if df is None:
        columns = consulta.columns or []
        return {
            "cnpj": cnpj,
            "dataset": dataset,
            "exists": False,
            "offset": consulta.offset,
            "limit": consulta.limit,
            "rows_total": 0,
            "columns": [{"name": col, "dtype": "unknown"} for col in columns],
            "items": [],
            "sort_applied": {"column": consulta.sort_by, "direction": consulta.sort_dir} if consulta.sort_by else None,
            "filters_applied": [{"column": key, "value": value, "mode": "contains"} for key, value in consulta.filtros.items()],
            "search_applied": {"term": consulta.search, "columns": columns} if consulta.search else None,
        }

    _validar_colunas(df, consulta.columns)
    colunas_busca = consulta.columns or df.columns
    filtrado, filtros_aplicados = _aplicar_filtros(df, consulta.filtros)
    filtrado, busca_aplicada = _aplicar_busca(filtrado, consulta.search, colunas_busca)
    filtrado, ordenacao_aplicada = _aplicar_ordenacao(filtrado, consulta.sort_by, consulta.sort_dir)
    rows_total = filtrado.height
    colunas_saida = consulta.columns or filtrado.columns
    paginado = filtrado.slice(consulta.offset, consulta.limit).select(colunas_saida)

    return {
        "cnpj": cnpj,
        "dataset": dataset,
        "exists": True,
        "offset": consulta.offset,
        "limit": consulta.limit,
        "rows_total": rows_total,
        "columns": _serializar_colunas(filtrado.select(colunas_saida), colunas_saida),
        "items": paginado.to_dicts(),
        "sort_applied": ordenacao_aplicada,
        "filters_applied": filtros_aplicados,
        "search_applied": busca_aplicada,
    }


def exportar_tabela_estoque_csv(cnpj: str, dataset: str, query_params: QueryParams) -> tuple[str, str]:
    _validar_dataset(dataset)
    consulta = _parse_consulta(query_params)
    df = _load_dataset(cnpj, dataset)
    if df is None:
        raise HTTPException(status_code=404, detail="Dataset nao encontrado para exportacao.")

    _validar_colunas(df, consulta.columns)
    colunas_busca = consulta.columns or df.columns
    filtrado, _ = _aplicar_filtros(df, consulta.filtros)
    filtrado, _ = _aplicar_busca(filtrado, consulta.search, colunas_busca)
    filtrado, _ = _aplicar_ordenacao(filtrado, consulta.sort_by, consulta.sort_dir)
    colunas_saida = consulta.columns or filtrado.columns
    export_df = filtrado.select(colunas_saida)
    stream = StringIO()
    export_df.write_csv(stream)
    return stream.getvalue(), f"{dataset}_{cnpj}.csv"
