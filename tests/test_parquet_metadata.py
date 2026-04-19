import polars as pl

from backend.app import config
from backend.app.config import Settings
from backend.app.services.datasets import dataset_ref
from pipeline.io.parquet_store import save_parquet, load_parquet_metadata, load_parquet
from pipeline.persist_gold_v2 import persist_gold_outputs_v2


def test_save_and_load_metadata(tmp_path):
    # Redirect runtime directories to temporary path for isolation
    config.settings = Settings(cnpj_root=tmp_path, workspace_root=tmp_path, app_state_root=tmp_path)

    cnpj = "00000000000999"
    ref = dataset_ref(cnpj, "silver", "test_dataset")

    df = pl.DataFrame({"a": [1, 2, 3]})
    meta = {"dataset_id": "test_dataset_silver", "row_count": df.height}

    save_parquet(df, ref, metadata=meta)

    loaded_meta = load_parquet_metadata(ref)
    assert loaded_meta == meta

    loaded_df = load_parquet(ref)
    assert loaded_df is not None
    assert loaded_df.height == df.height


def test_persist_gold_outputs_v2_writes_operational_metadata_and_columns(tmp_path):
    config.settings = Settings(cnpj_root=tmp_path, workspace_root=tmp_path, app_state_root=tmp_path)

    cnpj = "00000000000888"
    outputs = {
        "fatores_conversao": pl.DataFrame({"id_agrupado": ["AGR1"], "fator": [2.0]}),
    }

    saved = persist_gold_outputs_v2(
        cnpj,
        outputs,
        run_id="RUN-1",
        input_hash="HASH-1",
        data_processamento="2026-04-18T00:00:00+00:00",
        pipeline_version="gold_v20",
        schema_version="v2.1",
        upstream_datasets=["mdc_base", "silver", "references"],
        manual_assets_used=["overrides_conversao"],
    )

    ref = dataset_ref(cnpj, "gold", "fatores_conversao")
    meta = load_parquet_metadata(ref)
    df = load_parquet(ref)

    assert meta is not None
    assert meta["pipeline_version"] == "gold_v20"
    assert meta["schema_version"] == "v2.1"
    assert meta["manual_assets_used"] == ["overrides_conversao"]
    assert meta["upstream_datasets"] == ["mdc_base", "silver", "references"]
    assert meta["run_id"] == "RUN-1"
    assert meta["input_hash"] == "HASH-1"
    assert meta["data_processamento"] == "2026-04-18T00:00:00+00:00"

    assert df is not None
    assert "__run_id__" in df.columns
    assert "__input_hash__" in df.columns
    assert "__data_processamento__" in df.columns
    assert df["__run_id__"][0] == "RUN-1"
    assert saved["__run_metadata__"]["pipeline_version"] == "gold_v20"
    assert saved["__run_metadata__"]["manual_assets_used"] == ["overrides_conversao"]
