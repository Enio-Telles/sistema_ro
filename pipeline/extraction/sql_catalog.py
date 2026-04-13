from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

CORE_SQL_FILES = {
    "lookup_contribuinte": "lookup_contribuinte.sql",
    "dados_cadastrais": "dados_cadastrais.sql",
    "efd_reg_0200": "efd_reg_0200.sql",
    "efd_c170": "efd_c170.sql",
    "efd_bloco_h": "efd_bloco_h_template.sql",
    "nfe_itens": "nfe_itens_template.sql",
    "fisconforme_cadastral": "fisconforme_cadastral_template.sql",
    "fisconforme_malhas": "fisconforme_malhas.sql",
}


@dataclass(frozen=True)
class SqlTemplate:
    name: str
    path: Path
    content: str

    @property
    def placeholders(self) -> set[str]:
        placeholders: set[str] = set()
        for token in self.content.split(":")[1:]:
            chars: list[str] = []
            for char in token:
                if char.isalnum() or char == "_":
                    chars.append(char)
                else:
                    break
            if chars:
                placeholders.add("".join(chars))
        return placeholders


def resolve_sql_path(sql_root: Path, name: str) -> Path:
    filename = CORE_SQL_FILES.get(name, f"{name}.sql")
    path = sql_root / "core" / filename
    if not path.exists():
        raise FileNotFoundError(f"SQL não encontrada: {path}")
    return path


def load_sql_template(sql_root: Path, name: str) -> SqlTemplate:
    path = resolve_sql_path(sql_root, name)
    return SqlTemplate(name=name, path=path, content=path.read_text(encoding="utf-8"))


def list_available_sql_names() -> Iterable[str]:
    return CORE_SQL_FILES.keys()
