from __future__ import annotations

import polars as pl


def _normalize_st_expr(expr: pl.Expr) -> pl.Expr:
    return (
        pl.when(expr.is_null())
        .then(False)
        .when(expr.cast(pl.Utf8, strict=False).str.to_uppercase().is_in(["S", "SIM", "TRUE", "1"]))
        .then(True)
        .otherwise(pl.lit(False))
    )


def _round_quantities(df: pl.DataFrame, cols: list[str]) -> pl.DataFrame:
    available = [pl.col(c).round(4).alias(c) for c in cols if c in df.columns]
    return df.with_columns(available) if available else df


def _round_money(df: pl.DataFrame, cols: list[str]) -> pl.DataFrame:
    available = [pl.col(c).round(2).alias(c) for c in cols if c in df.columns]
    return df.with_columns(available) if available else df


def _mva_ajustado_expr(has_aliq_inter: bool) -> pl.Expr:
    mva_orig = pl.col("MVA").fill_null(0.0) / 100.0
    aliq_inter = pl.col("aliq_inter").fill_null(0.0) / 100.0 if has_aliq_inter else pl.lit(0.12)
    aliq_interna = pl.col("aliq_interna").fill_null(0.0) / 100.0
    return (
        pl.when((1 - aliq_interna) > 0)
        .then((((1 + mva_orig) * (1 - aliq_inter)) / (1 - aliq_interna)) - 1)
        .otherwise(mva_orig)
    )


def _base_saida_expr(pms_col: str, pme_col: str, qtd_col: str) -> pl.Expr:
    return pl.when(pl.col(pms_col) > 0).then(pl.col(qtd_col) * pl.col(pms_col)).otherwise(pl.col(qtd_col) * pl.col(pme_col))


def _base_estoque_expr(pms_col: str, pme_col: str, qtd_col: str) -> pl.Expr:
    return pl.when(pl.col(pms_col) > 0).then(pl.col(qtd_col) * pl.col(pms_col)).otherwise(pl.col(qtd_col) * pl.col(pme_col))


def _estoque_final_expr(df: pl.DataFrame) -> pl.Expr:
    if "__qtd_decl_final_audit__" in df.columns:
        return pl.col("__qtd_decl_final_audit__").fill_null(0.0)
    return pl.col("qtd").abs().fill_null(0.0)


def _divergencia_declarado_agg_expr(df: pl.DataFrame) -> pl.Expr | None:
    if "divergencia_estoque_declarado" not in df.columns:
        return None
    return pl.col("divergencia_estoque_declarado").fill_null(0.0).sum().alias("divergencia_estoque_declarado")


def _divergencia_calculado_agg_expr(df: pl.DataFrame) -> pl.Expr | None:
    if "divergencia_estoque_calculado" not in df.columns:
        return None
    return pl.col("divergencia_estoque_calculado").fill_null(0.0).sum().alias("divergencia_estoque_calculado")


def _coalesce_optional_expr(df: pl.DataFrame, target: str, vig_target: str) -> pl.Expr:
    available: list[pl.Expr] = []
    if vig_target in df.columns:
        available.append(pl.col(vig_target))
    if target in df.columns:
        available.append(pl.col(target))
    if not available:
        available.append(pl.lit(None))
    return pl.coalesce(available).alias(target)


