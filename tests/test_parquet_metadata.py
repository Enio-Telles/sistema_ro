import polars as pl

from backend.app import config
from backend.app.config import Settings
from backend.app.services.datasets import dataset_ref
from pipeline.io.parquet_store import save_parquet, load_parquet_metadata, load_parquet


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
