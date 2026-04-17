import polars as pl

import pipeline.run_gold_v20 as pipeline_run


def test_run_gold_v20_passes_vigencia_to_all_stock_derivatives(monkeypatch) -> None:
    captured: dict[str, pl.DataFrame | None] = {}
    vigencia_df = pl.DataFrame(
        {
            "co_sefin": ["123"],
            "it_da_inicio": ["2024-01-01"],
            "it_da_final": ["2024-12-31"],
        }
    )

    monkeypatch.setattr(
        pipeline_run,
        "run_mercadoria_v2",
        lambda *args, **kwargs: {
            "map_produto_agrupado": pl.DataFrame(),
            "produtos_agrupados": pl.DataFrame(),
            "id_agrupados": pl.DataFrame(),
            "produtos_final": pl.DataFrame({"id_agrupado": ["P1"]}),
        },
    )
    monkeypatch.setattr(pipeline_run, "build_item_unidades_v3", lambda *args, **kwargs: pl.DataFrame())
    monkeypatch.setattr(pipeline_run, "calcular_fatores_priorizados_v4", lambda *args, **kwargs: pl.DataFrame())
    monkeypatch.setattr(pipeline_run, "apply_manual_overrides", lambda fatores, overrides_df: fatores)
    monkeypatch.setattr(pipeline_run, "build_conversion_anomalies", lambda *args, **kwargs: pl.DataFrame())
    monkeypatch.setattr(pipeline_run, "build_mov_estoque_v3", lambda *args, **kwargs: pl.DataFrame())

    def capture(name: str):
        def _inner(mov_df, vigencia_df=None):
            captured[name] = vigencia_df
            return pl.DataFrame()

        return _inner

    monkeypatch.setattr(
        pipeline_run,
        "build_aba_mensal_v4",
        capture("mensal"),
    )
    monkeypatch.setattr(
        pipeline_run,
        "build_aba_anual_v4",
        capture("anual"),
    )
    monkeypatch.setattr(
        pipeline_run,
        "build_aba_periodos_v4",
        capture("periodos"),
    )
    monkeypatch.setattr(pipeline_run, "build_estoque_resumo", lambda *args, **kwargs: pl.DataFrame())
    monkeypatch.setattr(pipeline_run, "build_estoque_alertas", lambda *args, **kwargs: pl.DataFrame())

    pipeline_run.run_gold_v20(
        pl.DataFrame(),
        c170_df=pl.DataFrame(),
        nfe_df=pl.DataFrame(),
        nfce_df=pl.DataFrame(),
        bloco_h_df=pl.DataFrame(),
        sefin_vigencia_df=vigencia_df,
    )

    assert captured["mensal"] is vigencia_df
    assert captured["anual"] is vigencia_df
    assert captured["periodos"] is vigencia_df
