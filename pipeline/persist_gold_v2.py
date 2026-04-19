from __future__ import annotations

import hashlib
import uuid
from datetime import datetime, timezone
from typing import Any

import polars as pl

from backend.app.services.datasets import dataset_ref
from pipeline.io.parquet_store import save_parquet


GOLD_DATASET_NAMES_V2 = {
    "produtos_agrupados": "gold",
    "id_agrupados": "gold",
    "produtos_final": "gold",
    "item_unidades": "gold",
    "fatores_conversao": "gold",
    "log_conversao_overrides": "gold",
    "log_conversao_anomalias": "gold",
    "mov_estoque": "gold",
    "aba_mensal": "gold",
    "aba_anual": "gold",
    "aba_periodos": "gold",
    "estoque_resumo": "gold",
    "estoque_alertas": "gold",
}


def _generate_input_hash(outputs: dict[str, pl.DataFrame]) -> str:
    """Gera um hash determinístico a partir do shape e amostra de dados dos DataFrames.

    Não é um hash criptográfico de conteúdo completo (evita custo de
    serialização de frames grandes), mas é suficiente para detectar
    variações de shape, colunas e primeiros/últimos valores — útil para
    rastrear se dois runs receberam os mesmos inputs.
    """
    hasher = hashlib.sha256()
    for name in sorted(outputs):
        df = outputs[name]
        sig = f"{name}|rows={df.height}|cols={df.width}|schema={df.schema}"
        if df.height > 0:
            sig += f"|head0={df.row(0)}|tail0={df.row(-1)}"
        hasher.update(sig.encode("utf-8"))
    return hasher.hexdigest()[:16]


def _inject_run_metadata(
    df: pl.DataFrame,
    *,
    run_id: str,
    input_hash: str,
    data_processamento: str,
) -> pl.DataFrame:
    """Injeta colunas de rastreabilidade no DataFrame antes da persistência.

    As colunas são adicionadas apenas se ainda não existirem, preservando
    valores já presentes (e.g. se o caller já os materializou upstream).

    Colunas injetadas
    -----------------
    ``__run_id__``
        Identificador único do run de processamento.
    ``__input_hash__``
        Hash resumido dos inputs do pipeline.
    ``__data_processamento__``
        Timestamp ISO-8601 do momento de persistência (UTC).
    """
    if df.is_empty():
        return df
    exprs = []
    if "__run_id__" not in df.columns:
        exprs.append(pl.lit(run_id).alias("__run_id__"))
    if "__input_hash__" not in df.columns:
        exprs.append(pl.lit(input_hash).alias("__input_hash__"))
    if "__data_processamento__" not in df.columns:
        exprs.append(pl.lit(data_processamento).alias("__data_processamento__"))
    if not exprs:
        return df
    return df.with_columns(exprs)


def persist_gold_outputs_v2(
    cnpj: str,
    outputs: dict[str, pl.DataFrame],
    *,
    run_id: str | None = None,
    input_hash: str | None = None,
    data_processamento: str | None = None,
    pipeline_version: str | None = None,
    schema_version: str = "v2.0",
    upstream_datasets: list[str] | None = None,
    manual_assets_used: list[str] | None = None,
) -> dict[str, Any]:
    """Persiste os outputs da trilha gold com metadados operacionais de rastreabilidade.

    Parâmetros
    ----------
    cnpj:
        CNPJ da empresa auditada (8 ou 14 dígitos, sem formatação).
    outputs:
        Dicionário ``{nome_dataset: DataFrame}`` produzido por ``run_gold_v20``.
    run_id:
        Identificador único desta execução do pipeline.  Gerado
        automaticamente como UUID4 se não informado.
    input_hash:
        Hash resumido dos inputs.  Calculado automaticamente a partir dos
        shapes e amostras dos DataFrames se não informado.
    data_processamento:
        Timestamp ISO-8601 (UTC) do momento de persistência.  Usa
        ``datetime.now(UTC)`` se não informado.

    Retorno
    -------
    Dicionário ``{nome_dataset: caminho_parquet}`` com os caminhos salvos, mais
    a chave especial ``"__run_metadata__"`` com os valores efetivos de
    ``run_id``, ``input_hash`` e ``data_processamento``.
    """
    effective_run_id = run_id or str(uuid.uuid4())
    effective_hash   = input_hash or _generate_input_hash(outputs)
    effective_dt     = data_processamento or datetime.now(timezone.utc).isoformat()
    effective_pipeline_version = pipeline_version or "unknown"
    effective_upstream = upstream_datasets or ["mdc_base", "silver"]
    effective_manual_assets = manual_assets_used or []

    saved: dict[str, Any] = {}

    for name, df in outputs.items():
        if name not in GOLD_DATASET_NAMES_V2:
            continue
        ref = dataset_ref(cnpj=cnpj, layer=GOLD_DATASET_NAMES_V2[name], name=name)

        meta = {
            "dataset_id":        f"{name}_{GOLD_DATASET_NAMES_V2[name]}",
            "layer":             GOLD_DATASET_NAMES_V2[name],
            "schema_version":    schema_version,
            "pipeline_version":  effective_pipeline_version,
            "row_count":         df.height,
            "cnpj":              cnpj,
            "upstream_datasets": effective_upstream,
            "manual_assets_used": effective_manual_assets,
            # --- metadados operacionais C6 ---
            "run_id":              effective_run_id,
            "input_hash":          effective_hash,
            "data_processamento":  effective_dt,
        }

        df_with_meta = _inject_run_metadata(
            df,
            run_id=effective_run_id,
            input_hash=effective_hash,
            data_processamento=effective_dt,
        )

        save_parquet(df_with_meta, ref, metadata=meta)
        saved[name] = str(ref.path)

    # Expõe metadados efetivos para o caller (logging, auditoria, testes)
    saved["__run_metadata__"] = {
        "run_id":             effective_run_id,
        "input_hash":         effective_hash,
        "data_processamento": effective_dt,
        "pipeline_version":   effective_pipeline_version,
        "schema_version":     schema_version,
        "upstream_datasets":  effective_upstream,
        "manual_assets_used": effective_manual_assets,
    }

    return saved