def _apply_window_vigencia(
    df: pl.DataFrame,
    vigencia_df: pl.DataFrame | None,
    *,
    start_col: str,
    end_col: str,
) -> pl.DataFrame:
    if (
        vigencia_df is None
        or vigencia_df.is_empty()
        or df.is_empty()
        or "co_sefin_agr" not in df.columns
        or start_col not in df.columns
        or end_col not in df.columns
        or "co_sefin" not in vigencia_df.columns
    ):
        return df

    vig = vigencia_df
    if "it_in_status" in vig.columns:
        vig = vig.filter(pl.col("it_in_status").cast(pl.Utf8, strict=False).str.to_uppercase() != "C")
    if vig.is_empty():
        return df

    rename_map = {"co_sefin": "co_sefin_agr"}
    if "it_da_inicio" in vig.columns:
        rename_map["it_da_inicio"] = "__vig_inicio__"
    if "it_da_final" in vig.columns:
        rename_map["it_da_final"] = "__vig_fim__"
    vig = vig.rename(rename_map)

    if "__vig_inicio__" not in vig.columns:
        return df
    if "__vig_fim__" not in vig.columns:
        vig = vig.with_columns(pl.lit(None, dtype=pl.Date).alias("__vig_fim__"))

    if vig.schema.get("__vig_inicio__") == pl.Utf8:
        vig = vig.with_columns(pl.col("__vig_inicio__").str.strptime(pl.Date, strict=False))
    if vig.schema.get("__vig_fim__") == pl.Utf8:
        vig = vig.with_columns(pl.col("__vig_fim__").str.strptime(pl.Date, strict=False))

    selected_cols = [
        "co_sefin_agr",
        "__vig_inicio__",
        "__vig_fim__",
        "it_pc_interna",
        "it_in_st",
        "it_pc_mva",
        "it_in_mva_ajustado",
        "it_pc_reducao",
        "it_in_reducao_credito",
    ]
    available_cols = [col for col in selected_cols if col in vig.columns]
    if len(available_cols) <= 1:
        return df

    vig_fields = [col for col in available_cols if col not in {"co_sefin_agr", "__vig_inicio__", "__vig_fim__"}]
    rename_vig_fields = {col: f"__vig_{col}__" for col in vig_fields}
    vig_join = vig.select(available_cols).rename(rename_vig_fields)

    joined = df.with_row_index("__row_id__").join(vig_join, on="co_sefin_agr", how="left")
    joined = joined.with_columns(
        pl.when(
            pl.col("__vig_inicio__").is_not_null() &
            (pl.col(start_col) <= pl.coalesce([pl.col("__vig_fim__"), pl.col(end_col)])) &
            (pl.col(end_col) >= pl.col("__vig_inicio__"))
        )
        .then(1)
        .otherwise(0)
        .alias("__vig_overlap__")
    )

    resolved = (
        joined.sort(
            ["__row_id__", "__vig_overlap__", "__vig_inicio__"],
            descending=[False, True, True],
            nulls_last=True,
        )
        .group_by("__row_id__")
        .first()
        .drop("__row_id__")
    )

    return resolved.with_columns(
        pl.coalesce([pl.col("__vig_it_pc_interna__"), pl.col("aliq_interna")]).alias("aliq_interna"),
        _coalesce_optional_expr(resolved, "it_in_st", "__vig_it_in_st__"),
        _coalesce_optional_expr(resolved, "it_pc_mva", "__vig_it_pc_mva__"),
        _coalesce_optional_expr(resolved, "it_in_mva_ajustado", "__vig_it_in_mva_ajustado__"),
        _coalesce_optional_expr(resolved, "it_pc_reducao", "__vig_it_pc_reducao__"),
        _coalesce_optional_expr(resolved, "it_in_reducao_credito", "__vig_it_in_reducao_credito__"),
        pl.when(_normalize_st_expr(pl.coalesce([pl.col("__vig_it_in_st__"), pl.col("it_in_st")]))).then(pl.lit("ST")).otherwise(pl.lit("SEM ST")).alias("ST"),
    )


