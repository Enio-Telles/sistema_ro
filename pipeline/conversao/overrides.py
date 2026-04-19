from __future__ import annotations

import polars as pl


def apply_manual_overrides(fatores_df: pl.DataFrame, overrides_df: pl.DataFrame | None) -> pl.DataFrame:
    """Aplica overrides manuais de conversão com granularidade correta.

    Estratégia de join (prioridade decrescente):

    1. **Específico** — override por ``id_agrupado + unid`` (quando ``unid``
       está presente em *overrides_df* e é não-nulo).  Aplica apenas à
       unidade exata, evitando contaminar outras unidades do mesmo
       agrupamento.

    2. **Geral** — override por ``id_agrupado`` apenas (quando a linha de
       override não tem ``unid`` ou ``unid`` é nulo).  Aplica a todas as
       unidades do agrupamento que não receberam override específico.

    3. **Sem override** — linha de fatores não tem match em nenhum dos
       dois passos anteriores.

    Campos produzidos (adicionados/modificados):

    - ``unid_ref``, ``fator``, ``tipo_fator``, ``confianca_fator``,
      ``fonte_fator`` — substituídos quando override é aplicado.
    - ``override_aplicado`` (bool) — ``True`` quando qualquer override foi
      aplicado.
    - ``override_resolution_key`` (str) — ``"id_agrupado+unid"``,
      ``"id_agrupado"`` ou ``"nenhum"``.
    - ``justificativa_fator`` — copiado do override quando disponível.
    """
    if fatores_df.is_empty() or overrides_df is None or overrides_df.is_empty():
        return fatores_df

    if "id_agrupado" not in overrides_df.columns:
        return fatores_df

    payload_cols = [c for c in ["unid_ref_manual", "fator_manual", "justificativa_fator"] if c in overrides_df.columns]

    has_unid_in_overrides = "unid" in overrides_df.columns

    # --------------------------------------------------------------------------
    # Passo 1 — overrides específicos por id_agrupado + unid
    # --------------------------------------------------------------------------
    if has_unid_in_overrides:
        specific = (
            overrides_df
            .filter(pl.col("unid").is_not_null() & (pl.col("unid").cast(pl.Utf8, strict=False).str.strip_chars() != ""))
            .select(["id_agrupado", "unid"] + payload_cols)
            .unique(subset=["id_agrupado", "unid"])
            .rename({c: f"{c}__spec" for c in payload_cols})
        )
    else:
        specific = pl.DataFrame()

    # --------------------------------------------------------------------------
    # Passo 2 — overrides gerais por id_agrupado (sem unid ou unid nulo)
    # --------------------------------------------------------------------------
    if has_unid_in_overrides:
        general = (
            overrides_df
            .filter(pl.col("unid").is_null() | (pl.col("unid").cast(pl.Utf8, strict=False).str.strip_chars() == ""))
            .select(["id_agrupado"] + payload_cols)
            .unique(subset=["id_agrupado"])
            .rename({c: f"{c}__gen" for c in payload_cols})
        )
    else:
        # Comportamento legado: todas as linhas são tratadas como override geral
        general = (
            overrides_df
            .select(["id_agrupado"] + payload_cols)
            .unique(subset=["id_agrupado"])
            .rename({c: f"{c}__gen" for c in payload_cols})
        )

    # --------------------------------------------------------------------------
    # Aplicar joins
    # --------------------------------------------------------------------------
    result = fatores_df

    if not specific.is_empty() and "unid" in result.columns:
        result = result.join(specific, on=["id_agrupado", "unid"], how="left")
    else:
        for c in payload_cols:
            result = result.with_columns(pl.lit(None).cast(pl.Utf8).alias(f"{c}__spec"))

    if not general.is_empty():
        result = result.join(general, on="id_agrupado", how="left")
    else:
        for c in payload_cols:
            result = result.with_columns(pl.lit(None).cast(pl.Utf8).alias(f"{c}__gen"))

    # --------------------------------------------------------------------------
    # Mesclar: específico > geral > original
    # --------------------------------------------------------------------------
    def _coalesce_override(col: str) -> pl.Expr:
        spec = f"{col}__spec"
        gen = f"{col}__gen"
        if spec in result.columns and gen in result.columns:
            return (
                pl.when(pl.col(spec).is_not_null()).then(pl.col(spec))
                .when(pl.col(gen).is_not_null()).then(pl.col(gen))
                .otherwise(None)
                .alias(f"{col}__resolved")
            )
        if spec in result.columns:
            return pl.col(spec).alias(f"{col}__resolved")
        if gen in result.columns:
            return pl.col(gen).alias(f"{col}__resolved")
        return pl.lit(None).cast(pl.Utf8).alias(f"{col}__resolved")

    resolve_exprs = [_coalesce_override(c) for c in payload_cols]
    result = result.with_columns(resolve_exprs)

    # Determinar chave de resolução usada
    spec_active = "fator_manual__spec" in result.columns
    gen_active = "fator_manual__gen" in result.columns
    fator_resolved_col = "fator_manual__resolved" if "fator_manual" in payload_cols else None

    if fator_resolved_col:
        result = result.with_columns(
            pl.when(spec_active and pl.col("fator_manual__spec").is_not_null())
            .then(pl.lit("id_agrupado+unid"))
            .when(gen_active and pl.col("fator_manual__gen").is_not_null())
            .then(pl.lit("id_agrupado"))
            .otherwise(pl.lit("nenhum"))
            .alias("override_resolution_key"),
            (pl.col(fator_resolved_col).is_not_null()).alias("override_aplicado"),
        )
    else:
        result = result.with_columns(
            pl.lit("nenhum").alias("override_resolution_key"),
            pl.lit(False).alias("override_aplicado"),
        )

    # Aplicar valores resolvidos nos campos operacionais
    fator_col = "fator_manual__resolved" if "fator_manual" in payload_cols else None
    unid_col = "unid_ref_manual__resolved" if "unid_ref_manual" in payload_cols else None
    just_col = "justificativa_fator__resolved" if "justificativa_fator" in payload_cols else None

    exprs = []
    if unid_col and unid_col in result.columns:
        exprs.append(
            pl.when(pl.col(unid_col).is_not_null())
            .then(pl.col(unid_col))
            .otherwise(pl.col("unid_ref"))
            .alias("unid_ref")
        )
    if fator_col and fator_col in result.columns:
        exprs.append(
            pl.when(pl.col(fator_col).is_not_null())
            .then(pl.col(fator_col).cast(pl.Float64, strict=False))
            .otherwise(pl.col("fator"))
            .alias("fator")
        )
        exprs.append(
            pl.when(pl.col(fator_col).is_not_null())
            .then(pl.lit("manual"))
            .otherwise(pl.col("tipo_fator"))
            .alias("tipo_fator")
        )
        exprs.append(
            pl.when(pl.col(fator_col).is_not_null())
            .then(pl.lit(1.0))
            .otherwise(pl.col("confianca_fator"))
            .alias("confianca_fator")
        )
        exprs.append(
            pl.when(pl.col(fator_col).is_not_null())
            .then(pl.lit("override_manual"))
            .otherwise(pl.col("fonte_fator"))
            .alias("fonte_fator")
        )
    if just_col and just_col in result.columns and "justificativa_fator" not in fatores_df.columns:
        exprs.append(pl.col(just_col).alias("justificativa_fator"))

    if exprs:
        result = result.with_columns(exprs)

    final_sync_exprs = []
    final_map = [
        ("unid_ref", "unid_ref_final"),
        ("fator", "fator_final"),
        ("tipo_fator", "tipo_fator_final"),
        ("fonte_fator", "fonte_fator_final"),
        ("confianca_fator", "confianca_fator_final"),
    ]
    for src, dst in final_map:
        if src in result.columns:
            final_sync_exprs.append(pl.col(src).alias(dst))

    final_sync_exprs.append(
        pl.when(pl.col("override_aplicado"))
        .then(pl.format("override_manual:{}", pl.col("override_resolution_key")))
        .otherwise(pl.lit("heuristico"))
        .alias("caminho_decisao_final")
    )
    result = result.with_columns(final_sync_exprs)

    # Limpar colunas temporárias
    tmp_cols = (
        [f"{c}__spec" for c in payload_cols]
        + [f"{c}__gen" for c in payload_cols]
        + [f"{c}__resolved" for c in payload_cols]
    )
    result = result.drop([c for c in tmp_cols if c in result.columns])

    return result


def build_override_log(fatores_df: pl.DataFrame) -> pl.DataFrame:
    """Retorna linhas onde override manual foi aplicado, para persistência de auditoria."""
    if fatores_df.is_empty() or "override_aplicado" not in fatores_df.columns:
        # fallback legado: filtrar por tipo_fator
        if "tipo_fator" not in fatores_df.columns:
            return pl.DataFrame()
        return fatores_df.filter(pl.col("tipo_fator") == "manual").select(
            [c for c in ["id_agrupado", "unid_ref", "fator", "tipo_fator", "fonte_fator", "justificativa_fator"] if c in fatores_df.columns]
        )
    return fatores_df.filter(pl.col("override_aplicado")).select(
        [c for c in [
            "id_agrupado", "unid_ref", "fator", "tipo_fator", "fonte_fator",
            "fator_heuristico", "fator_final", "justificativa_fator",
            "override_aplicado", "override_resolution_key", "caminho_decisao_final",
        ] if c in fatores_df.columns]
    )
