from __future__ import annotations

from pathlib import Path

from backend.app.config import settings

LAYER_DATASETS = {
    "mdc_base": [
        "efd_entregas_base",
        "efd_participantes_base",
        "efd_produtos_base",
        "efd_documentos_base",
        "efd_itens_base",
        "efd_c176_ressarcimento_base",
        "efd_inventario_base",
        "bi_documentos_base",
        "sitafe_nota_item_base",
        "dim_fiscal_sefin_base",
        "diagnostico_conversao_unidade_base",
    ],
    "agregacao": [
        "mapa_manual_agregacao",
        "map_produto_agrupado",
        "produtos_agrupados",
        "id_agrupados",
        "produtos_final",
    ],
    "fontes_agr": [
        "c170_agr",
        "nfe_agr",
        "nfce_agr",
        "bloco_h_agr",
    ],
    "gold_produtos": [
        "item_unidades",
        "fatores_conversao",
        "log_conversao_anomalias",
        "mov_estoque",
        "aba_mensal",
        "aba_anual",
        "aba_periodos",
        "estoque_resumo",
        "estoque_alertas",
    ],
}


def _layer_dir(cnpj: str, layer: str) -> Path:
    path = settings.cnpj_root / cnpj / layer
    path.mkdir(parents=True, exist_ok=True)
    return path


def _layer_status(cnpj: str, layer: str) -> dict:
    layer_dir = _layer_dir(cnpj, layer)
    entries: dict[str, dict] = {}
    for name in LAYER_DATASETS[layer]:
        file_path = layer_dir / f"{name}_{cnpj}.parquet"
        entries[name] = {
            "exists": file_path.exists(),
            "path": str(file_path),
        }
    present = sum(1 for value in entries.values() if value["exists"])
    return {
        "layer": layer,
        "path": str(layer_dir),
        "present": present,
        "expected": len(entries),
        "datasets": entries,
    }


def get_operational_layer_status(cnpj: str) -> dict:
    layers = {layer: _layer_status(cnpj, layer) for layer in LAYER_DATASETS}
    return {
        "cnpj": cnpj,
        "layers": layers,
    }