def build_aba_mensal_v4(mov_df: pl.DataFrame, vigencia_df: pl.DataFrame | None = None) -> pl.DataFrame:
    if mov_df.is_empty():
        return pl.DataFrame()

    df = mov_df.with_columns(pl.coalesce([pl.col("dt_e_s"), pl.col("dt_doc")]).alias("data_ref"))
    if df.schema.get("data_ref") == pl.Utf8:
        df = df.with_columns(pl.col("data_ref").str.strptime(pl.Date, strict=False))

    df = df.with_columns(
        pl.col("data_ref").dt.year().alias("ano"),
        pl.col("data_ref").dt.month().alias("mes"),
        _normalize_st_expr(pl.col("it_in_st")).alias("__it_in_st_bool__"),
    )
    has_aliq_inter = "aliq_inter" in df.columns

    result = df.group_by(["id_agrupado", "ano", "mes"]).agg(
        pl.col("descr_padrao").drop_nulls().first().alias("descr_padrao"),
        pl.col("unid").drop_nulls().unique().sort().alias("unids_mes"),
        pl.col("unid_ref").drop_nulls().unique().sort().alias("unids_ref_mes"),
        pl.when(pl.col("tipo_operacao") == "1 - ENTRADA").then(pl.col("vl_item")).otherwise(0.0).sum().alias("valor_entradas"),
        pl.when(pl.col("tipo_operacao") == "1 - ENTRADA").then(pl.col("q_conv")).otherwise(0.0).sum().alias("qtd_entradas"),
        pl.when(pl.col("tipo_operacao") == "2 - SAIDAS").then(pl.col("vl_item").abs()).otherwise(0.0).sum().alias("valor_saidas"),
        pl.when(pl.col("tipo_operacao") == "2 - SAIDAS").then(pl.col("q_conv").abs()).otherwise(0.0).sum().alias("qtd_saidas"),
        pl.col("saldo_estoque_anual").drop_nulls().last().alias("saldo_mes"),
        pl.col("custo_medio_anual").drop_nulls().last().alias("custo_medio_mes"),
        pl.col("entr_desac_anual").sum().alias("entradas_desacob"),
        pl.col("saldo_estoque_periodo").drop_nulls().last().alias("saldo_mes_periodo"),
        pl.col("custo_medio_periodo").drop_nulls().last().alias("custo_medio_mes_periodo"),
        pl.col("entr_desac_periodo").sum().alias("entradas_desacob_periodo"),
        pl.col("co_sefin_agr").drop_nulls().first().alias("co_sefin_agr") if "co_sefin_agr" in df.columns else pl.lit(None).alias("co_sefin_agr"),
        pl.col("it_pc_interna").drop_nulls().last().alias("aliq_interna") if "it_pc_interna" in df.columns else (pl.col("aliq_interna").drop_nulls().last().alias("aliq_interna") if "aliq_interna" in df.columns else pl.lit(17.0).alias("aliq_interna")),
        pl.col("__it_in_st_bool__").any().alias("__tem_st_mes__"),
        pl.col("it_pc_mva").drop_nulls().last().alias("it_pc_mva") if "it_pc_mva" in df.columns else pl.lit(0.0).alias("it_pc_mva"),
        pl.col("it_in_mva_ajustado").drop_nulls().last().alias("it_in_mva_ajustado") if "it_in_mva_ajustado" in df.columns else pl.lit("N").alias("it_in_mva_ajustado"),
        pl.col("it_in_st").drop_nulls().last().alias("it_in_st") if "it_in_st" in df.columns else pl.lit(None).alias("it_in_st"),
        pl.col("aliq_inter").drop_nulls().last().alias("aliq_inter") if has_aliq_inter else pl.lit(None).alias("aliq_inter"),
    ).with_columns(
        pl.date(pl.col("ano"), pl.col("mes"), pl.lit(1)).alias("__data_inicio__"),
        pl.date(pl.col("ano"), pl.col("mes"), pl.lit(1)).dt.month_end().alias("__data_fim__"),
        pl.when(pl.col("qtd_entradas") > 0).then(pl.col("valor_entradas") / pl.col("qtd_entradas")).otherwise(0.0).alias("pme_mes"),
        pl.when(pl.col("qtd_saidas") > 0).then(pl.col("valor_saidas") / pl.col("qtd_saidas")).otherwise(0.0).alias("pms_mes"),
        (pl.col("saldo_mes") * pl.col("custo_medio_mes")).alias("valor_estoque"),
        (pl.col("saldo_mes_periodo") * pl.col("custo_medio_mes_periodo")).alias("valor_estoque_periodo"),
        pl.when(pl.col("__tem_st_mes__")).then(pl.lit("ST")).otherwise(pl.lit("SEM ST")).alias("ST"),
    )
    result = _apply_window_vigencia(result, vigencia_df, start_col="__data_inicio__", end_col="__data_fim__")
    result = result.with_columns(
        pl.col("it_pc_mva").fill_null(0.0).alias("MVA"),
    ).with_columns(
        pl.when(pl.col("it_in_mva_ajustado").cast(pl.Utf8, strict=False).str.to_uppercase() == "S").then(_mva_ajustado_expr(has_aliq_inter)).otherwise(pl.col("MVA").fill_null(0.0) / 100.0).alias("MVA_efetivo"),
    ).with_columns(
        pl.when((pl.col("ST") == "ST") & (pl.col("entradas_desacob") > 0))
        .then(
            pl.when(pl.col("pms_mes") > 0)
            .then(pl.col("pms_mes").round(2) * pl.col("entradas_desacob") * (pl.col("aliq_interna").fill_null(0.0) / 100.0))
            .otherwise(pl.col("pme_mes").round(2) * pl.col("entradas_desacob") * (pl.col("aliq_interna").fill_null(0.0) / 100.0) * pl.coalesce([pl.col("MVA_efetivo"), pl.lit(1.0)]))
        )
        .otherwise(0.0)
        .alias("ICMS_entr_desacob"),
        pl.when((pl.col("ST") == "ST") & (pl.col("entradas_desacob_periodo") > 0))
        .then(
            pl.when(pl.col("pms_mes") > 0)
            .then(pl.col("pms_mes").round(2) * pl.col("entradas_desacob_periodo") * (pl.col("aliq_interna").fill_null(0.0) / 100.0))
            .otherwise(pl.col("pme_mes").round(2) * pl.col("entradas_desacob_periodo") * (pl.col("aliq_interna").fill_null(0.0) / 100.0) * pl.coalesce([pl.col("MVA_efetivo"), pl.lit(1.0)]))
        )
        .otherwise(0.0)
        .alias("ICMS_entr_desacob_periodo"),
        pl.when(_normalize_st_expr(pl.col("it_in_st"))).then(pl.lit("S")).otherwise(pl.lit("N")).alias("it_in_st"),
        pl.when(pl.col("it_in_mva_ajustado").cast(pl.Utf8, strict=False).str.to_uppercase() == "S").then(pl.col("MVA_efetivo")).otherwise(None).alias("MVA_ajustado"),
    ).drop(["__tem_st_mes__", "__data_inicio__", "__data_fim__", "it_pc_mva"]).rename({"id_agrupado": "id_agregado"})

    result = _round_quantities(result, ["qtd_entradas", "qtd_saidas", "saldo_mes", "entradas_desacob", "entradas_desacob_periodo", "saldo_mes_periodo"])
    result = _round_money(result, ["valor_entradas", "valor_saidas", "valor_estoque", "valor_estoque_periodo", "ICMS_entr_desacob", "ICMS_entr_desacob_periodo", "aliq_interna"])
    return result


