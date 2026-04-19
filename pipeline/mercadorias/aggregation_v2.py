from __future__ import annotations

import hashlib
import re
import unicodedata
from typing import Any

import polars as pl


def normalize_descr_agregacao(value: Any) -> str:
    """Normaliza descrição de produto para agrupamento determinístico.

    Aplica, nesta ordem:
    1. upper
    2. remoção de acentos (NFKD → ASCII)
    3. strip de bordas
    4. colapso de espaços duplos

    O resultado é usado como entrada do SHA1 de ``id_agrupado_auto``.
    Garante que 'ÓLEO', 'Óleo' e 'OLEO' produzam o mesmo agrupamento.
    """
    if value is None:
        return ""
    text = str(value).upper()
    text = unicodedata.normalize("NFKD", text)
    text = text.encode("ascii", errors="ignore").decode("ascii")
    text = text.strip()
    return re.sub(r"\s+", " ", text)


def build_auto_id_agrupado(descricao_normalizada: str) -> str:
    digest = hashlib.sha1(descricao_normalizada.encode("utf-8")).hexdigest()[:12]
    return f"AGR_{digest}"


def build_agrupamento_v2(
    itens_df: pl.DataFrame,
    mapa_manual_df: pl.DataFrame | None = None,
    *,
    versao_agrupamento: str = "1",
) -> dict[str, pl.DataFrame]:
    """Agrupamento de mercadorias com rastreabilidade de proveniência.

    Parâmetros
    ----------
    itens_df:
        Itens enriquecidos com ao menos ``descr_item``, ``codigo_fonte`` e
        ``id_linha_origem``.
    mapa_manual_df:
        Mapa de override manual validado pelo ``manual_map_contract``.
        Quando ``None`` ou vazio, apenas o agrupamento automático é aplicado.
    versao_agrupamento:
        Rótulo de versão passado pelo caller (pipeline orquestrador).  Usada
        para rastrear qual rodada de agrupamento gerou cada ``id_agrupado``.

    Colunas de proveniência produzidas
    -----------------------------------
    ``manual_override_aplicado`` (bool)
        ``True`` quando a linha recebeu ``id_agrupado`` do mapa manual.
    ``origem_agrupamento`` (str)
        ``"manual"`` ou ``"auto"``.
    ``regra_agrupamento`` (str)
        Regra usada: ``"codigo_fonte→id_agrupado_manual"`` ou
        ``"sha1_descricao_normalizada"``.
    ``versao_agrupamento`` (str)
        Versão informada pelo caller.
    """
    if itens_df.is_empty():
        empty = pl.DataFrame()
        return {
            "map_produto_agrupado": empty,
            "produtos_agrupados": empty,
            "produtos_final": empty,
        }

    df = itens_df.with_columns(
        pl.col("descr_item").cast(pl.Utf8, strict=False).fill_null("").map_elements(normalize_descr_agregacao, return_dtype=pl.Utf8).alias("descricao_normalizada"),
        pl.col("descr_item").cast(pl.Utf8, strict=False).fill_null("").alias("descr_item"),
        pl.col("descr_compl").cast(pl.Utf8, strict=False).fill_null("").alias("descr_compl"),
        pl.col("codigo_produto_original").cast(pl.Utf8, strict=False).fill_null("").alias("codigo_produto_original"),
        pl.col("ncm").cast(pl.Utf8, strict=False).fill_null("").alias("ncm"),
        pl.col("cest").cast(pl.Utf8, strict=False).fill_null("").alias("cest"),
        pl.col("gtin_padrao").cast(pl.Utf8, strict=False).fill_null("").alias("gtin_padrao") if "gtin_padrao" in itens_df.columns else pl.lit("").alias("gtin_padrao"),
        pl.col("unid").cast(pl.Utf8, strict=False).fill_null("").alias("unid"),
        pl.col("tipo_item").cast(pl.Utf8, strict=False).fill_null("").alias("tipo_item") if "tipo_item" in itens_df.columns else pl.lit("").alias("tipo_item"),
    )

    df = df.with_columns(
        pl.col("descricao_normalizada").map_elements(build_auto_id_agrupado, return_dtype=pl.Utf8).alias("id_agrupado_auto")
    )

    if mapa_manual_df is not None and not mapa_manual_df.is_empty() and "codigo_fonte" in mapa_manual_df.columns and "id_agrupado_manual" in mapa_manual_df.columns:
        df = df.join(
            mapa_manual_df.select(["codigo_fonte", "id_agrupado_manual"]).unique(subset=["codigo_fonte"]),
            on="codigo_fonte",
            how="left",
        ).with_columns(
            pl.when(pl.col("id_agrupado_manual").is_not_null())
            .then(pl.col("id_agrupado_manual"))
            .otherwise(pl.col("id_agrupado_auto"))
            .alias("id_agrupado"),
            # --- proveniência ---
            (pl.col("id_agrupado_manual").is_not_null()).alias("manual_override_aplicado"),
            pl.when(pl.col("id_agrupado_manual").is_not_null())
            .then(pl.lit("manual"))
            .otherwise(pl.lit("auto"))
            .alias("origem_agrupamento"),
            pl.when(pl.col("id_agrupado_manual").is_not_null())
            .then(pl.lit("codigo_fonte→id_agrupado_manual"))
            .otherwise(pl.lit("sha1_descricao_normalizada"))
            .alias("regra_agrupamento"),
            pl.lit(versao_agrupamento).alias("versao_agrupamento"),
        )
    else:
        df = df.with_columns(
            pl.col("id_agrupado_auto").alias("id_agrupado"),
            # --- proveniência (sem mapa manual) ---
            pl.lit(False).alias("manual_override_aplicado"),
            pl.lit("auto").alias("origem_agrupamento"),
            pl.lit("sha1_descricao_normalizada").alias("regra_agrupamento"),
            pl.lit(versao_agrupamento).alias("versao_agrupamento"),
        )

    df = df.with_columns(pl.col("id_agrupado").alias("id_agrupado_final"))

    map_produto_agrupado = df.select([
        c for c in [
            "id_linha_origem",
            "codigo_fonte",
            "descricao_normalizada",
            "id_agrupado",
            "id_agrupado_final",
            "id_agrupado_auto",
            "id_agrupado_manual",
            "codigo_produto_original",
            "descr_item",
            "descr_compl",
            "tipo_item",
            "ncm",
            "cest",
            "gtin_padrao",
            "unid",
            # proveniência
            "manual_override_aplicado",
            "origem_agrupamento",
            "regra_agrupamento",
            "versao_agrupamento",
        ] if c in df.columns
    ])

    produtos_agrupados = df.group_by("id_agrupado").agg(
        pl.col("descricao_normalizada").drop_nulls().unique().sort().alias("lista_descricoes_normalizadas"),
        pl.col("descr_item").drop_nulls().unique().sort().alias("lista_descricoes"),
        pl.col("descr_compl").drop_nulls().unique().sort().alias("lista_desc_compl"),
        pl.col("codigo_produto_original").drop_nulls().unique().sort().alias("lista_itens_agrupados"),
        pl.col("id_linha_origem").drop_nulls().unique().sort().alias("ids_origem_agrupamento"),
        pl.col("codigo_fonte").drop_nulls().unique().sort().alias("codigos_fonte"),
        pl.col("tipo_item").drop_nulls().unique().sort().alias("lista_tipo_item"),
        pl.col("ncm").drop_nulls().unique().sort().alias("lista_ncm"),
        pl.col("cest").drop_nulls().unique().sort().alias("lista_cest"),
        pl.col("gtin_padrao").drop_nulls().unique().sort().alias("lista_gtin"),
        pl.col("unid").drop_nulls().unique().sort().alias("lista_unidades"),
        # proveniência agregada
        pl.col("manual_override_aplicado").any().alias("tem_override_manual"),
        pl.col("origem_agrupamento").drop_nulls().unique().sort().alias("lista_origens_agrupamento"),
        pl.col("regra_agrupamento").drop_nulls().first().alias("regra_agrupamento"),
        pl.col("versao_agrupamento").drop_nulls().first().alias("versao_agrupamento"),
    ).with_columns(
        pl.col("id_agrupado").alias("id_agrupado_final"),
        # origem_agrupamento: 'manual' se qualquer linha veio do mapa manual,
        # 'misto' se há linhas de ambas as origens, 'auto' caso contrário
        pl.when(pl.col("tem_override_manual") & (pl.col("lista_origens_agrupamento").list.len() > 1))
        .then(pl.lit("misto"))
        .when(pl.col("tem_override_manual"))
        .then(pl.lit("manual"))
        .otherwise(pl.lit("auto"))
        .alias("origem_agrupamento")
    ).drop("lista_origens_agrupamento")

    produtos_final = produtos_agrupados.with_columns(
        pl.col("id_agrupado").alias("id_agrupado_final"),
        pl.col("lista_descricoes").list.first().alias("descr_padrao"),
        pl.col("lista_ncm").list.first().alias("ncm_padrao"),
        pl.col("lista_cest").list.first().alias("cest_padrao"),
        pl.col("lista_gtin").list.first().alias("gtin_padrao"),
        pl.col("lista_unidades").list.first().alias("unid_ref"),
    )

    return {
        "map_produto_agrupado": map_produto_agrupado,
        "produtos_agrupados": produtos_agrupados,
        "produtos_final": produtos_final,
    }
