from __future__ import annotations

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware


class TransitionRuntimeMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, *, replacement_runtime: str, replacement_prefix: str) -> None:
        super().__init__(app)
        self.replacement_runtime = replacement_runtime
        self.replacement_prefix = replacement_prefix

    async def dispatch(self, request: Request, call_next):
        response = await call_next(request)
        response.headers["Deprecation"] = "true"
        response.headers["X-Replacement-Runtime"] = self.replacement_runtime
        response.headers["X-Replacement-Prefix"] = self.replacement_prefix
        response.headers["Warning"] = '299 - "Runtime em transicao. Prefira a superficie oficial recomendada."'
        return response
