from __future__ import annotations

from pathlib import Path

import polars as pl

from pipeline.references.loaders import resolve_reference_dataset, validate_reference_root


def _select_existing(df: pl.DataFrame, columns: list[str]) -> pl.DataFrame:
    existing = [col for col in columns if col in df.columns]
    return df.select(existing) if existing else pl.DataFrame()


def _concat_non_empty(frames: list[pl.DataFrame]) -> pl.DataFrame:
    valid = [df for df in frames if df is not None and not df.is_empty()]
    if not valid:
        return pl.DataFrame()
    common = set(valid[0].columns)
    for df in valid[1:]:
        common &= set(df.columns)
    ordered = [col for col in valid[0].columns if col in common]
    if not ordered:
        return pl.DataFrame()
    return pl.concat([df.select(ordered) for df in valid], how="vertical_relaxed")


def build_efd_produtos_base(itens_df: pl.DataFrame, base_info_df: pl.DataFrame) -> pl.DataFrame:
    if base_info_df is not None and not base_info_df.is_empty():
        preferred = _select_existing(
            base_info_df,
            ["cnpj", "codigo_produto_original", "descr_item", "descr_compl", "unid", "unid_ref", "ncm", "cest", "gtin_padrao", "embalagem", "conteudo"],
        )
        if not preferred.is_empty():
            return preferred.unique()
    if itens_df is None or itens_df.is_empty():
        return pl.DataFrame()
    fallback = _select_existing(
        itens_df,
        ["cnpj", "codigo_produto_original", "descr_item", "descr_compl", "unid", "ncm", "cest", "gtin_padrao"],
    )
    subset = [col for col in ["cnpj", "codigo_produto_original"] if col in fallback.columns]
    return fallback.unique(subset=subset) if subset else fallback.unique()


def build_efd_documentos_base(c170_df: pl.DataFrame, nfe_df: pl.DataFrame, nfce_df: pl.DataFrame, itens_df: pl.DataFrame) -> pl.DataFrame:
    columns = ["cnpj", "chave_doc", "dt_doc", "dt_e_s", "ind_oper", "ind_emit", "cod_part", "serie", "num_doc", "modelo"]
    docs = _concat_non_empty([
        _select_existing(c170_df, columns),
        _select_existing(nfe_df, columns),
        _select_existing(nfce_df, columns),
        _select_existing(itens_df, columns),
    ])
    subset = [col for col in ["cnpj", "chave_doc"] if col in docs.columns]
    return docs.unique(subset=subset) if subset else docs.unique()


def build_efd_itens_base(itens_df: pl.DataFrame, c170_df: pl.DataFrame) -> pl.DataFrame:
    if itens_df is not None and not itens_df.is_empty():
        return itens_df
    return c170_df if c170_df is not None else pl.DataFrame()


def build_efd_inventario_base(bloco_h_df: pl.DataFrame) -> pl.DataFrame:
    return bloco_h_df if bloco_h_df is not None else pl.DataFrame()


def build_sitafe_nota_item_base(itens_df: pl.DataFrame) -> pl.DataFrame:
    if itens_df is None or itens_df.is_empty():
        return pl.DataFrame()
    df = _select_existing(
        itens_df,
        ["cnpj", "chave_doc", "codigo_produto_original", "co_sefin_final", "co_sefin_agr", "ncm", "cest", "vl_item", "dt_doc", "dt_e_s"],
    )
    subset = [col for col in ["cnpj", "chave_doc", "codigo_produto_original"] if col in df.columns]
    return df.unique(subset=subset) if subset else df.unique()


def build_dim_fiscal_sefin_base(reference_root: Path, itens_df: pl.DataFrame) -> pl.DataFrame:
    refs_status = validate_reference_root(reference_root)
    frames: list[pl.DataFrame] = []
    if all(refs_status.values()):
        for name in ["sitafe_cest_ncm", "sitafe_cest", "sitafe_ncm"]:
            ref_df = resolve_reference_dataset(reference_root, name).read()
            if not ref_df.is_empty():
                frames.append(ref_df.with_columns(pl.lit(name).alias("source_reference")))
    if frames:
        merged = _concat_non_empty(frames)
        if not merged.is_empty():
            return merged.unique()
    if itens_df is None or itens_df.is_empty():
        return pl.DataFrame()
    derived = _select_existing(
        itens_df,
        ["ncm", "cest", "co_sefin_final", "co_sefin_agr", "it_pc_interna", "it_in_st", "it_pc_mva", "it_in_mva_ajustado"],
    )
    subset = [col for col in ["ncm", "cest", "co_sefin_final", "co_sefin_agr"] if col in derived.columns]
    return derived.unique(subset=subset) if subset else derived.unique()


def build_diagnostico_conversao_unidade_base(itens_df: pl.DataFrame, produtos_df: pl.DataFrame | None = None) -> pl.DataFrame:
    if itens_df is None or itens_df.is_empty():
        return pl.DataFrame()
    df = itens_df
    if produtos_df is not None and not produtos_df.is_empty() and "id_agrupado" in itens_df.columns and "id_agrupado" in produtos_df.columns:
        ref_cols = [col for col in ["id_agrupado", "unid_ref"] if col in produtos_df.columns]
        if ref_cols:
            df = df.join(produtos_df.select(ref_cols).unique(subset=["id_agrupado"]), on="id_agrupado", how="left")
    selected = _select_existing(df, ["cnpj", "codigo_produto_original", "id_agrupado", "unid", "unid_ref"])
    if selected.is_empty() or "unid" not in selected.columns:
        return selected
    if "unid_ref" not in selected.columns:
        selected = selected.with_columns(pl.lit(None, dtype=pl.Utf8).alias("unid_ref"))
    selected = selected.with_columns(
        pl.when(pl.col("unid_ref").is_null() | (pl.col("unid_ref") == ""))
        .then(False)
        .otherwise(pl.col("unid") != pl.col("unid_ref"))
        .alias("necessita_conversao"),
        pl.when(pl.col("unid_ref").is_null() | (pl.col("unid_ref") == ""))
        .then(pl.lit("sem_unid_ref"))
        .when(pl.col("unid") != pl.col("unid_ref"))
        .then(pl.lit("unidade_divergente"))
        .otherwise(pl.lit("unidade_compativel"))
        .alias("evidencia"),
    )
    subset = [col for col in ["cnpj", "codigo_produto_original", "unid", "unid_ref"] if col in selected.columns]
    return selected.unique(subset=subset) if subset else selected.unique()


def build_priority_mdc_base_from_existing(
    *,
    itens_df: pl.DataFrame,
    c170_df: pl.DataFrame,
    nfe_df: pl.DataFrame,
    nfce_df: pl.DataFrame,
    bloco_h_df: pl.DataFrame,
    base_info_df: pl.DataFrame,
    reference_root: Path,
    produtos_df: pl.DataFrame | None = None,
) -> dict[str, pl.DataFrame]:
    return {
        "efd_produtos_base": build_efd_produtos_base(itens_df, base_info_df),
        "efd_documentos_base": build_efd_documentos_base(c170_df, nfe_df, nfce_df, itens_df),
        "efd_itens_base": build_efd_itens_base(itens_df, c170_df),
        "efd_inventario_base": build_efd_inventario_base(bloco_h_df),
        "sitafe_nota_item_base": build_sitafe_nota_item_base(itens_df),
        "dim_fiscal_sefin_base": build_dim_fiscal_sefin_base(reference_root, itens_df),
        "diagnostico_conversao_unidade_base": build_diagnostico_conversao_unidade_base(itens_df, produtos_df=produtos_df),
    }
