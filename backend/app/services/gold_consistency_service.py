from __future__ import annotations

import polars as pl

from backend.app.services.datasets import dataset_ref
from pipeline.io.parquet_store import load_parquet


REQUIRED_COLS = {
    "mov_estoque": ["id_agrupado", "tipo_operacao", "qtd", "q_conv"],
    "aba_mensal": ["id_agregado", "ano", "mes", "ST", "ICMS_entr_desacob"],
    "aba_anual": ["id_agregado", "ano", "ST", "ICMS_saidas_desac", "ICMS_estoque_desac"],
    "aba_periodos": [
        "id_agregado",
        "cod_per",
        "data_inicio",
        "data_fim",
        "periodo_label",
        "ST",
        "ICMS_saidas_desac",
        "ICMS_estoque_desac",
    ],
}


def _load_gold(cnpj: str, name: str) -> pl.DataFrame:
    ref = dataset_ref(cnpj=cnpj, layer="gold", name=name)
    df = load_parquet(ref)
    return df if df is not None else pl.DataFrame()


def _validate_required(df: pl.DataFrame, name: str) -> dict:
    missing = [col for col in REQUIRED_COLS[name] if col not in df.columns]
    return {
        "dataset": name,
        "rows": df.height,
        "missing_columns": missing,
        "ok": not missing,
    }


def _id_set(df: pl.DataFrame, col: str) -> set[str]:
    if df.is_empty() or col not in df.columns:
        return set()
    values = df.select(pl.col(col).cast(pl.Utf8, strict=False).fill_null(""))
    return {row[0] for row in values.iter_rows() if row[0]}


def _inventory_contract(mov_df: pl.DataFrame) -> dict:
    if mov_df.is_empty() or "tipo_operacao" not in mov_df.columns:
        return {
            "linhas_estoque_inicial": 0,
            "linhas_estoque_final": 0,
            "linhas_estoque_inicial_sem_periodo": 0,
            "linhas_estoque_final_sem_periodo": 0,
            "linhas_estoque_final_sem_qtd_decl_final_audit": 0,
            "linhas_estoque_final_com_q_conv_nao_zero": 0,
            "ok": True,
        }

    estoque_inicial = mov_df.filter(pl.col("tipo_operacao") == "0 - ESTOQUE INICIAL")
    estoque_final = mov_df.filter(pl.col("tipo_operacao") == "3 - ESTOQUE FINAL")

    inicial_sem_periodo = (
        estoque_inicial.height
        if "periodo_inventario" not in mov_df.columns
        else estoque_inicial.filter(pl.col("periodo_inventario").is_null()).height
    )
    final_sem_periodo = (
        estoque_final.height
        if "periodo_inventario" not in mov_df.columns
        else estoque_final.filter(pl.col("periodo_inventario").is_null()).height
    )
    final_sem_qtd_decl = (
        estoque_final.height
        if "__qtd_decl_final_audit__" not in mov_df.columns
        else estoque_final.filter(pl.col("__qtd_decl_final_audit__").is_null()).height
    )
    final_q_conv_nao_zero = (
        0
        if "q_conv" not in mov_df.columns
        else estoque_final.filter(pl.col("q_conv").fill_null(0.0) != 0).height
    )

    ok = (
        inicial_sem_periodo == 0
        and final_sem_periodo == 0
        and final_sem_qtd_decl == 0
        and final_q_conv_nao_zero == 0
    )

    return {
        "linhas_estoque_inicial": estoque_inicial.height,
        "linhas_estoque_final": estoque_final.height,
        "linhas_estoque_inicial_sem_periodo": inicial_sem_periodo,
        "linhas_estoque_final_sem_periodo": final_sem_periodo,
        "linhas_estoque_final_sem_qtd_decl_final_audit": final_sem_qtd_decl,
        "linhas_estoque_final_com_q_conv_nao_zero": final_q_conv_nao_zero,
        "ok": ok,
    }


def _periodos_contract(periodos_df: pl.DataFrame) -> dict:
    if periodos_df.is_empty():
        return {
            "linhas_sem_data_inicio": 0,
            "linhas_sem_data_fim": 0,
            "linhas_sem_periodo_label": 0,
            "linhas_com_janela_invertida": 0,
            "chaves_duplicadas": 0,
            "ok": True,
        }

    sem_data_inicio = (
        periodos_df.height
        if "data_inicio" not in periodos_df.columns
        else periodos_df.filter(pl.col("data_inicio").is_null()).height
    )
    sem_data_fim = (
        periodos_df.height
        if "data_fim" not in periodos_df.columns
        else periodos_df.filter(pl.col("data_fim").is_null()).height
    )
    sem_periodo_label = (
        periodos_df.height
        if "periodo_label" not in periodos_df.columns
        else periodos_df.filter(pl.col("periodo_label").is_null()).height
    )

    janela_invertida = 0
    if {"data_inicio", "data_fim"}.issubset(periodos_df.columns):
        janela_invertida = periodos_df.filter(
            pl.col("data_inicio").is_not_null()
            & pl.col("data_fim").is_not_null()
            & (pl.col("data_inicio") > pl.col("data_fim"))
        ).height

    chaves_duplicadas = 0
    if {"id_agregado", "cod_per"}.issubset(periodos_df.columns):
        chaves_duplicadas = (
            periodos_df.group_by(["id_agregado", "cod_per"])
            .len()
            .filter(pl.col("len") > 1)
            .height
        )

    ok = (
        sem_data_inicio == 0
        and sem_data_fim == 0
        and sem_periodo_label == 0
        and janela_invertida == 0
        and chaves_duplicadas == 0
    )

    return {
        "linhas_sem_data_inicio": sem_data_inicio,
        "linhas_sem_data_fim": sem_data_fim,
        "linhas_sem_periodo_label": sem_periodo_label,
        "linhas_com_janela_invertida": janela_invertida,
        "chaves_duplicadas": chaves_duplicadas,
        "ok": ok,
    }


