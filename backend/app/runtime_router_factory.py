from __future__ import annotations

from collections.abc import Callable

from fastapi import APIRouter


PipelineHandler = Callable[[str], dict]


def build_pipeline_router(
    *,
    run_handler: PipelineHandler,
    status_handler: PipelineHandler | None = None,
) -> APIRouter:
    router = APIRouter()

    @router.post("/{cnpj}/run")
    def run_pipeline(cnpj: str) -> dict:
        return run_handler(cnpj)

    if status_handler is not None:
        @router.get("/{cnpj}/status")
        def get_pipeline_status(cnpj: str) -> dict:
            return status_handler(cnpj)

    return router
