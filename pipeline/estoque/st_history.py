"""
Enriquecimento temporal de Substituição Tributária via sitafe_produto_sefin_aux.

Fornece funções que, dado um DataFrame com (co_sefin_agr, ano) ou (co_sefin_agr, ano, mes),
retornam os campos ST histórico com precisão de vigência:
- __tem_st__: flag corrigido pelo cruzamento temporal
- st_text:    texto descritivo dos períodos ST intersectados
- aliq_interna_sefin: alíquota interna vigente no período (prioridade sobre mov_estoque)

Essas funções são usadas por build_aba_anual_v4 e build_aba_mensal_v4 antes do cálculo
do ICMS, para garantir que __tem_st__ reflita a situação histórica real do produto.
"""
from __future__ import annotations

import polars as pl


_DATE_FMT = "%Y%m%d"
_OPEN_END = pl.lit("20991231").str.strptime(pl.Date, _DATE_FMT)


def _parse_sitafe_aux(sitafe_aux_df: pl.DataFrame) -> pl.DataFrame:
    required = {"it_co_sefin", "it_da_inicio", "it_da_final", "it_in_st", "it_pc_interna"}
    if not required.issubset(set(sitafe_aux_df.columns)):
        return pl.DataFrame()

    return sitafe_aux_df.select(list(required)).with_columns(
        pl.col("it_co_sefin").cast(pl.Utf8, strict=False).alias("it_co_sefin"),
        pl.col("it_da_inicio").cast(pl.Utf8, strict=False).str.strptime(pl.Date, _DATE_FMT, strict=False).alias("it_da_inicio"),
        pl.col("it_da_final").cast(pl.Utf8, strict=False).str.strptime(pl.Date, _DATE_FMT, strict=False).fill_null(_OPEN_END).alias("it_da_final"),
        pl.col("it_in_st").cast(pl.Utf8, strict=False).str.to_uppercase().alias("it_in_st"),
        pl.col("it_pc_interna").cast(pl.Float64, strict=False).alias("it_pc_interna"),
    )


def _period_text(da_inicio: pl.Expr, da_final: pl.Expr) -> pl.Expr:
    return da_inicio.dt.strftime("%m/%Y") + pl.lit("-") + da_final.dt.strftime("%m/%Y")


def resolve_st_anual(
    co_sefin_ano_df: pl.DataFrame,
    sitafe_aux_df: pl.DataFrame,
    *,
    sefin_col: str = "co_sefin_agr",
    ano_col: str = "ano",
) -> pl.DataFrame:
    """
    Dado um DataFrame com [co_sefin_agr, ano], retorna enriquecimento ST com:
    - __tem_st__:        True se algum período SITAFE com ST=S intersecta o ano
    - __st_text__:       texto "ST (mm/aaaa-mm/aaaa; ...)" ou "SEM ST"
    - __aliq_interna__:  alíquota interna do último período SITAFE do ano (ou null)

    Retorna um df com as mesmas chaves [sefin_col, ano_col] + os 3 campos acima.
    Pode ser joined de volta ao DataFrame agrupado pelo chamador.
    """
    aux = _parse_sitafe_aux(sitafe_aux_df)
    if aux.is_empty():
        return pl.DataFrame()

    keys = co_sefin_ano_df.select([sefin_col, ano_col]).unique()

    df = keys.with_columns(
        pl.date(pl.col(ano_col), 1, 1).alias("__ano_inicio__"),
        pl.date(pl.col(ano_col), 12, 31).alias("__ano_fim__"),
    )

    crossed = df.join(
        aux.rename({"it_co_sefin": sefin_col}),
        on=sefin_col,
        how="left",
        suffix="_sefin",
    ).filter(
        pl.col("it_da_inicio").is_null()
        | (
            (pl.col("it_da_inicio") <= pl.col("__ano_fim__"))
            & (pl.col("it_da_final") >= pl.col("__ano_inicio__"))
        )
    )

    return (
        crossed.group_by([sefin_col, ano_col]).agg(
            (pl.col("it_in_st") == "S").any().alias("__tem_st__"),
            pl.when((pl.col("it_in_st") == "S") & pl.col("it_da_inicio").is_not_null())
            .then(_period_text(pl.col("it_da_inicio"), pl.col("it_da_final")))
            .otherwise(None)
            .drop_nulls()
            .sort()
            .alias("__st_periodos__"),
            pl.col("it_pc_interna").filter(pl.col("it_da_inicio").is_not_null()).last().alias("__aliq_interna__"),
        )
        .with_columns(
            pl.when(pl.col("__tem_st__") & (pl.col("__st_periodos__").list.len() > 0))
            .then(pl.lit("ST (") + pl.col("__st_periodos__").list.join("; ") + pl.lit(")"))
            .when(pl.col("__tem_st__"))
            .then(pl.lit("ST"))
            .otherwise(pl.lit("SEM ST"))
            .alias("__st_text__"),
        )
        .drop("__st_periodos__")
    )


def resolve_st_mensal(
    co_sefin_mes_df: pl.DataFrame,
    sitafe_aux_df: pl.DataFrame,
    *,
    sefin_col: str = "co_sefin_agr",
    ano_col: str = "ano",
    mes_col: str = "mes",
) -> pl.DataFrame:
    """
    Dado um DataFrame com [co_sefin_agr, ano, mes], retorna enriquecimento ST mensal.
    Mesma estrutura que resolve_st_anual, com chave adicional mes_col.
    """
    aux = _parse_sitafe_aux(sitafe_aux_df)
    if aux.is_empty():
        return pl.DataFrame()

    keys = co_sefin_mes_df.select([sefin_col, ano_col, mes_col]).unique()

    df = keys.with_columns(
        pl.date(pl.col(ano_col), pl.col(mes_col), 1).alias("__mes_inicio__"),
        pl.date(pl.col(ano_col), pl.col(mes_col), 1)
        .dt.offset_by("1mo")
        .dt.offset_by("-1d")
        .alias("__mes_fim__"),
    )

    crossed = df.join(
        aux.rename({"it_co_sefin": sefin_col}),
        on=sefin_col,
        how="left",
        suffix="_sefin",
    ).filter(
        pl.col("it_da_inicio").is_null()
        | (
            (pl.col("it_da_inicio") <= pl.col("__mes_fim__"))
            & (pl.col("it_da_final") >= pl.col("__mes_inicio__"))
        )
    )

    return (
        crossed.group_by([sefin_col, ano_col, mes_col]).agg(
            (pl.col("it_in_st") == "S").any().alias("__tem_st__"),
            pl.when((pl.col("it_in_st") == "S") & pl.col("it_da_inicio").is_not_null())
            .then(_period_text(pl.col("it_da_inicio"), pl.col("it_da_final")))
            .otherwise(None)
            .drop_nulls()
            .sort()
            .alias("__st_periodos__"),
            pl.col("it_pc_interna").filter(pl.col("it_da_inicio").is_not_null()).last().alias("__aliq_interna__"),
        )
        .with_columns(
            pl.when(pl.col("__tem_st__") & (pl.col("__st_periodos__").list.len() > 0))
            .then(pl.lit("ST (") + pl.col("__st_periodos__").list.join("; ") + pl.lit(")"))
            .when(pl.col("__tem_st__"))
            .then(pl.lit("ST"))
            .otherwise(pl.lit("SEM ST"))
            .alias("__st_text__"),
        )
        .drop("__st_periodos__")
    )
