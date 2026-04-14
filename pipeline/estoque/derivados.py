from __future__ import annotations

import polars as pl


def build_aba_mensal(mov_df: pl.DataFrame) -> pl.DataFrame:
    if mov_df.is_empty():
        return pl.DataFrame()

    df = mov_df.with_columns(
        pl.coalesce([pl.col("dt_e_s"), pl.col("dt_doc")]).alias("data_ref")
    )
    if df.schema.get("data_ref") == pl.Utf8:
        df = df.with_columns(pl.col("data_ref").str.strptime(pl.Date, strict=False))

    df = df.with_columns(
        pl.col("data_ref").dt.year().alias("ano"),
        pl.col("data_ref").dt.month().alias("mes"),
    )

    return df.group_by(["id_agrupado", "ano", "mes"]).agg(
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
    ).with_columns(
        pl.when(pl.col("qtd_entradas") > 0).then(pl.col("valor_entradas") / pl.col("qtd_entradas")).otherwise(0.0).alias("pme_mes"),
        pl.when(pl.col("qtd_saidas") > 0).then(pl.col("valor_saidas") / pl.col("qtd_saidas")).otherwise(0.0).alias("pms_mes"),
        (pl.col("saldo_mes") * pl.col("custo_medio_mes")).alias("valor_estoque"),
        (pl.col("saldo_mes_periodo") * pl.col("custo_medio_mes_periodo")).alias("valor_estoque_periodo"),
    ).rename({"id_agrupado": "id_agregado"})


def build_aba_anual(mov_df: pl.DataFrame) -> pl.DataFrame:
    if mov_df.is_empty():
        return pl.DataFrame()

    df = mov_df.with_columns(
        pl.coalesce([pl.col("dt_e_s"), pl.col("dt_doc")]).alias("data_ref")
    )
    if df.schema.get("data_ref") == pl.Utf8:
        df = df.with_columns(pl.col("data_ref").str.strptime(pl.Date, strict=False))
    df = df.with_columns(pl.col("data_ref").dt.year().alias("ano"))

    return df.group_by(["id_agrupado", "ano"]).agg(
        pl.col("descr_padrao").drop_nulls().first().alias("descr_padrao"),
        pl.col("unid_ref").drop_nulls().first().alias("unid_ref"),
        pl.when(pl.col("tipo_operacao") == "0 - ESTOQUE INICIAL").then(pl.col("q_conv")).otherwise(0.0).sum().alias("estoque_inicial"),
        pl.when(pl.col("tipo_operacao") == "1 - ENTRADA").then(pl.col("q_conv")).otherwise(0.0).sum().alias("entradas"),
        pl.when(pl.col("tipo_operacao") == "2 - SAIDAS").then(pl.col("q_conv").abs()).otherwise(0.0).sum().alias("saidas"),
        pl.when(pl.col("tipo_operacao") == "3 - ESTOQUE FINAL").then(pl.col("qtd").abs()).otherwise(0.0).sum().alias("estoque_final"),
        pl.col("entr_desac_anual").sum().alias("entradas_desacob"),
        pl.col("saldo_estoque_anual").drop_nulls().last().alias("saldo_final"),
        pl.when(pl.col("tipo_operacao") == "1 - ENTRADA").then(pl.col("preco_unit")).otherwise(None).mean().alias("pme"),
        pl.when(pl.col("tipo_operacao") == "2 - SAIDAS").then(pl.col("preco_unit")).otherwise(None).mean().alias("pms"),
    ).with_columns(
        (pl.col("estoque_inicial") + pl.col("entradas") + pl.col("entradas_desacob") - pl.col("estoque_final")).alias("saidas_calculadas"),
        (pl.col("estoque_final") - pl.col("saldo_final")).clip(lower_bound=0).alias("saidas_desacob"),
        (pl.col("saldo_final") - pl.col("estoque_final")).clip(lower_bound=0).alias("estoque_final_desacob"),
    ).rename({"id_agrupado": "id_agregado"})


def build_aba_periodos(mov_df: pl.DataFrame) -> pl.DataFrame:
    if mov_df.is_empty() or "periodo_inventario" not in mov_df.columns:
        return pl.DataFrame()

    return mov_df.group_by(["id_agrupado", "periodo_inventario"]).agg(
        pl.col("descr_padrao").drop_nulls().first().alias("descr_padrao"),
        pl.col("unid_ref").drop_nulls().first().alias("unid_ref"),
        pl.when(pl.col("tipo_operacao") == "0 - ESTOQUE INICIAL").then(pl.col("q_conv")).otherwise(0.0).sum().alias("estoque_inicial"),
        pl.when(pl.col("tipo_operacao") == "1 - ENTRADA").then(pl.col("q_conv")).otherwise(0.0).sum().alias("entradas"),
        pl.when(pl.col("tipo_operacao") == "2 - SAIDAS").then(pl.col("q_conv").abs()).otherwise(0.0).sum().alias("saidas"),
        pl.when(pl.col("tipo_operacao") == "3 - ESTOQUE FINAL").then(pl.col("qtd").abs()).otherwise(0.0).sum().alias("estoque_final"),
        pl.col("entr_desac_periodo").sum().alias("entradas_desacob"),
        pl.col("saldo_estoque_periodo").drop_nulls().last().alias("saldo_final"),
    ).with_columns(
        (pl.col("estoque_inicial") + pl.col("entradas") + pl.col("entradas_desacob") - pl.col("estoque_final")).alias("saidas_calculadas"),
        (pl.col("estoque_final") - pl.col("saldo_final")).clip(lower_bound=0).alias("saidas_desacob"),
        (pl.col("saldo_final") - pl.col("estoque_final")).clip(lower_bound=0).alias("estoque_final_desacob"),
        pl.col("periodo_inventario").alias("cod_per"),
    ).rename({"id_agrupado": "id_agregado"})