def build_aba_anual_v4(mov_df: pl.DataFrame, vigencia_df: pl.DataFrame | None = None) -> pl.DataFrame:
    if mov_df.is_empty():
        return pl.DataFrame()

    df = mov_df.with_columns(pl.coalesce([pl.col("dt_e_s"), pl.col("dt_doc")]).alias("data_ref"))
    if df.schema.get("data_ref") == pl.Utf8:
        df = df.with_columns(pl.col("data_ref").str.strptime(pl.Date, strict=False))

    df = df.with_columns(pl.col("data_ref").dt.year().alias("ano"), _normalize_st_expr(pl.col("it_in_st")).alias("__it_in_st_bool__"))

    agg_exprs: list[pl.Expr] = [
        pl.col("descr_padrao").drop_nulls().first().alias("descr_padrao"),
        pl.col("unid_ref").drop_nulls().first().alias("unid_ref"),
        pl.when(pl.col("tipo_operacao") == "0 - ESTOQUE INICIAL").then(pl.col("q_conv")).otherwise(0.0).sum().alias("estoque_inicial"),
        pl.when(pl.col("tipo_operacao") == "1 - ENTRADA").then(pl.col("q_conv")).otherwise(0.0).sum().alias("entradas"),
        pl.when(pl.col("tipo_operacao") == "2 - SAIDAS").then(pl.col("q_conv").abs()).otherwise(0.0).sum().alias("saidas"),
        pl.when(pl.col("tipo_operacao") == "3 - ESTOQUE FINAL").then(_estoque_final_expr(df)).otherwise(0.0).sum().alias("estoque_final"),
        pl.col("entr_desac_anual").sum().alias("entradas_desacob"),
        pl.col("saldo_estoque_anual").drop_nulls().last().alias("saldo_final"),
        pl.when(pl.col("tipo_operacao") == "1 - ENTRADA").then(pl.col("preco_unit")).otherwise(None).mean().alias("pme"),
        pl.when(pl.col("tipo_operacao") == "2 - SAIDAS").then(pl.col("preco_unit")).otherwise(None).mean().alias("pms"),
        pl.col("co_sefin_agr").drop_nulls().first().alias("co_sefin_agr") if "co_sefin_agr" in df.columns else pl.lit(None).alias("co_sefin_agr"),
        pl.col("it_pc_interna").drop_nulls().last().alias("aliq_interna") if "it_pc_interna" in df.columns else (pl.col("aliq_interna").drop_nulls().last().alias("aliq_interna") if "aliq_interna" in df.columns else pl.lit(17.0).alias("aliq_interna")),
        pl.col("__it_in_st_bool__").any().alias("__tem_st_ano__"),
        pl.col("it_in_st").drop_nulls().last().alias("it_in_st") if "it_in_st" in df.columns else pl.lit(None).alias("it_in_st"),
    ]
    divergencia_declarado_expr = _divergencia_declarado_agg_expr(df)
    divergencia_calculado_expr = _divergencia_calculado_agg_expr(df)
    if divergencia_declarado_expr is not None:
        agg_exprs.append(divergencia_declarado_expr)
    if divergencia_calculado_expr is not None:
        agg_exprs.append(divergencia_calculado_expr)

    result = df.group_by(["id_agrupado", "ano"]).agg(agg_exprs).with_columns(
        pl.date(pl.col("ano"), pl.lit(1), pl.lit(1)).alias("__data_inicio__"),
        pl.date(pl.col("ano"), pl.lit(12), pl.lit(31)).alias("__data_fim__"),
        (pl.col("estoque_inicial") + pl.col("entradas") + pl.col("entradas_desacob") - pl.col("estoque_final")).alias("saidas_calculadas"),
        (
            pl.col("divergencia_estoque_declarado").fill_null(0.0)
            if "divergencia_estoque_declarado" in df.columns
            else (pl.col("estoque_final") - pl.col("saldo_final")).clip(lower_bound=0)
        ).alias("saidas_desacob"),
        (
            pl.col("divergencia_estoque_calculado").fill_null(0.0)
            if "divergencia_estoque_calculado" in df.columns
            else (pl.col("saldo_final") - pl.col("estoque_final")).clip(lower_bound=0)
        ).alias("estoque_final_desacob"),
        pl.when(pl.col("__tem_st_ano__")).then(pl.lit("ST")).otherwise(pl.lit("SEM ST")).alias("ST"),
    )
    result = _apply_window_vigencia(result, vigencia_df, start_col="__data_inicio__", end_col="__data_fim__")
    result = result.with_columns(
        _base_saida_expr("pms", "pme", "saidas_desacob").alias("__base_saida__"),
        _base_estoque_expr("pms", "pme", "estoque_final_desacob").alias("__base_estoque__"),
    ).with_columns(
        pl.when(pl.col("ST") == "ST").then(0.0).otherwise(pl.col("__base_saida__") * (pl.col("aliq_interna").fill_null(0.0) / 100.0)).alias("ICMS_saidas_desac"),
        (pl.col("__base_estoque__") * (pl.col("aliq_interna").fill_null(0.0) / 100.0)).alias("ICMS_estoque_desac"),
    ).drop(["__tem_st_ano__", "__data_inicio__", "__data_fim__", "__base_saida__", "__base_estoque__"]).rename({"id_agrupado": "id_agregado"})

    result = _round_quantities(result, ["estoque_inicial", "entradas", "saidas", "estoque_final", "saidas_calculadas", "saldo_final", "entradas_desacob", "saidas_desacob", "estoque_final_desacob", "divergencia_estoque_declarado", "divergencia_estoque_calculado"])
    result = _round_money(result, ["pme", "pms", "aliq_interna", "ICMS_saidas_desac", "ICMS_estoque_desac"])
    return result


