from __future__ import annotations

import polars as pl

from pipeline.estoque.st_history import resolve_st_anual, resolve_st_mensal


def _normalize_st_expr(expr: pl.Expr) -> pl.Expr:
    return (
        pl.when(expr.is_null())
        .then(False)
        .when(expr.cast(pl.Utf8, strict=False).str.to_uppercase().is_in(["S", "SIM", "TRUE", "1"]))
        .then(True)
        .otherwise(pl.lit(False))
    )


def _normalize_yes_no_expr(expr: pl.Expr) -> pl.Expr:
    return (
        pl.when(expr.is_null())
        .then(False)
        .when(expr.cast(pl.Utf8, strict=False).str.to_uppercase() == "S")
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
    # Fallback com markup 1.30 quando não há PMS (doc tabela_anual, seção ICMS anual)
    return (
        pl.when(pl.col(pms_col) > 0)
        .then(pl.col(qtd_col) * pl.col(pms_col))
        .otherwise(pl.col(qtd_col) * pl.col(pme_col) * 1.30)
    )


def _base_estoque_expr(pms_col: str, pme_col: str, qtd_col: str) -> pl.Expr:
    # Fallback com markup 1.30 quando não há PMS (doc tabela_anual, seção ICMS anual)
    return (
        pl.when(pl.col(pms_col) > 0)
        .then(pl.col(qtd_col) * pl.col(pms_col))
        .otherwise(pl.col(qtd_col) * pl.col(pme_col) * 1.30)
    )


def build_aba_mensal_v4(
    mov_df: pl.DataFrame,
    sitafe_aux_df: pl.DataFrame | None = None,
) -> pl.DataFrame:
    if mov_df.is_empty():
        return pl.DataFrame()

    df = mov_df.with_columns(pl.coalesce([pl.col("dt_e_s"), pl.col("dt_doc")]).alias("data_ref"))
    if df.schema.get("data_ref") == pl.Utf8:
        df = df.with_columns(pl.col("data_ref").str.strptime(pl.Date, strict=False))

    # Garantir vl_item para PME/PMS ponderado; fallback via preco_unit * q_conv
    if "vl_item" not in df.columns:
        if "preco_unit" in df.columns:
            df = df.with_columns((pl.col("preco_unit").fill_null(0.0) * pl.col("q_conv").fill_null(0.0)).alias("vl_item"))
        else:
            df = df.with_columns(pl.lit(0.0).alias("vl_item"))

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
        pl.col("co_sefin_agr").drop_nulls().first().alias("co_sefin_agr"),
        pl.col("it_pc_interna").drop_nulls().last().alias("aliq_interna") if "it_pc_interna" in df.columns else (pl.col("aliq_interna").drop_nulls().last().alias("aliq_interna") if "aliq_interna" in df.columns else pl.lit(17.0).alias("aliq_interna")),
        pl.col("__it_in_st_bool__").any().alias("__tem_st_mes__"),
        pl.col("it_pc_mva").drop_nulls().last().alias("MVA") if "it_pc_mva" in df.columns else pl.lit(0.0).alias("MVA"),
        pl.col("it_in_mva_ajustado").drop_nulls().last().alias("it_in_mva_ajustado") if "it_in_mva_ajustado" in df.columns else pl.lit("N").alias("it_in_mva_ajustado"),
        pl.col("aliq_inter").drop_nulls().last().alias("aliq_inter") if has_aliq_inter else pl.lit(None).alias("aliq_inter"),
    ).with_columns(
        pl.when(pl.col("qtd_entradas") > 0).then(pl.col("valor_entradas") / pl.col("qtd_entradas")).otherwise(0.0).alias("pme_mes"),
        pl.when(pl.col("qtd_saidas") > 0).then(pl.col("valor_saidas") / pl.col("qtd_saidas")).otherwise(0.0).alias("pms_mes"),
        (pl.col("saldo_mes") * pl.col("custo_medio_mes")).alias("valor_estoque"),
        (pl.col("saldo_mes_periodo") * pl.col("custo_medio_mes_periodo")).alias("valor_estoque_periodo"),
        pl.when(pl.col("__tem_st_mes__")).then(pl.lit("ST")).otherwise(pl.lit("SEM ST")).alias("ST"),
    ).with_columns(
        pl.when(pl.col("it_in_mva_ajustado").cast(pl.Utf8, strict=False).str.to_uppercase() == "S").then(_mva_ajustado_expr(has_aliq_inter)).otherwise(pl.col("MVA").fill_null(0.0) / 100.0).alias("MVA_efetivo"),
    ).with_columns(
        pl.when(pl.col("__tem_st_mes__") & (pl.col("entradas_desacob") > 0))
        .then(
            pl.when(pl.col("pms_mes") > 0)
            .then(pl.col("pms_mes").round(2) * pl.col("entradas_desacob") * (pl.col("aliq_interna").fill_null(0.0) / 100.0))
            .otherwise(pl.col("pme_mes").round(2) * pl.col("entradas_desacob") * (pl.col("aliq_interna").fill_null(0.0) / 100.0) * pl.coalesce([pl.col("MVA_efetivo"), pl.lit(1.0)]))
        )
        .otherwise(0.0)
        .alias("ICMS_entr_desacob"),
        pl.when(pl.col("__tem_st_mes__") & (pl.col("entradas_desacob_periodo") > 0))
        .then(
            pl.when(pl.col("pms_mes") > 0)
            .then(pl.col("pms_mes").round(2) * pl.col("entradas_desacob_periodo") * (pl.col("aliq_interna").fill_null(0.0) / 100.0))
            .otherwise(pl.col("pme_mes").round(2) * pl.col("entradas_desacob_periodo") * (pl.col("aliq_interna").fill_null(0.0) / 100.0) * pl.coalesce([pl.col("MVA_efetivo"), pl.lit(1.0)]))
        )
        .otherwise(0.0)
        .alias("ICMS_entr_desacob_periodo"),
        pl.when(pl.col("__tem_st_mes__")).then(pl.lit("S")).otherwise(pl.lit("N")).alias("it_in_st"),
        pl.when(pl.col("it_in_mva_ajustado").cast(pl.Utf8, strict=False).str.to_uppercase() == "S").then(pl.col("MVA_efetivo")).otherwise(None).alias("MVA_ajustado"),
    ).drop("__tem_st_mes__").rename({"id_agrupado": "id_agregado"})

    result = _round_quantities(result, ["qtd_entradas", "qtd_saidas", "saldo_mes", "entradas_desacob", "entradas_desacob_periodo", "saldo_mes_periodo"])
    result = _round_money(result, ["valor_entradas", "valor_saidas", "valor_estoque", "valor_estoque_periodo", "ICMS_entr_desacob", "ICMS_entr_desacob_periodo", "aliq_interna"])

    # Enriquecimento temporal ST via sitafe_produto_sefin_aux (opcional)
    if sitafe_aux_df is not None and not sitafe_aux_df.is_empty():
        st_enr = resolve_st_mensal(result, sitafe_aux_df, sefin_col="co_sefin_agr", ano_col="ano", mes_col="mes")
        if not st_enr.is_empty():
            result = (
                result.join(
                    st_enr.select(["co_sefin_agr", "ano", "mes", "__tem_st__", "__st_text__", "__aliq_interna__"]),
                    on=["co_sefin_agr", "ano", "mes"],
                    how="left",
                )
                .with_columns(
                    pl.coalesce([pl.col("__st_text__"), pl.col("ST")]).alias("ST"),
                    pl.coalesce([pl.col("__aliq_interna__"), pl.col("aliq_interna")]).alias("aliq_interna"),
                    pl.coalesce([pl.col("__tem_st__"), pl.col("ST").str.starts_with("ST")]).alias("__tem_st_recalc__"),
                )
                .with_columns(
                    # Recalcular ICMS_entr_desacob com ST e aliq_interna corrigidos
                    pl.when(pl.col("__tem_st_recalc__") & (pl.col("entradas_desacob") > 0))
                    .then(
                        pl.when(pl.col("pms_mes") > 0)
                        .then(pl.col("pms_mes") * pl.col("entradas_desacob") * (pl.col("aliq_interna").fill_null(0.0) / 100.0))
                        .otherwise(pl.col("pme_mes") * pl.col("entradas_desacob") * (pl.col("aliq_interna").fill_null(0.0) / 100.0) * pl.coalesce([pl.col("MVA_efetivo"), pl.lit(1.0)]))
                    )
                    .otherwise(0.0)
                    .round(2).alias("ICMS_entr_desacob"),
                    pl.when(pl.col("__tem_st_recalc__") & (pl.col("entradas_desacob_periodo") > 0))
                    .then(
                        pl.when(pl.col("pms_mes") > 0)
                        .then(pl.col("pms_mes") * pl.col("entradas_desacob_periodo") * (pl.col("aliq_interna").fill_null(0.0) / 100.0))
                        .otherwise(pl.col("pme_mes") * pl.col("entradas_desacob_periodo") * (pl.col("aliq_interna").fill_null(0.0) / 100.0) * pl.coalesce([pl.col("MVA_efetivo"), pl.lit(1.0)]))
                    )
                    .otherwise(0.0)
                    .round(2).alias("ICMS_entr_desacob_periodo"),
                )
                .drop(["__tem_st__", "__st_text__", "__aliq_interna__", "__tem_st_recalc__"])
            )

    return result


