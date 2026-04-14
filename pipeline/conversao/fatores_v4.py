from __future__ import annotations

import polars as pl

from pipeline.conversao.structural_factors import infer_structural_factors


def _choose_reference_units(item_unidades_df: pl.DataFrame) -> pl.DataFrame:
    auto_rank = (
        item_unidades_df
        .sort(["id_agrupado", "qtd_total", "linhas"], descending=[False, True, True])
        .group_by("id_agrupado")
        .first()
        .select(["id_agrupado", pl.col("unid").alias("unid_ref_auto")])
    )

    group = item_unidades_df.group_by("id_agrupado").agg(
        pl.col("unid_ref_diag").filter(pl.col("unid_ref_diag") != "").first().alias("unid_ref_diag_group") if "unid_ref_diag" in item_unidades_df.columns else pl.lit("").alias("unid_ref_diag_group"),
        pl.col("unid_ref").filter(pl.col("unid_ref") != "").first().alias("unid_ref_catalogo") if "unid_ref" in item_unidades_df.columns else pl.lit("").alias("unid_ref_catalogo"),
        pl.col("necessita_conversao_diag").any().alias("necessita_conversao_diag_group") if "necessita_conversao_diag" in item_unidades_df.columns else pl.lit(False).alias("necessita_conversao_diag_group"),
        pl.col("possui_diagnostico_conversao").any().alias("possui_diagnostico_conversao") if "possui_diagnostico_conversao" in item_unidades_df.columns else pl.lit(False).alias("possui_diagnostico_conversao"),
        pl.col("evidencia_diag").filter(pl.col("evidencia_diag") != "").first().alias("evidencia_diag_group") if "evidencia_diag" in item_unidades_df.columns else pl.lit("").alias("evidencia_diag_group"),
    )

    refs = group.join(auto_rank, on="id_agrupado", how="left").with_columns(
        pl.when(pl.col("unid_ref_diag_group") != "").then(pl.col("unid_ref_diag_group"))
        .when(pl.col("unid_ref_catalogo") != "").then(pl.col("unid_ref_catalogo"))
        .otherwise(pl.col("unid_ref_auto"))
        .alias("unid_ref_escolhida"),
        pl.when(pl.col("unid_ref_diag_group") != "").then(pl.lit("diagnostico_conversao"))
        .when(pl.col("unid_ref_catalogo") != "").then(pl.lit("catalogo_produtos"))
        .otherwise(pl.lit("auto_qtd_valor"))
        .alias("fonte_unid_ref"),
    )
    return refs


def calcular_fatores_priorizados_v4(item_unidades_df: pl.DataFrame, itens_df: pl.DataFrame) -> pl.DataFrame:
    if item_unidades_df.is_empty():
        return item_unidades_df

    refs = _choose_reference_units(item_unidades_df)
    base = item_unidades_df.join(refs, on="id_agrupado", how="left")

    ref_prices = (
        base.filter(pl.col("unid") == pl.col("unid_ref_escolhida"))
        .select(["id_agrupado", pl.col("preco_medio").alias("preco_unid_ref")])
        .unique(subset=["id_agrupado"])
    )

    result = base.join(ref_prices, on="id_agrupado", how="left").with_columns(
        pl.col("unid_ref_escolhida").alias("unid_ref"),
        pl.when(pl.col("possui_diagnostico_conversao") & (~pl.col("necessita_conversao_diag_group")))
        .then(pl.lit(1.0))
        .when((pl.col("preco_unid_ref") > 0) & (pl.col("preco_medio") > 0))
        .then(pl.col("preco_medio") / pl.col("preco_unid_ref"))
        .otherwise(1.0)
        .alias("fator"),
        pl.when(pl.col("possui_diagnostico_conversao") & (~pl.col("necessita_conversao_diag_group")))
        .then(pl.lit("diagnostico"))
        .otherwise(pl.lit("preco"))
        .alias("tipo_fator"),
        pl.when(pl.col("possui_diagnostico_conversao") & (~pl.col("necessita_conversao_diag_group")))
        .then(pl.lit(0.98))
        .when(pl.col("fonte_unid_ref") == "diagnostico_conversao")
        .then(pl.lit(0.75))
        .otherwise(pl.lit(0.6))
        .alias("confianca_fator"),
        pl.when(pl.col("possui_diagnostico_conversao") & (~pl.col("necessita_conversao_diag_group")))
        .then(pl.lit("diagnostico_conversao_unidade_base"))
        .when(pl.col("fonte_unid_ref") == "diagnostico_conversao")
        .then(pl.lit("preco_relativo_com_ref_diagnostico"))
        .otherwise(pl.lit("preco_medio_relativo"))
        .alias("fonte_fator"),
        pl.col("necessita_conversao_diag_group").fill_null(False).alias("necessita_conversao_diag_group"),
        pl.col("possui_diagnostico_conversao").fill_null(False).alias("possui_diagnostico_conversao"),
        pl.col("evidencia_diag_group").cast(pl.Utf8, strict=False).fill_null("").alias("evidencia_diag_group"),
    )

    estrutural_df = infer_structural_factors(itens_df)
    if estrutural_df.is_empty():
        return result

    joined = result.join(
        estrutural_df.select([
            c for c in [
                "id_agrupado",
                "unid",
                "fator_estrutural",
                "tipo_fator_estrutural",
                "confianca_estrutural",
                "fonte_estrutural",
            ] if c in estrutural_df.columns
        ]),
        on=[c for c in ["id_agrupado", "unid"] if c in result.columns and c in estrutural_df.columns],
        how="left",
    )

    return joined.with_columns(
        pl.when(pl.col("tipo_fator") == "diagnostico").then(pl.col("fator"))
        .when(pl.col("fator_estrutural").is_not_null()).then(pl.col("fator_estrutural"))
        .otherwise(pl.col("fator"))
        .alias("fator"),
        pl.when(pl.col("tipo_fator") == "diagnostico").then(pl.col("tipo_fator"))
        .when(pl.col("fator_estrutural").is_not_null()).then(pl.lit("estrutural"))
        .otherwise(pl.col("tipo_fator"))
        .alias("tipo_fator"),
        pl.when(pl.col("tipo_fator") == "diagnostico").then(pl.col("confianca_fator"))
        .when(pl.col("fator_estrutural").is_not_null()).then(pl.col("confianca_estrutural"))
        .otherwise(pl.col("confianca_fator"))
        .alias("confianca_fator"),
        pl.when(pl.col("tipo_fator") == "diagnostico").then(pl.col("fonte_fator"))
        .when(pl.col("fator_estrutural").is_not_null()).then(pl.col("fonte_estrutural"))
        .otherwise(pl.col("fonte_fator"))
        .alias("fonte_fator"),
    ).drop([c for c in ["fator_estrutural", "tipo_fator_estrutural", "confianca_estrutural", "fonte_estrutural"] if c in joined.columns])