def build_aba_periodos_v4(mov_df: pl.DataFrame, vigencia_df: pl.DataFrame | None = None) -> pl.DataFrame:
    if mov_df.is_empty() or "periodo_inventario" not in mov_df.columns:
        return pl.DataFrame()

    df = mov_df.with_columns(
        pl.coalesce([pl.col("dt_e_s"), pl.col("dt_doc")]).alias("data_ref"),
        _normalize_st_expr(pl.col("it_in_st")).alias("__it_in_st_bool__"),
    )
    if df.schema.get("data_ref") == pl.Utf8:
        df = df.with_columns(pl.col("data_ref").str.strptime(pl.Date, strict=False))

    agg_exprs: list[pl.Expr] = [
        pl.col("descr_padrao").drop_nulls().first().alias("descr_padrao"),
        pl.col("unid_ref").drop_nulls().first().alias("unid_ref"),
        pl.col("data_ref").drop_nulls().min().alias("data_inicio"),
        pl.col("data_ref").drop_nulls().max().alias("data_fim"),
        pl.when(pl.col("tipo_operacao") == "0 - ESTOQUE INICIAL").then(pl.col("q_conv")).otherwise(0.0).sum().alias("estoque_inicial"),
        pl.when(pl.col("tipo_operacao") == "1 - ENTRADA").then(pl.col("q_conv")).otherwise(0.0).sum().alias("entradas"),
        pl.when(pl.col("tipo_operacao") == "2 - SAIDAS").then(pl.col("q_conv").abs()).otherwise(0.0).sum().alias("saidas"),
        pl.when(pl.col("tipo_operacao") == "3 - ESTOQUE FINAL").then(_estoque_final_expr(df)).otherwise(0.0).sum().alias("estoque_final"),
        pl.col("entr_desac_periodo").sum().alias("entradas_desacob"),
        pl.col("saldo_estoque_periodo").drop_nulls().last().alias("saldo_final"),
        pl.when(pl.col("tipo_operacao") == "1 - ENTRADA").then(pl.col("preco_unit")).otherwise(None).mean().alias("pme"),
        pl.when(pl.col("tipo_operacao") == "2 - SAIDAS").then(pl.col("preco_unit")).otherwise(None).mean().alias("pms"),
        pl.col("co_sefin_agr").drop_nulls().first().alias("co_sefin_agr") if "co_sefin_agr" in df.columns else pl.lit(None).alias("co_sefin_agr"),
        pl.col("it_pc_interna").drop_nulls().last().alias("aliq_interna") if "it_pc_interna" in df.columns else (pl.col("aliq_interna").drop_nulls().last().alias("aliq_interna") if "aliq_interna" in df.columns else pl.lit(17.0).alias("aliq_interna")),
        pl.col("__it_in_st_bool__").any().alias("__tem_st_per__"),
        pl.col("it_in_st").drop_nulls().last().alias("it_in_st") if "it_in_st" in df.columns else pl.lit(None).alias("it_in_st"),
        pl.col("it_pc_mva").drop_nulls().last().alias("it_pc_mva") if "it_pc_mva" in df.columns else pl.lit(None).alias("it_pc_mva"),
        pl.col("it_in_mva_ajustado").drop_nulls().last().alias("it_in_mva_ajustado") if "it_in_mva_ajustado" in df.columns else pl.lit(None).alias("it_in_mva_ajustado"),
    ]
    divergencia_declarado_expr = _divergencia_declarado_agg_expr(df)
    divergencia_calculado_expr = _divergencia_calculado_agg_expr(df)
    if divergencia_declarado_expr is not None:
        agg_exprs.append(divergencia_declarado_expr)
    if divergencia_calculado_expr is not None:
        agg_exprs.append(divergencia_calculado_expr)

    result = df.group_by(["id_agrupado", "periodo_inventario"]).agg(agg_exprs).with_columns(
        (pl.col("estoque_inicial") + pl.col("entradas") + pl.col("entradas_desacob") - pl.col("estoque_final")).alias("saidas_calculadas"),
        (
            pl.col("divergencia_estoque_declarado").fill_null(0.0)
            if "divergencia_estoque_declarado" in df.columns
            else (pl.col("estoque_final") - pl.col("saldo_final")).clip(lower_bound=0)
        ).alias("saidas_desacob"),
        (
            pl.col("divergencia_estoque_calculado").fill_null(0.0)
            if "divergencia_estoque_calculado" in df.columns
            else (pl.col("saldo_final") - pl.col("estoque_final")).clip(lower_bound=0)
        ).alias("estoque_final_desacob"),
        pl.when(pl.col("data_inicio").is_not_null() & pl.col("data_fim").is_not_null())
        .then(pl.format("{} até {}", pl.col("data_inicio").dt.strftime("%d/%m/%Y"), pl.col("data_fim").dt.strftime("%d/%m/%Y")))
        .otherwise(None)
        .alias("periodo_label"),
        pl.when(pl.col("__tem_st_per__")).then(pl.lit("ST")).otherwise(pl.lit("SEM ST")).alias("ST"),
    )
    result = _apply_window_vigencia(result, vigencia_df, start_col="data_inicio", end_col="data_fim")
    result = result.with_columns(
        _base_saida_expr("pms", "pme", "saidas_desacob").alias("__base_saida__"),
        _base_estoque_expr("pms", "pme", "estoque_final_desacob").alias("__base_estoque__"),
    ).with_columns(
        pl.when(pl.col("ST") == "ST").then(0.0).otherwise(pl.col("__base_saida__") * (pl.col("aliq_interna").fill_null(0.0) / 100.0)).alias("ICMS_saidas_desac"),
        (pl.col("__base_estoque__") * (pl.col("aliq_interna").fill_null(0.0) / 100.0)).alias("ICMS_estoque_desac"),
        pl.col("periodo_inventario").alias("cod_per"),
    ).drop(["__tem_st_per__", "__base_saida__", "__base_estoque__"]).rename({"id_agrupado": "id_agregado"})

    result = _round_quantities(result, ["estoque_inicial", "entradas", "saidas", "estoque_final", "saidas_calculadas", "saldo_final", "entradas_desacob", "saidas_desacob", "estoque_final_desacob", "divergencia_estoque_declarado", "divergencia_estoque_calculado"])
    result = _round_money(result, ["pme", "pms", "aliq_interna", "ICMS_saidas_desac", "ICMS_estoque_desac"])
    return result
