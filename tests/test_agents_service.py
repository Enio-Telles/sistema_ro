import backend.app.config as app_config
from backend.app.config import Settings
from backend.app.services.agents_service import list_agents


def test_list_agents(tmp_path):
    # Arrange: create agents folder under workspace_root
    settings = Settings(cnpj_root=tmp_path, workspace_root=tmp_path, app_state_root=tmp_path)
    app_config.settings = settings

    agents_dir = tmp_path / "agentes_sistema_ro"
    agents_dir.mkdir(parents=True)
    file1 = agents_dir / "01_AGENT_FUNDACAO_GOVERNANCA.md"
    file1.write_text("# Fundação e Governança\n\nDetalhes...", encoding="utf-8")
    file2 = agents_dir / "README.md"
    file2.write_text("# Pacote de agentes", encoding="utf-8")

    # Act
    res = list_agents()

    # Assert
    assert res["path"].endswith("agentes_sistema_ro")
    names = [f["name"] for f in res["files"]]
    assert "01_AGENT_FUNDACAO_GOVERNANCA.md" in names
    assert "README.md" in names
    titles = {f["name"]: f["title"] for f in res["files"]}
    assert titles["01_AGENT_FUNDACAO_GOVERNANCA.md"] == "Fundação e Governança"
