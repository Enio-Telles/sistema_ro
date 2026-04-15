from fastapi import FastAPI, APIRouter

from backend.app.agregacao_materialize_router import router as agregacao_materialize_router
from backend.app.agregacao_review_router import router as agregacao_review_router
from backend.app.aggregated_sources_v2_router import router as aggregated_sources_v2_router
from backend.app.conversao_quality_router import router as conversao_quality_router
from backend.app.estoque_quality_router import router as estoque_quality_router
from backend.app.fisconforme_dsf_v2_router import router as fisconforme_dsf_v2_router
from backend.app.fisconforme_refresh_v2_router import router as fisconforme_refresh_v2_router
from backend.app.fisconforme_v2_router import router as fisconforme_v2_router
from backend.app.gold_consistency_router import router as gold_consistency_router
from backend.app.layer_status_router import router as layer_status_router
from backend.app.manual_map_router import router as manual_map_router
from backend.app.mdc_contract_router import router as mdc_contract_router
from backend.app.mdc_materialize_router import router as mdc_materialize_router
from backend.app.references_diagnostic_router import router as references_router
from backend.app.runtime_recommendation_v2_router import router as runtime_recommendation_v2_router
from backend.app.status_router import router as status_router
from backend.app.routers_v2 import agregacao, conversao, estoque, fisconforme, health
from backend.app.services.pipeline_exec_gold_v20 import execute_gold_v20

pipeline_router = APIRouter()


@pipeline_router.post("/{cnpj}/run")
def run_pipeline(cnpj: str) -> dict:
    return execute_gold_v20(cnpj)


app = FastAPI(title="sistema_ro_gold_v23", version="3.2.0")

app.include_router(health.router, prefix="/api/gold23/health", tags=["health"])
app.include_router(status_router, prefix="/api/gold23/status", tags=["status"])
app.include_router(runtime_recommendation_v2_router, prefix="/api/gold23/runtime", tags=["runtime_recommendation"])
app.include_router(layer_status_router, prefix="/api/gold23/layers", tags=["layers"])
app.include_router(mdc_contract_router, prefix="/api/gold23/mdc/contracts", tags=["mdc_contracts"])
app.include_router(mdc_materialize_router, prefix="/api/gold23/mdc", tags=["mdc_materialize"])
app.include_router(agregacao.router, prefix="/api/gold23/agregacao", tags=["agregacao"])
app.include_router(agregacao_materialize_router, prefix="/api/gold23/agregacao", tags=["agregacao_materialize"])
app.include_router(agregacao_review_router, prefix="/api/gold23/agregacao", tags=["agregacao_review"])
app.include_router(aggregated_sources_v2_router, prefix="/api/gold23/fontes-agr", tags=["fontes_agr"])
app.include_router(manual_map_router, prefix="/api/gold23/mapa-manual", tags=["manual_map"])
app.include_router(conversao.router, prefix="/api/gold23/conversao", tags=["conversao"])
app.include_router(conversao_quality_router, prefix="/api/gold23/conversao", tags=["conversao_quality"])
app.include_router(estoque.router, prefix="/api/gold23/estoque", tags=["estoque"])
app.include_router(estoque_quality_router, prefix="/api/gold23/estoque", tags=["estoque_quality"])
app.include_router(gold_consistency_router, prefix="/api/gold23/gold", tags=["gold_consistency"])
app.include_router(fisconforme.router, prefix="/api/gold23/fisconforme", tags=["fisconforme"])
app.include_router(fisconforme_v2_router, prefix="/api/gold23/fisconforme-v2", tags=["fisconforme_v2"])
app.include_router(fisconforme_refresh_v2_router, prefix="/api/gold23/fisconforme-v2", tags=["fisconforme_refresh_v2"])
app.include_router(fisconforme_dsf_v2_router, prefix="/api/gold23/fisconforme-v2", tags=["fisconforme_dsf_v2"])
app.include_router(pipeline_router, prefix="/api/gold23/pipeline", tags=["pipeline"])
app.include_router(references_router, prefix="/api/gold23/references", tags=["references"])


@app.get("/")
def root() -> dict[str, str]:
    return {
        "name": "sistema_ro_gold_v23",
        "status": "runtime_with_modular_fisconforme_dsf_and_notification_services",
    }
