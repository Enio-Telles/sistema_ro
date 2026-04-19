from __future__ import annotations

import polars as pl

from pipeline.estoque.mov_estoque import _prepare_source
from pipeline.estoque.periodos import assign_periodo_inventario, build_estoque_inicial_rows


def build_mov_estoque_v2(
    c170_df: pl.DataFrame,
    nfe_df: pl.DataFrame,
    nfce_df: pl.DataFrame,
    bloco_h_df: pl.DataFrame,
    fatores_df: pl.DataFrame,
) -> pl.DataFrame:
    frames: list[pl.DataFrame] = []

    estoque_inicial = build_estoque_inicial_rows(bloco_h_df)
    if not estoque_inicial.is_empty():
        frames.append(_prepare_source(estoque_inicial, "gerado", "0 - ESTOQUE INICIAL"))
    if not c170_df.is_empty():
        frames.append(_prepare_source(c170_df, "c170", "1 - ENTRADA"))
    if not nfe_df.is_empty():
        frames.append(_prepare_source(nfe_df, "nfe", "2 - SAIDAS"))
    if not nfce_df.is_empty():
        frames.append(_prepare_source(nfce_df, "nfce", "2 - SAIDAS"))
    if not bloco_h_df.is_empty():
        frames.append(_prepare_source(bloco_h_df, "bloco_h", "3 - ESTOQUE FINAL"))

    if not frames:
        return pl.DataFrame()

    mov = pl.concat(frames, how="diagonal_relaxed")
    if "id_agrupado" in mov.columns and "id_agrupado" in fatores_df.columns:
        payload_cols = [c for c in ["mercadoria_id", "apresentacao_id", "unid_ref", "fator", "tipo_fator", "confianca_fator", "fonte_fator"] if c in fatores_df.columns]

        can_join_por_unid = "unid" in mov.columns and "unid" in fatores_df.columns

        if can_join_por_unid:
            # Passo 1 — join específico por id_agrupado + unid
            fat_spec = (
                fatores_df
                .select(["id_agrupado", "unid"] + payload_cols)
                .unique(subset=["id_agrupado", "unid"])
                .rename({c: f"{c}__s" for c in payload_cols})
            )
            mov = mov.join(fat_spec, on=["id_agrupado", "unid"], how="left")

            # Passo 2 — fallback por id_agrupado para linhas sem match específico
            explicit_general = fatores_df.filter(
                pl.col("unid").cast(pl.Utf8, strict=False).fill_null("").str.strip_chars() == ""
            )
            implicit_general_ids = (
                fatores_df
                .filter(pl.col("unid").cast(pl.Utf8, strict=False).fill_null("").str.strip_chars() != "")
                .group_by("id_agrupado")
                .agg(pl.col("unid").n_unique().alias("unique_unid_count"))
                .filter(pl.col("unique_unid_count") == 1)
                .select("id_agrupado")
            )
            implicit_general = fatores_df.join(implicit_general_ids, on="id_agrupado", how="inner")
            fat_gen = (
                pl.concat(
                    [
                        explicit_general.select(["id_agrupado"] + payload_cols),
                        implicit_general.select(["id_agrupado"] + payload_cols),
                    ],
                    how="diagonal_relaxed",
                )
                .unique(subset=["id_agrupado"], keep="first")
                .rename({c: f"{c}__g" for c in payload_cols})
            ) if (not explicit_general.is_empty() or not implicit_general.is_empty()) else pl.DataFrame()
            if not fat_gen.is_empty():
                mov = mov.join(fat_gen, on="id_agrupado", how="left")
            else:
                mov = mov.with_columns([
                    pl.lit(None).alias(f"{c}__g")
                    for c in payload_cols
                ])

            # Mesclar: específico > geral; registrar chave usada
            coalesce_exprs = [
                pl.when(pl.col(f"{c}__s").is_not_null())
                .then(pl.col(f"{c}__s"))
                .otherwise(pl.col(f"{c}__g"))
                .alias(c)
                for c in payload_cols
            ]
            resolution_expr = (
                pl.when(pl.col("fator__s").is_not_null())
                .then(pl.lit("id_agrupado+unid"))
                .when(pl.col("fator__g").is_not_null())
                .then(pl.lit("id_agrupado"))
                .otherwise(pl.lit("fallback_default"))
                .alias("factor_resolution_mode")
            ) if "fator" in payload_cols else pl.lit("id_agrupado+unid").alias("factor_resolution_mode")

            mov = mov.with_columns(coalesce_exprs + [resolution_expr])
            tmp = [f"{c}__s" for c in payload_cols] + [f"{c}__g" for c in payload_cols]
            mov = mov.drop([c for c in tmp if c in mov.columns])

        else:
            # Legado: join por id_agrupado apenas (sem coluna unid disponível)
            mov = mov.join(
                fatores_df.select(["id_agrupado"] + payload_cols).unique(subset=["id_agrupado"]),
                on="id_agrupado",
                how="left",
            ).with_columns(pl.lit("id_agrupado").alias("factor_resolution_mode"))

    fator_expr = pl.col("fator").fill_null(1.0)

    mov = mov.with_columns(
        fator_expr.alias("fator"),
        pl.when(pl.col("tipo_operacao") == "3 - ESTOQUE FINAL")
        .then(pl.lit(0.0))
        .otherwise(pl.col("qtd").abs() * fator_expr.abs())
        .alias("q_conv"),
        pl.when((pl.col("qtd").abs() > 0) & (pl.col("tipo_operacao") != "3 - ESTOQUE FINAL"))
        .then(pl.col("vl_item") / (pl.col("qtd").abs() * fator_expr.abs()))
        .otherwise(None)
        .alias("preco_unit"),
        pl.when(pl.col("tipo_operacao") == "2 - SAIDAS")
        .then(-pl.col("qtd").abs() * fator_expr.abs())
        .otherwise(
            pl.when(pl.col("tipo_operacao") == "3 - ESTOQUE FINAL")
            .then(pl.lit(0.0))
            .otherwise(pl.col("qtd").abs() * fator_expr.abs())
        )
        .alias("__q_conv_sinal__"),
        pl.when(pl.col("tipo_operacao") == "3 - ESTOQUE FINAL")
        .then(pl.col("qtd").abs() * fator_expr.abs())
        .otherwise(None)
        .alias("__qtd_decl_final_audit__"),
        pl.when(pl.col("tipo_operacao") == "3 - ESTOQUE FINAL")
        .then(pl.col("qtd").abs() * fator_expr.abs())
        .otherwise(None)
        .alias("estoque_final_declarado"),
    )

    if "dt_e_s" in mov.columns and mov.schema.get("dt_e_s") == pl.Utf8:
        mov = mov.with_columns(pl.col("dt_e_s").str.strptime(pl.Date, strict=False))
    if "dt_doc" in mov.columns and mov.schema.get("dt_doc") == pl.Utf8:
        mov = mov.with_columns(pl.col("dt_doc").str.strptime(pl.Date, strict=False))

    operation_order = (
        pl.when(pl.col("tipo_operacao") == "0 - ESTOQUE INICIAL").then(0)
        .when(pl.col("tipo_operacao") == "1 - ENTRADA").then(1)
        .when(pl.col("tipo_operacao") == "2 - SAIDAS").then(2)
        .otherwise(3)
        .alias("__ordem_operacao__")
    )
    mov = mov.with_columns(operation_order)

    sort_cols = [c for c in ["id_agrupado", "dt_e_s", "dt_doc", "__ordem_operacao__", "id_linha_origem"] if c in mov.columns]
    mov = mov.sort(sort_cols, nulls_last=True)
    mov = assign_periodo_inventario(mov)

    if "id_agrupado" in mov.columns:
        mov = mov.with_columns(
            pl.col("__q_conv_sinal__").cum_sum().over(["id_agrupado", "periodo_inventario"]).alias("__saldo_bruto_periodo__"),
            pl.col("__q_conv_sinal__").cum_sum().over("id_agrupado").alias("__saldo_bruto_anual__"),
        )
        mov = mov.with_columns(
            (-pl.col("__saldo_bruto_anual__").cum_min().over("id_agrupado").clip(upper_bound=0.0)).alias("__deficit_acum_anual__"),
            (-pl.col("__saldo_bruto_periodo__").cum_min().over(["id_agrupado", "periodo_inventario"]).clip(upper_bound=0.0)).alias("__deficit_acum_periodo__"),
        )
        mov = mov.with_columns(
            (pl.col("__saldo_bruto_anual__") + pl.col("__deficit_acum_anual__")).alias("saldo_estoque_anual"),
            (pl.col("__saldo_bruto_periodo__") + pl.col("__deficit_acum_periodo__")).alias("saldo_estoque_periodo"),
            pl.coalesce([
                (pl.col("__deficit_acum_anual__") - pl.col("__deficit_acum_anual__").shift(1).over("id_agrupado")).clip(lower_bound=0.0),
                pl.col("__deficit_acum_anual__"),
            ]).alias("entr_desac_anual"),
            pl.coalesce([
                (
                    pl.col("__deficit_acum_periodo__")
                    - pl.col("__deficit_acum_periodo__").shift(1).over(["id_agrupado", "periodo_inventario"])
                ).clip(lower_bound=0.0),
                pl.col("__deficit_acum_periodo__"),
            ]).alias("entr_desac_periodo"),
            pl.col("preco_unit").forward_fill().over("id_agrupado").fill_null(0.0).alias("custo_medio_anual"),
            pl.col("preco_unit").forward_fill().over(["id_agrupado", "periodo_inventario"]).fill_null(0.0).alias("custo_medio_periodo"),
        )
        mov = mov.with_columns(
            pl.when(pl.col("tipo_operacao") == "3 - ESTOQUE FINAL")
            .then((pl.col("__qtd_decl_final_audit__") - pl.col("saldo_estoque_periodo")).clip(lower_bound=0))
            .otherwise(0.0)
            .alias("divergencia_estoque_declarado"),
            pl.when(pl.col("tipo_operacao") == "3 - ESTOQUE FINAL")
            .then((pl.col("saldo_estoque_periodo") - pl.col("__qtd_decl_final_audit__")).clip(lower_bound=0))
            .otherwise(0.0)
            .alias("divergencia_estoque_calculado"),
        )
    return mov.drop([
        c
        for c in [
            "__q_conv_sinal__",
            "__ordem_operacao__",
            "__saldo_bruto_anual__",
            "__saldo_bruto_periodo__",
            "__deficit_acum_anual__",
            "__deficit_acum_periodo__",
        ]
        if c in mov.columns
    ])