def build_aba_anual_v4(
    mov_df: pl.DataFrame,
    sitafe_aux_df: pl.DataFrame | None = None,
) -> pl.DataFrame:
    if mov_df.is_empty():
        return pl.DataFrame()

    df = mov_df.with_columns(pl.coalesce([pl.col("dt_e_s"), pl.col("dt_doc")]).alias("data_ref"))
    if df.schema.get("data_ref") == pl.Utf8:
        df = df.with_columns(pl.col("data_ref").str.strptime(pl.Date, strict=False))

    # Garantir vl_item para PME/PMS ponderado; fallback via preco_unit * q_conv
    if "vl_item" not in df.columns:
        if "preco_unit" in df.columns:
            df = df.with_columns((pl.col("preco_unit").fill_null(0.0) * pl.col("q_conv").fill_null(0.0)).alias("vl_item"))
        else:
            df = df.with_columns(pl.lit(0.0).alias("vl_item"))

    df = df.with_columns(
        pl.col("data_ref").dt.year().alias("ano"),
        _normalize_st_expr(pl.col("it_in_st")).alias("__it_in_st_bool__"),
        _normalize_yes_no_expr(pl.col("it_in_mva_ajustado")).alias("__it_in_mva_ajustado_bool__") if "it_in_mva_ajustado" in df.columns else pl.lit(False).alias("__it_in_mva_ajustado_bool__"),
    )
    has_aliq_inter = "aliq_inter" in df.columns
    has_pc_interna = "it_pc_interna" in df.columns
    has_aliq_interna = "aliq_interna" in df.columns

    result = df.group_by(["id_agrupado", "ano"]).agg(
        pl.col("descr_padrao").drop_nulls().first().alias("descr_padrao"),
        pl.col("unid_ref").drop_nulls().first().alias("unid_ref"),
        pl.when(pl.col("tipo_operacao") == "0 - ESTOQUE INICIAL").then(pl.col("q_conv")).otherwise(0.0).sum().alias("estoque_inicial"),
        pl.when(pl.col("tipo_operacao") == "1 - ENTRADA").then(pl.col("q_conv")).otherwise(0.0).sum().alias("entradas"),
        pl.when(pl.col("tipo_operacao") == "2 - SAIDAS").then(pl.col("q_conv").abs()).otherwise(0.0).sum().alias("saidas"),
        # Bug fix: usar q_conv (fator aplicado) em vez de qtd bruto para estoque_final
        pl.when(pl.col("tipo_operacao") == "3 - ESTOQUE FINAL").then(pl.col("q_conv")).otherwise(0.0).sum().alias("estoque_final"),
        pl.col("entr_desac_anual").sum().alias("entradas_desacob"),
        pl.col("saldo_estoque_anual").drop_nulls().last().alias("saldo_final"),
        # Média ponderada: sum(vl_item)/sum(q_conv) em vez de mean(preco_unit)
        pl.when(pl.col("tipo_operacao") == "1 - ENTRADA").then(pl.col("vl_item")).otherwise(0.0).sum().alias("__valor_entradas__"),
        pl.when(pl.col("tipo_operacao") == "1 - ENTRADA").then(pl.col("q_conv")).otherwise(0.0).sum().alias("__qtd_entradas__"),
        pl.when(pl.col("tipo_operacao") == "2 - SAIDAS").then(pl.col("vl_item").abs()).otherwise(0.0).sum().alias("__valor_saidas__"),
        pl.when(pl.col("tipo_operacao") == "2 - SAIDAS").then(pl.col("q_conv").abs()).otherwise(0.0).sum().alias("__qtd_saidas__"),
        pl.col("co_sefin_agr").drop_nulls().first().alias("co_sefin_agr"),
        pl.coalesce([pl.col("it_pc_interna"), pl.col("aliq_interna")]).drop_nulls().last().alias("aliq_interna") if has_pc_interna and has_aliq_interna else (
            pl.col("it_pc_interna").drop_nulls().last().alias("aliq_interna") if has_pc_interna else (
                pl.col("aliq_interna").drop_nulls().last().alias("aliq_interna") if has_aliq_interna else pl.lit(17.0).alias("aliq_interna")
            )
        ),
        pl.col("__it_in_st_bool__").any().alias("__tem_st_ano__"),
        pl.col("__it_in_mva_ajustado_bool__").any().alias("__usa_mva_ajustada__"),
        pl.col("it_pc_mva").drop_nulls().last().alias("MVA") if "it_pc_mva" in df.columns else pl.lit(0.0).alias("MVA"),
        pl.col("aliq_inter").drop_nulls().last().alias("aliq_inter") if has_aliq_inter else pl.lit(None).alias("aliq_inter"),
        pl.col("divergencia_estoque_declarado").sum().alias("divergencia_estoque_declarado") if "divergencia_estoque_declarado" in df.columns else pl.lit(0.0).alias("divergencia_estoque_declarado"),
        pl.col("divergencia_estoque_calculado").sum().alias("divergencia_estoque_calculado") if "divergencia_estoque_calculado" in df.columns else pl.lit(0.0).alias("divergencia_estoque_calculado"),
    ).with_columns(
        pl.when(pl.col("__qtd_entradas__") > 0).then(pl.col("__valor_entradas__") / pl.col("__qtd_entradas__")).otherwise(0.0).alias("pme"),
        pl.when(pl.col("__qtd_saidas__") > 0).then(pl.col("__valor_saidas__") / pl.col("__qtd_saidas__")).otherwise(0.0).alias("pms"),
        (pl.col("estoque_inicial") + pl.col("entradas") + pl.col("entradas_desacob") - pl.col("estoque_final")).alias("saidas_calculadas"),
        (pl.col("estoque_final") - pl.col("saldo_final")).clip(lower_bound=0).alias("saidas_desacob"),
        (pl.col("saldo_final") - pl.col("estoque_final")).clip(lower_bound=0).alias("estoque_final_desacob"),
        pl.when(pl.col("__tem_st_ano__")).then(pl.lit("ST")).otherwise(pl.lit("SEM ST")).alias("ST"),
    ).with_columns(
        pl.when(pl.col("__tem_st_ano__") & pl.col("__usa_mva_ajustada__"))
        .then(_mva_ajustado_expr(has_aliq_inter))
        .otherwise(None)
        .alias("MVA_ajustado"),
        _base_saida_expr("pms", "pme", "saidas_desacob").alias("__base_saida__"),
        _base_estoque_expr("pms", "pme", "estoque_final_desacob").alias("__base_estoque__"),
    ).with_columns(
        pl.when(pl.col("__tem_st_ano__")).then(0.0).otherwise(pl.col("__base_saida__") * (pl.col("aliq_interna").fill_null(0.0) / 100.0)).alias("ICMS_saidas_desac"),
        (pl.col("__base_estoque__") * (pl.col("aliq_interna").fill_null(0.0) / 100.0)).alias("ICMS_estoque_desac"),
    ).drop(["__tem_st_ano__", "__usa_mva_ajustada__", "__base_saida__", "__base_estoque__", "__valor_entradas__", "__qtd_entradas__", "__valor_saidas__", "__qtd_saidas__"]).rename({"id_agrupado": "id_agregado"})

    result = _round_quantities(result, ["estoque_inicial", "entradas", "saidas", "estoque_final", "saidas_calculadas", "saldo_final", "entradas_desacob", "saidas_desacob", "estoque_final_desacob", "divergencia_estoque_declarado", "divergencia_estoque_calculado"])
    result = _round_money(result, ["pme", "pms", "aliq_interna", "ICMS_saidas_desac", "ICMS_estoque_desac"])

    # Enriquecimento temporal ST via sitafe_produto_sefin_aux (opcional)
    if sitafe_aux_df is not None and not sitafe_aux_df.is_empty():
        st_enr = resolve_st_anual(result, sitafe_aux_df, sefin_col="co_sefin_agr", ano_col="ano")
        if not st_enr.is_empty():
            result = (
                result.join(
                    st_enr.select(["co_sefin_agr", "ano", "__tem_st__", "__st_text__", "__aliq_interna__"]),
                    on=["co_sefin_agr", "ano"],
                    how="left",
                )
                .with_columns(
                    pl.coalesce([pl.col("__st_text__"), pl.col("ST")]).alias("ST"),
                    pl.coalesce([pl.col("__aliq_interna__"), pl.col("aliq_interna")]).alias("aliq_interna"),
                    pl.coalesce([pl.col("__tem_st__"), pl.col("ST").str.starts_with("ST")]).alias("__tem_st_recalc__"),
                )
                .with_columns(
                    # Recalcular ICMS_saidas_desac com ST e aliq_interna corrigidos
                    pl.when(pl.col("__tem_st_recalc__"))
                    .then(0.0)
                    .otherwise(
                        pl.when(pl.col("pms") > 0)
                        .then(pl.col("saidas_desacob") * pl.col("pms") * (pl.col("aliq_interna").fill_null(0.0) / 100.0))
                        .otherwise(pl.col("saidas_desacob") * pl.col("pme") * 1.30 * (pl.col("aliq_interna").fill_null(0.0) / 100.0))
                    ).round(2).alias("ICMS_saidas_desac"),
                    # Recalcular ICMS_estoque_desac com aliq_interna corrigida
                    (
                        pl.when(pl.col("pms") > 0)
                        .then(pl.col("estoque_final_desacob") * pl.col("pms"))
                        .otherwise(pl.col("estoque_final_desacob") * pl.col("pme") * 1.30)
                    ).mul(pl.col("aliq_interna").fill_null(0.0) / 100.0).round(2).alias("ICMS_estoque_desac"),
                )
                .drop(["__tem_st__", "__st_text__", "__aliq_interna__", "__tem_st_recalc__"])
            )

    return result