def get_gold_consistency(cnpj: str) -> dict:
    mov_df = _load_gold(cnpj, "mov_estoque")
    mensal_df = _load_gold(cnpj, "aba_mensal")
    anual_df = _load_gold(cnpj, "aba_anual")
    periodos_df = _load_gold(cnpj, "aba_periodos")

    validations = {
        "mov_estoque": _validate_required(mov_df, "mov_estoque"),
        "aba_mensal": _validate_required(mensal_df, "aba_mensal"),
        "aba_anual": _validate_required(anual_df, "aba_anual"),
        "aba_periodos": _validate_required(periodos_df, "aba_periodos"),
    }

    mov_ids = _id_set(mov_df, "id_agrupado")
    mensal_ids = _id_set(mensal_df, "id_agregado")
    anual_ids = _id_set(anual_df, "id_agregado")
    periodos_ids = _id_set(periodos_df, "id_agregado")

    coherence = {
        "ids_mov_estoque": len(mov_ids),
        "ids_aba_mensal": len(mensal_ids),
        "ids_aba_anual": len(anual_ids),
        "ids_aba_periodos": len(periodos_ids),
        "ids_mensal_fora_mov": len(mensal_ids - mov_ids),
        "ids_anual_fora_mov": len(anual_ids - mov_ids),
        "ids_periodos_fora_mov": len(periodos_ids - mov_ids),
        "movimentos_sem_periodo": 0,
        "movimentos_com_saldo_negativo": 0,
    }

    if not mov_df.is_empty():
        if "periodo_inventario" in mov_df.columns:
            coherence["movimentos_sem_periodo"] = mov_df.filter(pl.col("periodo_inventario").is_null()).height
        if "saldo_estoque_anual" in mov_df.columns:
            coherence["movimentos_com_saldo_negativo"] = mov_df.filter(pl.col("saldo_estoque_anual") < 0).height

    inventory_contract = _inventory_contract(mov_df)
    periodos_contract = _periodos_contract(periodos_df)

    fiscal = {
        "linhas_st_mensal": 0,
        "linhas_st_anual": 0,
        "linhas_st_periodos": 0,
        "icms_entr_desacob_total": 0.0,
        "icms_saidas_desac_total": 0.0,
        "icms_estoque_desac_total": 0.0,
    }

    if not mensal_df.is_empty() and "ST" in mensal_df.columns:
        fiscal["linhas_st_mensal"] = mensal_df.filter(pl.col("ST") == "ST").height
        if "ICMS_entr_desacob" in mensal_df.columns:
            fiscal["icms_entr_desacob_total"] = float(mensal_df["ICMS_entr_desacob"].sum())
    if not anual_df.is_empty() and "ST" in anual_df.columns:
        fiscal["linhas_st_anual"] = anual_df.filter(pl.col("ST") == "ST").height
        if "ICMS_saidas_desac" in anual_df.columns:
            fiscal["icms_saidas_desac_total"] += float(anual_df["ICMS_saidas_desac"].sum())
        if "ICMS_estoque_desac" in anual_df.columns:
            fiscal["icms_estoque_desac_total"] += float(anual_df["ICMS_estoque_desac"].sum())
    if not periodos_df.is_empty() and "ST" in periodos_df.columns:
        fiscal["linhas_st_periodos"] = periodos_df.filter(pl.col("ST") == "ST").height
        if "ICMS_saidas_desac" in periodos_df.columns:
            fiscal["icms_saidas_desac_total"] += float(periodos_df["ICMS_saidas_desac"].sum())
        if "ICMS_estoque_desac" in periodos_df.columns:
            fiscal["icms_estoque_desac_total"] += float(periodos_df["ICMS_estoque_desac"].sum())

    ok = (
        all(v["ok"] for v in validations.values())
        and coherence["ids_mensal_fora_mov"] == 0
        and coherence["ids_anual_fora_mov"] == 0
        and coherence["ids_periodos_fora_mov"] == 0
        and coherence["movimentos_com_saldo_negativo"] == 0
        and inventory_contract["ok"]
        and periodos_contract["ok"]
    )

    return {
        "cnpj": cnpj,
        "ok": ok,
        "validations": validations,
        "coherence": coherence,
        "inventory_contract": inventory_contract,
        "periodos_contract": periodos_contract,
        "fiscal": fiscal,
    }
