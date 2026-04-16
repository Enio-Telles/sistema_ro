import backend.app.services.cnpj_status_service as service


def test_get_cnpj_status_requires_references_first(monkeypatch) -> None:
    def fake_status(_: str) -> dict:
        return {
            "silver": {
                "efd_c170": {"exists": False},
                "nfe_itens": {"exists": False},
                "itens_unificados": {"exists": False},
                "base_info_mercadorias": {"exists": False},
                "itens_unificados_sefin": {"exists": False},
            },
            "gold": {
                "produtos_final": {"exists": False},
                "fatores_conversao": {"exists": False},
                "mov_estoque": {"exists": False},
                "aba_anual": {"exists": False},
            },
            "references": {
                "ncm": True,
                "cest": False,
            },
        }

    monkeypatch.setattr(service, "get_references_and_parquets_status", fake_status)

    payload = service.get_cnpj_status("123")

    assert payload["next_action"] == "validar_referencias"
    assert payload["missing"]["references"] == ["cest"]
    assert payload["recommended_runtime"] == "backend.app.runtime_gold_current_v2:app"
    assert payload["recommended_surfaces"]["gold"]["status_endpoint"] == "/api/current-v2/status/{cnpj}"
    assert payload["recommended_surfaces"]["fisconforme"]["status_endpoint"] == "/api/current-v5/status/{cnpj}"


def test_get_cnpj_status_promotes_quality_when_gold_is_ready(monkeypatch) -> None:
    def fake_status(_: str) -> dict:
        return {
            "silver": {
                "efd_c170": {"exists": True},
                "nfe_itens": {"exists": True},
                "itens_unificados": {"exists": True},
                "base_info_mercadorias": {"exists": True},
                "itens_unificados_sefin": {"exists": True},
            },
            "gold": {
                "produtos_final": {"exists": True},
                "fatores_conversao": {"exists": True},
                "mov_estoque": {"exists": True},
                "aba_anual": {"exists": True},
            },
            "references": {
                "ncm": True,
                "cest": True,
            },
        }

    monkeypatch.setattr(service, "get_references_and_parquets_status", fake_status)

    payload = service.get_cnpj_status("123")

    assert payload["next_action"] == "revisar_quality"
    assert payload["gold_ready"] is True
    assert payload["sefin_ready"] is True
    assert payload["missing"]["gold_outputs"] == []
