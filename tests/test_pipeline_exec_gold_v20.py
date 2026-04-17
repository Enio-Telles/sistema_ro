import polars as pl

import backend.app.services.pipeline_exec_gold_v20 as service


def _fake_raw_inputs(selected_items_source: str = "itens_unificados_sefin", using_aggregated_sources: bool = False) -> dict:
    return {
        "itens_df": pl.DataFrame({"item": ["a"]}),
        "c170_df": pl.DataFrame({"item": ["a"]}),
        "nfe_df": pl.DataFrame(),
        "nfce_df": pl.DataFrame(),
        "bloco_h_df": pl.DataFrame(),
        "overrides_df": pl.DataFrame({"produto": ["a"], "fator": [2.0]}),
        "base_info_df": pl.DataFrame({"item": ["a"]}),
        "mapa_manual_df": pl.DataFrame({"de": ["a"], "para": ["b"]}),
        "map_produto_agrupado_df": pl.DataFrame(),
        "produtos_agrupados_df": pl.DataFrame(),
        "id_agrupados_df": pl.DataFrame(),
        "produtos_final_df": pl.DataFrame(),
        "diagnostico_conversao_df": pl.DataFrame({"item": ["a"], "alerta": ["ok"]}),
        "selected_items_source": selected_items_source,
        "using_aggregated_sources": using_aggregated_sources,
        "fontes_agr_validation": {"ok": using_aggregated_sources, "missing": []},
    }


def test_get_gold_v20_status_exposes_conversion_and_sefin_context(monkeypatch) -> None:
    monkeypatch.setattr(service, "load_gold_inputs_with_conversion_diagnosis", lambda cnpj: _fake_raw_inputs())
    monkeypatch.setattr(
        service,
        "validate_gold_inputs",
        lambda inputs: {"ok": True, "missing": [], "empty": [], "stats": {"itens_df": 1}},
    )
    monkeypatch.setattr(
        service,
        "get_references_and_parquets_status",
        lambda cnpj: {"references": {"ncm": True, "cest": False}},
    )
    monkeypatch.setattr(
        service,
        "get_gold_temporal_resolution_summary",
        lambda cnpj: {
            "status": "available",
            "partial_coverage": True,
            "targets_with_partial_coverage": ["aba_anual"],
            "targets": {"aba_anual": {"rows_without_vigencia_overlap": 1}},
        },
    )

    payload = service.get_gold_v20_status("123")

    assert payload["validation"]["ok"] is True
    assert payload["selected_items_source"] == "itens_unificados_sefin"
    assert payload["references_status"] == {"ncm": True, "cest": False}
    assert payload["sefin_context"]["status"] == "sefin_enriched_items"
    assert payload["sefin_context"]["references_complete"] is False
    assert payload["sefin_context"]["references_status"] == {"ncm": True, "cest": False}
    assert payload["sefin_context"]["using_sefin_enriched_items"] is True
    assert payload["conversion_quality_summary"]["manual_overrides_rows"] == 1
    assert payload["conversion_quality_summary"]["diagnostico_conversao_rows"] == 1
    assert payload["missing_references"] == ["cest"]
    assert payload["temporal_resolution_summary"]["status"] == "not_available"
    assert payload["sefin_context"]["temporal_resolution_summary"]["status"] == "not_available"
    assert payload["quality_attention_required"] is False
    assert payload["attention_flags"] == []


