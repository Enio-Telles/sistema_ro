from datetime import date

import polars as pl

import backend.app.services.gold_temporal_resolution_service as service


def test_get_gold_temporal_resolution_summary_marks_partial_coverage(monkeypatch) -> None:
    monkeypatch.setattr(
        service,
        "_load_vigencia_reference",
        lambda: pl.DataFrame(
            {
                "co_sefin": ["123"],
                "it_da_inicio": ["2024-01-01"],
                "it_da_final": ["2024-12-31"],
            }
        ),
    )

    def fake_load(cnpj: str, name: str) -> pl.DataFrame:
        if name == "aba_mensal":
            return pl.DataFrame({"co_sefin_agr": ["123", None], "ano": [2024, 2024], "mes": [1, 1]})
        if name == "aba_anual":
            return pl.DataFrame({"co_sefin_agr": ["123", "999"], "ano": [2024, 2024]})
        return pl.DataFrame(
            {
                "co_sefin_agr": ["123"],
                "data_inicio": [date(2024, 1, 1)],
                "data_fim": [date(2024, 1, 31)],
            }
        )

    monkeypatch.setattr(service, "_load_gold_dataset", fake_load)

    payload = service.get_gold_temporal_resolution_summary("123")

    assert payload["status"] == "available"
    assert payload["partial_coverage"] is True
    assert payload["targets_with_partial_coverage"] == ["aba_anual"]
    assert payload["targets"]["aba_mensal"]["non_coverage_breakdown"]["sem_co_sefin"] == 1
    assert payload["targets"]["aba_anual"]["non_coverage_breakdown"]["sem_intersecao_temporal"] == 1


def test_get_gold_temporal_resolution_summary_disables_when_vigencia_missing(monkeypatch) -> None:
    monkeypatch.setattr(service, "_load_vigencia_reference", lambda: pl.DataFrame())
    monkeypatch.setattr(service, "_load_gold_dataset", lambda cnpj, name: pl.DataFrame({"co_sefin_agr": ["123"]}))

    payload = service.get_gold_temporal_resolution_summary("123")

    assert payload["status"] == "disabled"
    assert payload["partial_coverage"] is False
    assert payload["targets"]["aba_mensal"]["status"] == "disabled"
