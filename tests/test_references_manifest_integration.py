from backend.app import config
from backend.app.config import Settings
from backend.app.services.references_diagnostic_service import get_references_and_parquets_status


def test_manifest_integration(tmp_path):
    # Redirect runtime directories to temporary path for isolation
    config.settings = Settings(cnpj_root=tmp_path, workspace_root=tmp_path, app_state_root=tmp_path)

    docs_dir = tmp_path / "docs" / "datasets"
    docs_dir.mkdir(parents=True)
    manifest_file = docs_dir / "manifest_datasets.yaml"
    manifest_content = '''version: "1.0"
datasets:
  my_test_dataset:
    id: "my_test_dataset_id"
    layer: "base"
    schema_version: "v1.0"
    source_sql: "sql/core/foo.sql"
    primary_keys: ["id"]
    description: "Test dataset."
'''
    manifest_file.write_text(manifest_content, encoding="utf-8")

    cnpj = "00000000000200"
    status = get_references_and_parquets_status(cnpj)

    assert "manifest" in status
    assert status["manifest"]["path"] is not None
    assert "my_test_dataset" in status["manifest"]["datasets"]
    # layer 'base' in manifest should map to silver diagnostics
    assert "my_test_dataset" in status["silver"]
