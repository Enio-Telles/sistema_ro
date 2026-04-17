import io
import zipfile
from pathlib import Path

import polars as pl

from backend.app.services import fisconforme_notification_service as service


def _patch_template(monkeypatch, tmp_path: Path) -> Path:
    template = tmp_path / "modelo_notificacao_fisconforme_n_atendido.txt"
    template.write_text(
        "Contribuinte={{RAZAO_SOCIAL}}\n"
        "CNPJ={{CNPJ}}\n"
        "Tabela={{TABELA}}\n"
        "Imagens={{DSF_IMAGENS}}\n",
        encoding="utf-8",
    )
    monkeypatch.setattr(service, "_template_path", lambda: template)
    return template


def _patch_cache(monkeypatch) -> None:
    cadastral = pl.DataFrame(
        [
            {
                "cnpj": "12345678000195",
                "ie": "123456",
                "razao_social": "EMPRESA TESTE LTDA",
            }
        ]
    )
    malhas = pl.DataFrame(
        [
            {
                "cnpj": "12345678000195",
                "id_pendencia": "P-1",
                "id_notificacao": "N-1",
                "malhas_id": "M-1",
                "titulo_malha": "Pendência A",
                "periodo": "2025-01",
                "status_pendencia": "PENDENTE",
                "status_notificacao": "ABERTA",
                "data_ciencia_consolidada": "2025-02-10",
            }
        ]
    )

    def fake_load_cache(cnpj: str, dataset_name: str):
        if dataset_name == "fisconforme_cadastral":
            return cadastral
        if dataset_name == "fisconforme_malhas":
            return malhas
        return None

    monkeypatch.setattr(service, "load_cache", fake_load_cache)


def test_generate_notification_txt_uses_cached_data(monkeypatch, tmp_path: Path) -> None:
    _patch_template(monkeypatch, tmp_path)
    _patch_cache(monkeypatch)

    content, filename = service.generate_notification_txt(
        "12.345.678/0001-95",
        dsf="1204",
        auditor="Auditor Teste",
        cargo_titulo="Auditor Fiscal",
        matricula="123",
        contato="auditor@example.com",
        orgao_origem="SEFIN",
    )

    assert filename == "notificacao_det_12345678000195.txt"
    assert "EMPRESA TESTE LTDA" in content
    assert "12345678000195" in content
    assert "Pendência A" in content
    assert "Imagens=" in content


def test_generate_notifications_zip_contains_one_txt_per_cnpj(monkeypatch, tmp_path: Path) -> None:
    _patch_template(monkeypatch, tmp_path)
    _patch_cache(monkeypatch)

    zip_bytes, zip_name = service.generate_notifications_zip(
        ["12.345.678/0001-95"],
        dsf="1204",
        auditor="Auditor Teste",
    )

    assert zip_name.startswith("notificacoes_fisconforme_")

    with zipfile.ZipFile(io.BytesIO(zip_bytes), "r") as zip_file:
        assert zip_file.namelist() == ["notificacao_det_12345678000195.txt"]
        content = zip_file.read("notificacao_det_12345678000195.txt").decode("utf-8")
        assert "EMPRESA TESTE LTDA" in content


def test_save_and_load_auditor_config(monkeypatch, tmp_path: Path) -> None:
    monkeypatch.setattr(service, "_state_root", lambda: tmp_path)

    service.save_auditor_config(
        auditor="Auditor Teste",
        cargo_titulo="Auditor Fiscal",
        matricula="123",
        contato="auditor@example.com",
        orgao_origem="SEFIN",
    )

    payload = service.load_auditor_config()

    assert payload == {
        "auditor": "Auditor Teste",
        "cargo_titulo": "Auditor Fiscal",
        "matricula": "123",
        "contato": "auditor@example.com",
        "orgao_origem": "SEFIN",
    }
