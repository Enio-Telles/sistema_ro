from __future__ import annotations

from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class OracleAdapterConfigV2:
    host: str
    port: int
    service: str
    user: str
    secret: str


class OracleAdapterV2:
    def __init__(self, config: OracleAdapterConfigV2):
        self.config = config

    def fetch_all(self, sql: str, binds: dict[str, Any]) -> list[dict[str, Any]]:
        try:
            import oracledb
        except ImportError as exc:
            raise RuntimeError("oracledb não instalado no ambiente atual") from exc

        dsn = oracledb.makedsn(self.config.host, self.config.port, service_name=self.config.service)
        conn = oracledb.connect(user=self.config.user, password=self.config.secret, dsn=dsn)
        try:
            with conn.cursor() as cur:
                cur.execute("ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,'")
                cur.execute(sql, binds)
                if cur.description is None:
                    return []
                columns = [col[0].lower() for col in cur.description]
                rows = cur.fetchall()
                return [dict(zip(columns, row)) for row in rows]
        finally:
            conn.close()
