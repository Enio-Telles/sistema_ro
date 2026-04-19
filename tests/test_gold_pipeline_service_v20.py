import polars as pl

import backend.app.services.gold_pipeline_service_v20 as service


def test_run_and_persist_gold_v20_loads_sefin_vigencia_when_not_provided(monkeypatch) -> None:
    captured: dict[str, object] = {}

    monkeypatch.setattr(
        service,
        "resolve_reference_dataset",
        lambda root, name: type("Ref", (), {"read": lambda self: pl.DataFrame({"co_sefin": ["123"], "it_da_inicio": [None], "it_da_final": [None]})})(),
    )
    def fake_run_gold_v20(*args, **kwargs):
        captured["sefin_vigencia_df"] = kwargs["sefin_vigencia_df"]
        return {"mov_estoque": pl.DataFrame()}

    monkeypatch.setattr(service, "run_gold_v20", fake_run_gold_v20)
    monkeypatch.setattr(service, "persist_gold_outputs_v2", lambda cnpj, outputs, **kwargs: {})

    payload = service.run_and_persist_gold_v20(
        "123",
        itens_df=pl.DataFrame(),
        c170_df=pl.DataFrame(),
        nfe_df=pl.DataFrame(),
        nfce_df=pl.DataFrame(),
        bloco_h_df=pl.DataFrame(),
    )

    assert isinstance(captured["sefin_vigencia_df"], pl.DataFrame)
    assert payload["cnpj"] == "123"


def test_run_and_persist_gold_v20_passes_pipeline_metadata_to_persistence(monkeypatch) -> None:
    captured: dict[str, object] = {}

    monkeypatch.setattr(service, "run_gold_v20", lambda *args, **kwargs: {"mov_estoque": pl.DataFrame()})

    def fake_persist(cnpj, outputs, **kwargs):
        captured["cnpj"] = cnpj
        captured["outputs"] = outputs
        captured["kwargs"] = kwargs
        return {"mov_estoque": "ok", "__run_metadata__": kwargs}

    monkeypatch.setattr(service, "persist_gold_outputs_v2", fake_persist)

    payload = service.run_and_persist_gold_v20(
        "123",
        itens_df=pl.DataFrame(),
        c170_df=pl.DataFrame(),
        nfe_df=pl.DataFrame(),
        nfce_df=pl.DataFrame(),
        bloco_h_df=pl.DataFrame(),
        overrides_df=pl.DataFrame({"id_agrupado": ["AGR1"], "fator_manual": [2.0]}),
        mapa_manual_df=pl.DataFrame({"codigo_fonte": ["A"], "id_agrupado_manual": ["AGR_MANUAL"]}),
        sefin_vigencia_df=pl.DataFrame(),
    )

    kwargs = captured["kwargs"]
    assert captured["cnpj"] == "123"
    assert kwargs["pipeline_version"] == "gold_v20"
    assert kwargs["upstream_datasets"] == ["mdc_base", "silver", "references"]
    assert kwargs["manual_assets_used"] == ["overrides_conversao", "mapa_manual_agregacao"]
    assert payload["saved"]["__run_metadata__"]["pipeline_version"] == "gold_v20"
