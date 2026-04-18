from __future__ import annotations

import polars as pl


def _prepare_source(df: pl.DataFrame, fonte: str, tipo_operacao: str) -> pl.DataFrame:
    if df.is_empty():
        return df
    cols = df.columns
    result = df.with_columns(
        pl.lit(fonte).alias("fonte"),
        pl.lit(tipo_operacao).alias("tipo_operacao"),
        pl.col("qtd").cast(pl.Float64, strict=False).alias("qtd") if "qtd" in cols else pl.lit(0.0).alias("qtd"),
        pl.col("vl_item").cast(pl.Float64, strict=False).alias("vl_item") if "vl_item" in cols else pl.lit(0.0).alias("vl_item"),
    )
    if "dt_doc" not in cols:
        result = result.with_columns(pl.lit(None, dtype=pl.Utf8).alias("dt_doc"))
    if "dt_e_s" not in cols:
        result = result.with_columns(pl.col("dt_doc").alias("dt_e_s"))
    return result


def build_mov_estoque(
    c170_df: pl.DataFrame,
    nfe_df: pl.DataFrame,
    nfce_df: pl.DataFrame,
    bloco_h_df: pl.DataFrame,
    fatores_df: pl.DataFrame,
) -> pl.DataFrame:
    frames: list[pl.DataFrame] = []
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
        pl.when(pl.col("tipo_operacao") == "3 - ESTOQUE FINAL").then(pl.lit(0.0)).otherwise(pl.col("qtd").abs() * pl.col("fator").abs()).alias("q_conv"),
        pl.when((pl.col("qtd").abs() > 0) & (pl.col("tipo_operacao") != "3 - ESTOQUE FINAL")).then(pl.col("vl_item") / (pl.col("qtd").abs() * pl.col("fator").abs())).otherwise(None).alias("preco_unit"),
        pl.when(pl.col("tipo_operacao") == "2 - SAIDAS").then(-pl.col("qtd").abs() * pl.col("fator").abs()).otherwise(pl.when(pl.col("tipo_operacao") == "3 - ESTOQUE FINAL").then(pl.lit(0.0)).otherwise(pl.col("qtd").abs() * pl.col("fator").abs())).alias("__q_conv_sinal__"),
    )

    sort_cols = [c for c in ["id_agrupado", "dt_e_s", "dt_doc", "id_linha_origem"] if c in mov.columns]
    if sort_cols:
        mov = mov.sort(sort_cols, nulls_last=True)

    if "id_agrupado" in mov.columns:
        mov = mov.with_columns(
            pl.col("__q_conv_sinal__").cum_sum().over("id_agrupado").alias("saldo_estoque_anual")
        )
        mov = mov.with_columns(
            pl.when(pl.col("saldo_estoque_anual") < 0).then((-pl.col("saldo_estoque_anual")).clip(lower_bound=0)).otherwise(0.0).alias("entr_desac_anual")
        )
        mov = mov.with_columns(
            pl.when(pl.col("saldo_estoque_anual") < 0).then(0.0).otherwise(pl.col("saldo_estoque_anual")).alias("saldo_estoque_anual"),
            pl.col("preco_unit").forward_fill().over("id_agrupado").fill_null(0.0).alias("custo_medio_anual"),
        )
        mov = mov.with_columns(
            pl.col("saldo_estoque_anual").alias("saldo_estoque_periodo"),
            pl.col("entr_desac_anual").alias("entr_desac_periodo"),
            pl.col("custo_medio_anual").alias("custo_medio_periodo"),
        )
    return mov
