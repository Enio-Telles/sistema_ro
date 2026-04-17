import polars as pl

import backend.app.services.silver_base_v2_service as service


def _base_outputs() -> dict:
    itens = pl.DataFrame({"item": ["a"], "ncm": ["1234"], "cest": ["01"]})
    return {
        "itens_unificados": itens,
        "base_info_mercadorias": pl.DataFrame({"item": ["a"]}),
    }


def test_execute_silver_base_with_sefin_reports_missing_references(monkeypatch, tmp_path) -> None:
    monkeypatch.setattr(service, "load_gold_inputs", lambda cnpj: {"c170_df": pl.DataFrame(), "nfe_df": pl.DataFrame(), "nfce_df": pl.DataFrame(), "bloco_h_df": pl.DataFrame()})
    monkeypatch.setattr(service, "run_silver_base_pipeline", lambda **kwargs: _base_outputs())
    monkeypatch.setattr(service, "reference_dir", lambda: tmp_path)
    monkeypatch.setattr(
        service,
        "persist_silver_outputs_v2",
        lambda cnpj, outputs: {name: f"/tmp/{name}.parquet" for name in outputs},
    )

    payload = service.execute_silver_base_with_sefin("123")

    assert payload["status"] == "ok"
    assert payload["sefin_enrichment_applied"] is False
    assert payload["sefin_enrichment"]["status"] == "skipped_missing_references"
    assert "sitafe_cest" in payload["missing_references"]
    assert payload["warnings"]


def test_execute_silver_base_with_sefin_reports_enrichment_failure(monkeypatch, tmp_path) -> None:
    for filename in [
        "sitafe_cest.parquet",
        "sitafe_cest_ncm.parquet",
        "sitafe_ncm.parquet",
        "sitafe_produto_sefin.parquet",
        "sitafe_produto_sefin_aux.parquet",
    ]:
        (tmp_path / filename).write_text("x", encoding="utf-8")

    monkeypatch.setattr(service, "load_gold_inputs", lambda cnpj: {"c170_df": pl.DataFrame(), "nfe_df": pl.DataFrame(), "nfce_df": pl.DataFrame(), "bloco_h_df": pl.DataFrame()})
    monkeypatch.setattr(service, "run_silver_base_pipeline", lambda **kwargs: _base_outputs())
    monkeypatch.setattr(service, "reference_dir", lambda: tmp_path)
    monkeypatch.setattr(service, "enrich_itens_with_sefin", lambda itens, root: (_ for _ in ()).throw(RuntimeError("falha controlada")))
    monkeypatch.setattr(
        service,
        "persist_silver_outputs_v2",
        lambda cnpj, outputs: {name: f"/tmp/{name}.parquet" for name in outputs},
    )

    payload = service.execute_silver_base_with_sefin("123")

    assert payload["status"] == "ok"
    assert payload["sefin_enrichment_applied"] is False
    assert payload["sefin_enrichment"]["status"] == "failed_fallback"
    assert payload["sefin_enrichment"]["error"] == "falha controlada"
    assert payload["missing_references"] == []


def test_execute_silver_base_with_sefin_reports_success(monkeypatch, tmp_path) -> None:
    for filename in [
        "sitafe_cest.parquet",
        "sitafe_cest_ncm.parquet",
        "sitafe_ncm.parquet",
        "sitafe_produto_sefin.parquet",
        "sitafe_produto_sefin_aux.parquet",
    ]:
        (tmp_path / filename).write_text("x", encoding="utf-8")

    monkeypatch.setattr(service, "load_gold_inputs", lambda cnpj: {"c170_df": pl.DataFrame(), "nfe_df": pl.DataFrame(), "nfce_df": pl.DataFrame(), "bloco_h_df": pl.DataFrame()})
    monkeypatch.setattr(service, "run_silver_base_pipeline", lambda **kwargs: _base_outputs())
    monkeypatch.setattr(service, "reference_dir", lambda: tmp_path)
    monkeypatch.setattr(
        service,
        "enrich_itens_with_sefin",
        lambda itens, root: itens.with_columns(pl.lit("001").alias("co_sefin_inferido")),
    )
    monkeypatch.setattr(
        service,
        "persist_silver_outputs_v2",
        lambda cnpj, outputs: {name: f"/tmp/{name}.parquet" for name in outputs},
    )

    payload = service.execute_silver_base_with_sefin("123")

    assert payload["status"] == "ok"
    assert payload["sefin_enrichment_applied"] is True
    assert payload["sefin_enrichment"]["status"] == "applied"
    assert payload["sefin_enrichment"]["error"] is None
    assert payload["warnings"] == []
