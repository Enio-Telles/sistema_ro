import polars as pl

from pipeline.conversao.anomalias import build_conversion_anomalies


def test_build_conversion_anomalies_flags_same_unit_factor() -> None:
    fatores = pl.DataFrame([
        {
            "id_agrupado": "P1",
            "unid": "UN",
            "unid_ref": "UN",
            "fator": 12.0,
            "tipo_fator": "estrutural",
            "confianca_fator": 0.9,
        }
    ])
    result = build_conversion_anomalies(fatores)
    assert result.height == 1
    assert result["anomalia_mesma_unidade_fator_diferente"][0] is True
