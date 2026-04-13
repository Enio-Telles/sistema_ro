from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any, Protocol

from pipeline.extraction.sql_catalog import SqlTemplate, load_sql_template


class DatabaseClient(Protocol):
    def fetch_all(self, sql: str, binds: dict[str, Any]) -> list[dict[str, Any]]: ...


@dataclass(frozen=True)
class SqlExecution:
    template: SqlTemplate
    binds: dict[str, Any]


def build_binds(template: SqlTemplate, values: dict[str, Any]) -> dict[str, Any]:
    binds: dict[str, Any] = {}
    for placeholder in template.placeholders:
        if placeholder in values:
            binds[placeholder] = values[placeholder]
    return binds


def prepare_execution(sql_root: Path, template_name: str, values: dict[str, Any]) -> SqlExecution:
    template = load_sql_template(sql_root=sql_root, name=template_name)
    binds = build_binds(template, values)
    return SqlExecution(template=template, binds=binds)


def execute_query(client: DatabaseClient, sql_root: Path, template_name: str, values: dict[str, Any]) -> list[dict[str, Any]]:
    execution = prepare_execution(sql_root=sql_root, template_name=template_name, values=values)
    return client.fetch_all(execution.template.content, execution.binds)
