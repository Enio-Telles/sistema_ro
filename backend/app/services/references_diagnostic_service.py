from __future__ import annotations

from pathlib import Path
import ast
from typing import Optional

from backend.app.services.datasets import dataset_ref
from backend.app.services.paths import reference_dir
import backend.app.config as app_config
from pipeline.io.parquet_store import parquet_exists
from pipeline.references.loaders import validate_reference_root

EXPECTED_SILVER = [
    "efd_c170",
    "nfe_itens",
    "nfce_itens",
    "bloco_h",
    "itens_unificados",
    "base_info_mercadorias",
    "itens_unificados_sefin",
]

EXPECTED_GOLD = [
    "produtos_agrupados",
    "id_agrupados",
    "produtos_final",
    "item_unidades",
    "fatores_conversao",
    "log_conversao_anomalias",
    "mov_estoque",
    "aba_mensal",
    "aba_anual",
    "aba_periodos",
    "estoque_resumo",
    "estoque_alertas",
]

EXPECTED_FISCONFORME = [
    "fisconforme_cadastral",
    "fisconforme_malhas",
]


def _load_manifest_datasets() -> tuple[dict[str, dict], Optional[Path]]:
    """Load dataset manifest from docs/datasets/manifest_datasets.yaml if present.

    Returns a tuple of (manifest_dict, manifest_path) where manifest_dict is
    the parsed `datasets` mapping (or empty dict) and manifest_path is the
    Path where the manifest was found (or None).
    Tries several candidate locations and supports a minimal YAML fallback
    parser (no external dependency required).
    """
    # prefer workspace-root provided in settings, then repo cwd, then relative path
    candidates = [
        app_config.settings.workspace_root / "docs" / "datasets" / "manifest_datasets.yaml",
        Path.cwd() / "docs" / "datasets" / "manifest_datasets.yaml",
        Path("docs") / "datasets" / "manifest_datasets.yaml",
    ]
    manifest_path: Optional[Path] = None
    for p in candidates:
        if p.exists():
            manifest_path = p
            break
    if manifest_path is None:
        return {}, None

    try:
        import yaml

        with manifest_path.open(encoding="utf-8") as fh:
            data = yaml.safe_load(fh)
        datasets = data.get("datasets", {}) if isinstance(data, dict) else {}
        return datasets, manifest_path
    except Exception:
        # Fallback minimal parser for the specific manifest structure
        datasets: dict[str, dict] = {}
        current: Optional[str] = None
        for raw in manifest_path.read_text(encoding="utf-8").splitlines():
            line = raw.rstrip("\n")
            if line.strip().startswith("datasets:"):
                continue
            # detect dataset key (two-spaces indent)
            if line.startswith("  ") and line.strip().endswith(":") and not line.startswith("    "):
                current = line.strip()[:-1]
                datasets[current] = {}
                continue
            # detect property lines (four spaces indent)
            if current and line.startswith("    "):
                parts = line.strip().split(":", 1)
                if len(parts) == 2:
                    key = parts[0].strip()
                    raw_value = parts[1].strip()
                    if raw_value == "":
                        # property with nested block (ignored by fallback)
                        continue
                    # try literal eval to interpret lists or quoted strings
                    try:
                        value = ast.literal_eval(raw_value)
                    except Exception:
                        # strip quotes if present
                        value = raw_value.strip('"').strip("'")
                    datasets[current][key] = value
        return datasets, manifest_path


def _manifest_to_expected(manifest: dict[str, dict]) -> dict[str, list[str]]:
    """Map manifest dataset entries to diagnostic layers: silver/gold/fisconforme."""
    result = {"silver": [], "gold": [], "fisconforme": []}

    def map_layer(layer: str) -> Optional[str]:
        if not layer:
            return None
        layer = layer.lower()
        if layer in ("base", "silver"):
            return "silver"
        if layer in ("marts", "gold", "curated", "mdc"):
            return "gold"
        if layer in ("fisconforme",):
            return "fisconforme"
        return None

    for name, props in manifest.items():
        layer = None
        if isinstance(props, dict):
            layer = props.get("layer")
        mapped = map_layer(layer) if layer else None
        if mapped:
            result[mapped].append(name)
    return result


def _layer_status(cnpj: str, layer: str, names: list[str]) -> dict[str, dict]:
    result: dict[str, dict] = {}
    for name in names:
        ref = dataset_ref(cnpj=cnpj, layer=layer, name=name)
        result[name] = {
            "exists": parquet_exists(ref),
            "path": str(ref.path),
        }
    return result


def get_references_and_parquets_status(cnpj: str) -> dict:
    refs_root = reference_dir()
    refs_status = validate_reference_root(refs_root)
    # derive expected datasets from docs manifest when available
    manifest, manifest_path = _load_manifest_datasets()
    manifest_expected = _manifest_to_expected(manifest) if manifest else {"silver": [], "gold": [], "fisconforme": []}

    silver_names = list(dict.fromkeys(EXPECTED_SILVER + manifest_expected.get("silver", [])))
    gold_names = list(dict.fromkeys(EXPECTED_GOLD + manifest_expected.get("gold", [])))
    fisconforme_names = list(dict.fromkeys(EXPECTED_FISCONFORME + manifest_expected.get("fisconforme", [])))

    silver = _layer_status(cnpj, "silver", silver_names)
    gold = _layer_status(cnpj, "gold", gold_names)
    fisconforme = _layer_status(cnpj, "fisconforme", fisconforme_names)

    # report agent documentation presence
    agents_candidates = [app_config.settings.workspace_root / "agentes_sistema_ro", Path("agentes_sistema_ro")]
    agents_root = next((p for p in agents_candidates if p.exists()), Path("agentes_sistema_ro"))
    agents_files = []
    if agents_root.exists() and agents_root.is_dir():
        agents_files = [p.name for p in agents_root.iterdir() if p.is_file()]
    return {
        "cnpj": cnpj,
        "references_root": str(refs_root),
        "references": refs_status,
        "silver": silver,
        "gold": gold,
        "fisconforme": fisconforme,
        "agents": {"path": str(agents_root), "files": agents_files},
        "manifest": {"path": str(manifest_path) if manifest_path is not None else None, "datasets": manifest},
    }
