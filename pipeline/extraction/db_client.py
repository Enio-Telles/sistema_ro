from __future__ import annotations

from typing import Any, Protocol


class DatabaseClient(Protocol):
    def fetch_all(self, sql: str, binds: dict[str, Any]) -> list[dict[str, Any]]:
        """Executa a consulta e retorna linhas em formato de dicionário."""
        ...
