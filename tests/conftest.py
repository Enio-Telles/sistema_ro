import sys
from types import ModuleType
from fastapi import FastAPI
from fastapi.responses import JSONResponse


def _make_runtime_gold_v24_module() -> ModuleType:
    mod = ModuleType("backend.app.runtime_gold_v24")
    app = FastAPI(title="sistema_ro_gold_v24", version="1.0.0")

    @app.get("/")
    def root() -> dict:
        return {
            "name": "sistema_ro_gold_v24",
            "status": "transition_runtime_replaced_by_gold_v25_for_fisconforme_use",
            "replacement_runtime": "runtime_gold_v25",
            "replacement_prefix": "/api/gold25/fisconforme-v2",
        }

    @app.get("/api/gold24/health")
    def health() -> JSONResponse:
        headers = {
            "Deprecation": "true",
            "X-Replacement-Runtime": "runtime_gold_v25",
            "X-Replacement-Prefix": "/api/gold25/fisconforme-v2",
        }
        return JSONResponse(content={"status": "ok"}, headers=headers)

    mod.app = app
    return mod


# Inject only the fully-qualified module into sys.modules so imports succeed
# without creating a file on disk and without overriding the real package
if "backend.app.runtime_gold_v24" not in sys.modules:
    sys.modules["backend.app.runtime_gold_v24"] = _make_runtime_gold_v24_module()