def build_aba_periodos_v4(mov_df: pl.DataFrame) -> pl.DataFrame:
    if mov_df.is_empty() or "periodo_inventario" not in mov_df.columns:
        return pl.DataFrame()

    df = mov_df

    # Garantir vl_item para PME/PMS ponderado; fallback via preco_unit * q_conv
    if "vl_item" not in df.columns:
        if "preco_unit" in df.columns:
            df = df.with_columns((pl.col("preco_unit").fill_null(0.0) * pl.col("q_conv").fill_null(0.0)).alias("vl_item"))
        else:
            df = df.with_columns(pl.lit(0.0).alias("vl_item"))

    df = df.with_columns(
        _normalize_st_expr(pl.col("it_in_st")).alias("__it_in_st_bool__"),
        _normalize_yes_no_expr(pl.col("it_in_mva_ajustado")).alias("__it_in_mva_ajustado_bool__") if "it_in_mva_ajustado" in mov_df.columns else pl.lit(False).alias("__it_in_mva_ajustado_bool__"),
    )
    has_aliq_inter = "aliq_inter" in df.columns
    has_pc_interna = "it_pc_interna" in df.columns
    has_aliq_interna = "aliq_interna" in df.columns

    result = df.group_by(["id_agrupado", "periodo_inventario"]).agg(
        pl.col("descr_padrao").drop_nulls().first().alias("descr_padrao"),
        pl.col("unid_ref").drop_nulls().first().alias("unid_ref"),
        pl.when(pl.col("tipo_operacao") == "0 - ESTOQUE INICIAL").then(pl.col("q_conv")).otherwise(0.0).sum().alias("estoque_inicial"),
        pl.when(pl.col("tipo_operacao") == "1 - ENTRADA").then(pl.col("q_conv")).otherwise(0.0).sum().alias("entradas"),
        pl.when(pl.col("tipo_operacao") == "2 - SAIDAS").then(pl.col("q_conv").abs()).otherwise(0.0).sum().alias("saidas"),
        # Bug fix: usar q_conv (fator aplicado) em vez de qtd bruto para estoque_final
        pl.when(pl.col("tipo_operacao") == "3 - ESTOQUE FINAL").then(pl.col("q_conv")).otherwise(0.0).sum().alias("estoque_final"),
        pl.col("entr_desac_periodo").sum().alias("entradas_desacob"),
        pl.col("saldo_estoque_periodo").drop_nulls().last().alias("saldo_final"),
        # Média ponderada: sum(vl_item)/sum(q_conv) em vez de mean(preco_unit)
        pl.when(pl.col("tipo_operacao") == "1 - ENTRADA").then(pl.col("vl_item")).otherwise(0.0).sum().alias("__valor_entradas__"),
        pl.when(pl.col("tipo_operacao") == "1 - ENTRADA").then(pl.col("q_conv")).otherwise(0.0).sum().alias("__qtd_entradas__"),
        pl.when(pl.col("tipo_operacao") == "2 - SAIDAS").then(pl.col("vl_item").abs()).otherwise(0.0).sum().alias("__valor_saidas__"),
        pl.when(pl.col("tipo_operacao") == "2 - SAIDAS").then(pl.col("q_conv").abs()).otherwise(0.0).sum().alias("__qtd_saidas__"),
        pl.col("co_sefin_agr").drop_nulls().first().alias("co_sefin_agr"),
        pl.coalesce([pl.col("it_pc_interna"), pl.col("aliq_interna")]).drop_nulls().last().alias("aliq_interna") if has_pc_interna and has_aliq_interna else (
            pl.col("it_pc_interna").drop_nulls().last().alias("aliq_interna") if has_pc_interna else (
                pl.col("aliq_interna").drop_nulls().last().alias("aliq_interna") if has_aliq_interna else pl.lit(17.0).alias("aliq_interna")
            )
        ),
        pl.col("__it_in_st_bool__").any().alias("__tem_st_per__"),
        pl.col("__it_in_mva_ajustado_bool__").any().alias("__usa_mva_ajustada__"),
        pl.col("it_pc_mva").drop_nulls().last().alias("MVA") if "it_pc_mva" in df.columns else pl.lit(0.0).alias("MVA"),
        pl.col("aliq_inter").drop_nulls().last().alias("aliq_inter") if has_aliq_inter else pl.lit(None).alias("aliq_inter"),
        pl.col("divergencia_estoque_declarado").sum().alias("divergencia_estoque_declarado") if "divergencia_estoque_declarado" in df.columns else pl.lit(0.0).alias("divergencia_estoque_declarado"),
        pl.col("divergencia_estoque_calculado").sum().alias("divergencia_estoque_calculado") if "divergencia_estoque_calculado" in df.columns else pl.lit(0.0).alias("divergencia_estoque_calculado"),
    ).with_columns(
        pl.when(pl.col("__qtd_entradas__") > 0).then(pl.col("__valor_entradas__") / pl.col("__qtd_entradas__")).otherwise(0.0).alias("pme"),
        pl.when(pl.col("__qtd_saidas__") > 0).then(pl.col("__valor_saidas__") / pl.col("__qtd_saidas__")).otherwise(0.0).alias("pms"),
        (pl.col("estoque_inicial") + pl.col("entradas") + pl.col("entradas_desacob") - pl.col("estoque_final")).alias("saidas_calculadas"),
        (pl.col("estoque_final") - pl.col("saldo_final")).clip(lower_bound=0).alias("saidas_desacob"),
        (pl.col("saldo_final") - pl.col("estoque_final")).clip(lower_bound=0).alias("estoque_final_desacob"),
        pl.when(pl.col("__tem_st_per__")).then(pl.lit("ST")).otherwise(pl.lit("SEM ST")).alias("ST"),
    ).with_columns(
        pl.when(pl.col("__tem_st_per__") & pl.col("__usa_mva_ajustada__"))
        .then(_mva_ajustado_expr(has_aliq_inter))
        .otherwise(None)
        .alias("MVA_ajustado"),
        _base_saida_expr("pms", "pme", "saidas_desacob").alias("__base_saida__"),
        _base_estoque_expr("pms", "pme", "estoque_final_desacob").alias("__base_estoque__"),
    ).with_columns(
        pl.when(pl.col("__tem_st_per__")).then(0.0).otherwise(pl.col("__base_saida__") * (pl.col("aliq_interna").fill_null(0.0) / 100.0)).alias("ICMS_saidas_desac"),
        (pl.col("__base_estoque__") * (pl.col("aliq_interna").fill_null(0.0) / 100.0)).alias("ICMS_estoque_desac"),
        pl.col("periodo_inventario").alias("cod_per"),
    ).drop(["__tem_st_per__", "__usa_mva_ajustada__", "__base_saida__", "__base_estoque__", "__valor_entradas__", "__qtd_entradas__", "__valor_saidas__", "__qtd_saidas__"]).rename({"id_agrupado": "id_agregado"})

    result = _round_quantities(result, ["estoque_inicial", "entradas", "saidas", "estoque_final", "saidas_calculadas", "saldo_final", "entradas_desacob", "saidas_desacob", "estoque_final_desacob", "divergencia_estoque_declarado", "divergencia_estoque_calculado"])
    result = _round_money(result, ["pme", "pms", "aliq_interna", "ICMS_saidas_desac", "ICMS_estoque_desac"])
    return result
