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
    monkeypatch.setattr(service, "persist_gold_outputs_v2", lambda cnpj, outputs: {})

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
