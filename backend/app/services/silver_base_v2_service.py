from __future__ import annotations

from backend.app.services.paths import reference_dir
from backend.app.services.source_datasets import load_gold_inputs
from pipeline.persist_silver_v2 import persist_silver_outputs_v2
from pipeline.references.enrichment import enrich_itens_with_sefin
from pipeline.references.loaders import validate_reference_root
from pipeline.run_silver import run_silver_base_pipeline


def execute_silver_base_with_sefin(cnpj: str) -> dict:
    inputs = load_gold_inputs(cnpj)
    outputs = run_silver_base_pipeline(
        c170_df=inputs["c170_df"],
        nfe_df=inputs["nfe_df"],
        nfce_df=inputs["nfce_df"],
        bloco_h_df=inputs["bloco_h_df"],
    )

    enriched = outputs["itens_unificados"]
    refs_root = reference_dir()
    references_status = validate_reference_root(refs_root)
    missing_references = [name for name, exists in references_status.items() if not exists]
    warnings: list[str] = []
    enrichment_error: str | None = None
    sefin_enrichment_status = "applied"

    if missing_references:
        sefin_enrichment_status = "skipped_missing_references"
        warnings.append("Preparação silver concluída sem enriquecimento SEFIN por ausência de referências obrigatórias.")
    else:
        try:
            enriched = enrich_itens_with_sefin(outputs["itens_unificados"], refs_root)
        except Exception as exc:
            enriched = outputs["itens_unificados"]
            enrichment_error = str(exc)
            sefin_enrichment_status = "failed_fallback"
            warnings.append("Preparação silver concluída com fallback após erro no enriquecimento SEFIN.")

    outputs_v2 = {
        **outputs,
        "itens_unificados_sefin": enriched,
    }
    saved = persist_silver_outputs_v2(cnpj, outputs_v2)
    return {
        "cnpj": cnpj,
        "status": "ok",
        "saved": saved,
        "datasets": list(saved.keys()),
        "rows": {name: df.height for name, df in outputs_v2.items() if name in saved},
        "references_status": references_status,
        "missing_references": missing_references,
        "sefin_enrichment_applied": sefin_enrichment_status == "applied" and "itens_unificados_sefin" in saved,
        "sefin_enrichment": {
            "status": sefin_enrichment_status,
            "applied": sefin_enrichment_status == "applied" and "itens_unificados_sefin" in saved,
            "missing_references": missing_references,
            "error": enrichment_error,
        },
        "warnings": warnings,
    }
