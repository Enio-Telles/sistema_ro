from __future__ import annotations

from pathlib import Path
import backend.app.config as app_config


def list_agents() -> dict:
    """Return a summary of agent documentation files found in the workspace.

    The function prefers `settings.workspace_root / 'agentes_sistema_ro'` when
    available, otherwise falls back to a local `agentes_sistema_ro` path.
    Each file entry includes its name, full path and an optional title parsed
    from the first Markdown header found in the file.
    """
    candidates = [app_config.settings.workspace_root / "agentes_sistema_ro", Path("agentes_sistema_ro")]
    agents_root = next((p for p in candidates if p.exists()), candidates[0])
    files = []
    if agents_root.exists() and agents_root.is_dir():
        for p in sorted(agents_root.iterdir()):
            if not p.is_file():
                continue
            title = None
            try:
                with p.open(encoding="utf-8") as f:
                    for line in f:
                        line = line.strip()
                        if line.startswith("#"):
                            title = line.lstrip("#").strip()
                            break
            except (OSError, UnicodeDecodeError):
                title = None
            files.append({"name": p.name, "path": p.name, "title": title})

    return {"path": str(agents_root), "files": files}