def test_execute_gold_v20_returns_quality_summary_with_result_rows(monkeypatch) -> None:
    monkeypatch.setattr(
        service,
        "load_gold_inputs_with_conversion_diagnosis",
        lambda cnpj: _fake_raw_inputs(selected_items_source="fontes_agr_validated", using_aggregated_sources=True),
    )
    monkeypatch.setattr(
        service,
        "validate_gold_inputs",
        lambda inputs: {"ok": True, "missing": [], "empty": [], "stats": {"itens_df": 1}},
    )
    monkeypatch.setattr(
        service,
        "get_references_and_parquets_status",
        lambda cnpj: {"references": {"ncm": True, "cest": True}},
    )
    monkeypatch.setattr(
        service,
        "run_and_persist_gold_v20",
        lambda cnpj, **inputs: {
            "cnpj": cnpj,
            "saved": {"fatores_conversao": "ok", "log_conversao_anomalias": "ok"},
            "datasets": ["fatores_conversao", "log_conversao_anomalias"],
            "rows": {"fatores_conversao": 5, "log_conversao_anomalias": 2},
        },
    )
    monkeypatch.setattr(service, "get_gold_consistency", lambda cnpj: {"ok": True})
    monkeypatch.setattr(
        service,
        "get_gold_temporal_resolution_summary",
        lambda cnpj: {
            "status": "available",
            "partial_coverage": True,
            "targets_with_partial_coverage": ["aba_periodos"],
            "targets": {"aba_periodos": {"rows_without_vigencia_overlap": 2}},
        },
    )

    payload = service.execute_gold_v20("123")

    assert payload["status"] == "ok"
    assert payload["pipeline_version"] == "gold_v20"
    assert payload["references_status"] == {"ncm": True, "cest": True}
    assert payload["sefin_context"]["status"] == "aggregated_sources"
    assert payload["conversion_quality_summary"]["fatores_conversao_rows"] == 5
    assert payload["conversion_quality_summary"]["log_conversao_anomalias_rows"] == 2
    assert payload["sefin_context"]["references_complete"] is True
    assert payload["sefin_context"]["using_aggregated_sources"] is True
    assert payload["temporal_resolution_summary"]["targets_with_partial_coverage"] == ["aba_periodos"]
    assert payload["sefin_context"]["temporal_resolution_partial"] is True
    assert payload["quality_attention_required"] is True
    assert payload["attention_flags"] == ["temporal_resolution_partial"]


def test_get_gold_v20_status_marks_fallback_without_sefin_when_references_are_complete(monkeypatch) -> None:
    monkeypatch.setattr(
        service,
        "load_gold_inputs_with_conversion_diagnosis",
        lambda cnpj: _fake_raw_inputs(selected_items_source="itens_unificados", using_aggregated_sources=False),
    )
    monkeypatch.setattr(
        service,
        "validate_gold_inputs",
        lambda inputs: {"ok": True, "missing": [], "empty": [], "stats": {"itens_df": 1}},
    )
    monkeypatch.setattr(
        service,
        "get_references_and_parquets_status",
        lambda cnpj: {"references": {"ncm": True, "cest": True}},
    )

    payload = service.get_gold_v20_status("123")

    assert payload["references_status"] == {"ncm": True, "cest": True}
    assert payload["missing_references"] == []
    assert payload["sefin_context"]["status"] == "fallback_without_sefin"
    assert payload["sefin_context"]["using_sefin_enriched_items"] is False


def test_get_gold_v20_status_exposes_temporal_resolution_when_gold_outputs_exist(monkeypatch) -> None:
    monkeypatch.setattr(service, "load_gold_inputs_with_conversion_diagnosis", lambda cnpj: _fake_raw_inputs())
    monkeypatch.setattr(
        service,
        "validate_gold_inputs",
        lambda inputs: {"ok": True, "missing": [], "empty": [], "stats": {"itens_df": 1}},
    )
    monkeypatch.setattr(
        service,
        "get_references_and_parquets_status",
        lambda cnpj: {
            "references": {"ncm": True, "cest": True},
            "gold": {
                "aba_mensal": {"exists": True},
                "aba_anual": {"exists": True},
                "aba_periodos": {"exists": True},
            },
        },
    )
    monkeypatch.setattr(
        service,
        "get_gold_temporal_resolution_summary",
        lambda cnpj: {
            "status": "available",
            "partial_coverage": True,
            "targets_with_partial_coverage": ["aba_anual"],
            "targets": {"aba_anual": {"rows_without_vigencia_overlap": 1}},
        },
    )

    payload = service.get_gold_v20_status("123")

    assert payload["temporal_resolution_summary"]["status"] == "available"
    assert payload["sefin_context"]["temporal_resolution_partial"] is True
    assert payload["sefin_context"]["temporal_resolution_summary"]["targets_with_partial_coverage"] == ["aba_anual"]
    assert payload["quality_attention_required"] is True
    assert payload["attention_flags"] == ["temporal_resolution_partial"]
