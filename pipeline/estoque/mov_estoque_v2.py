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
        factor_select = [c for c in ["id_agrupado", "mercadoria_id", "apresentacao_id", "unid_ref", "fator", "tipo_fator", "confianca_fator", "fonte_fator"] if c in fatores_df.columns]
        mov = mov.join(fatores_df.select(factor_select).unique(subset=["id_agrupado"]), on="id_agrupado", how="left")

    mov = mov.with_columns(
        pl.col("fator").fill_null(1.0).alias("fator"),
        pl.when(pl.col("tipo_operacao") == "3 - ESTOQUE FINAL")
        .then(pl.col("qtd").abs() * pl.col("fator").abs())
        .otherwise(pl.col("qtd").abs() * pl.col("fator").abs())
        .alias("q_conv"),
        pl.when((pl.col("qtd").abs() > 0) & (pl.col("tipo_operacao") != "3 - ESTOQUE FINAL"))
        .then(pl.col("vl_item") / (pl.col("qtd").abs() * pl.col("fator").abs()))
        .otherwise(None)
        .alias("preco_unit"),
        pl.when(pl.col("tipo_operacao") == "2 - SAIDAS")
        .then(-pl.col("qtd").abs() * pl.col("fator").abs())
        .otherwise(
            pl.when(pl.col("tipo_operacao") == "3 - ESTOQUE FINAL")
            .then(pl.lit(0.0))
            .otherwise(pl.col("qtd").abs() * pl.col("fator").abs())
        )
        .alias("__q_conv_sinal__"),
        pl.when(pl.col("tipo_operacao") == "3 - ESTOQUE FINAL")
        .then(pl.col("qtd").abs() * pl.col("fator").abs())
        .otherwise(None)
        .alias("__qtd_decl_final_audit__"),
        pl.when(pl.col("tipo_operacao") == "3 - ESTOQUE FINAL")
        .then(pl.col("qtd").abs() * pl.col("fator").abs())
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
            pl.col("__q_conv_sinal__").cum_sum().over(["id_agrupado", "periodo_inventario"]).alias("saldo_estoque_periodo"),
            pl.col("__q_conv_sinal__").cum_sum().over("id_agrupado").alias("saldo_estoque_anual"),
        )
        mov = mov.with_columns(
            pl.when(pl.col("saldo_estoque_anual") < 0).then((-pl.col("saldo_estoque_anual")).clip(lower_bound=0)).otherwise(0.0).alias("entr_desac_anual"),
            pl.when(pl.col("saldo_estoque_periodo") < 0).then((-pl.col("saldo_estoque_periodo")).clip(lower_bound=0)).otherwise(0.0).alias("entr_desac_periodo"),
        )
        mov = mov.with_columns(
            pl.when(pl.col("saldo_estoque_anual") < 0).then(0.0).otherwise(pl.col("saldo_estoque_anual")).alias("saldo_estoque_anual"),
            pl.when(pl.col("saldo_estoque_periodo") < 0).then(0.0).otherwise(pl.col("saldo_estoque_periodo")).alias("saldo_estoque_periodo"),
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
    return mov.drop([c for c in ["__q_conv_sinal__", "__ordem_operacao__"] if c in mov.columns])
