from fastapi import FastAPI, APIRouter

from backend.app.agregacao_materialize_router import router as agregacao_materialize_router
from backend.app.agregacao_review_router import router as agregacao_review_router
from backend.app.aggregated_sources_v2_router import router as aggregated_sources_v2_router
from backend.app.conversao_quality_router import router as conversao_quality_router
from backend.app.estoque_quality_router import router as estoque_quality_router
from backend.app.fisconforme_dsf_v2_router import router as fisconforme_dsf_v2_router
from backend.app.fisconforme_notification_v3_router import router as fisconforme_notification_v3_router
from backend.app.fisconforme_output_v2_router import router as fisconforme_output_v2_router
from backend.app.fisconforme_refresh_v2_router import router as fisconforme_refresh_v2_router
from backend.app.fisconforme_v2_router import router as fisconforme_v2_router
from backend.app.gold_consistency_router import router as gold_consistency_router
from backend.app.layer_status_router import router as layer_status_router
from backend.app.manual_map_router import router as manual_map_router
from backend.app.mdc_contract_router import router as mdc_contract_router
from backend.app.mdc_materialize_router import router as mdc_materialize_router
from backend.app.operational_surface_index_router import router as operational_surface_index_router
from backend.app.references_diagnostic_router import router as references_router
from backend.app.runtime_overview_router import router as runtime_overview_router
from backend.app.runtime_recommendation_v2_router import router as runtime_recommendation_v2_router
from backend.app.runtime_surface_catalog_router import router as runtime_surface_catalog_router
from backend.app.status_router import router as status_router
from backend.app.routers_v2 import agregacao, conversao, estoque, fisconforme, health
from backend.app.services.pipeline_exec_gold_v20 import execute_gold_v20

pipeline_router = APIRouter()


@pipeline_router.post("/{cnpj}/run")
def run_pipeline(cnpj: str) -> dict:
    return execute_gold_v20(cnpj)


app = FastAPI(title="sistema_ro_gold_v25", version="3.4.0")

app.include_router(health.router, prefix="/api/gold25/health", tags=["health"])
app.include_router(status_router, prefix="/api/gold25/status", tags=["status"])
app.include_router(runtime_recommendation_v2_router, prefix="/api/gold25/runtime", tags=["runtime_recommendation"])
app.include_router(runtime_overview_router, prefix="/api/gold25/runtime-overview", tags=["runtime_overview"])
app.include_router(operational_surface_index_router, prefix="/api/gold25/surfaces", tags=["operational_surface_index"])
app.include_router(runtime_surface_catalog_router, prefix="/api/gold25/surfaces/catalog", tags=["runtime_surface_catalog"])
app.include_router(layer_status_router, prefix="/api/gold25/layers", tags=["layers"])
app.include_router(mdc_contract_router, prefix="/api/gold25/mdc/contracts", tags=["mdc_contracts"])
app.include_router(mdc_materialize_router, prefix="/api/gold25/mdc", tags=["mdc_materialize"])
app.include_router(agregacao.router, prefix="/api/gold25/agregacao", tags=["agregacao"])
app.include_router(agregacao_materialize_router, prefix="/api/gold25/agregacao", tags=["agregacao_materialize"])
app.include_router(agregacao_review_router, prefix="/api/gold25/agregacao", tags=["agregacao_review"])
app.include_router(aggregated_sources_v2_router, prefix="/api/gold25/fontes-agr", tags=["fontes_agr"])
app.include_router(manual_map_router, prefix="/api/gold25/mapa-manual", tags=["manual_map"])
app.include_router(conversao.router, prefix="/api/gold25/conversao", tags=["conversao"])
app.include_router(conversao_quality_router, prefix="/api/gold25/conversao", tags=["conversao_quality"])
app.include_router(estoque.router, prefix="/api/gold25/estoque", tags=["estoque"])
app.include_router(estoque_quality_router, prefix="/api/gold25/estoque", tags=["estoque_quality"])
app.include_router(gold_consistency_router, prefix="/api/gold25/gold", tags=["gold_consistency"])
app.include_router(fisconforme.router, prefix="/api/gold25/fisconforme", tags=["fisconforme"])
app.include_router(fisconforme_v2_router, prefix="/api/gold25/fisconforme-v2", tags=["fisconforme_v2"])
app.include_router(fisconforme_refresh_v2_router, prefix="/api/gold25/fisconforme-v2", tags=["fisconforme_refresh_v2"])
app.include_router(fisconforme_dsf_v2_router, prefix="/api/gold25/fisconforme-v2", tags=["fisconforme_dsf_v2"])
app.include_router(fisconforme_notification_v3_router, prefix="/api/gold25/fisconforme-v2", tags=["fisconforme_notification_v3"])
app.include_router(fisconforme_output_v2_router, prefix="/api/gold25/fisconforme-v2", tags=["fisconforme_output_v2"])
app.include_router(pipeline_router, prefix="/api/gold25/pipeline", tags=["pipeline"])
app.include_router(references_router, prefix="/api/gold25/references", tags=["references"])


@app.get("/")
def root() -> dict[str, str]:
    return {
        "name": "sistema_ro_gold_v25",
        "status": "runtime_with_fisconforme_zip_download_and_docx_output",
    }
