from pathlib import Path

import pytest

from pipeline.extraction.sql_catalog import (CORE_SQL_FILES, load_sql_template)


def test_load_sql_template_loads_all_canonical_core_sqls() -> None:
    sql_root = Path("sql")
    for name in CORE_SQL_FILES:
        template = load_sql_template(sql_root, name)
        assert template.name == name

        assert "1 AS placeholder" not in template.content


def test_load_sql_template_rejects_placeholder_sql() -> None:
    sql_root = Path("/tmp/sql_root_test")
    (sql_root / "core").mkdir(parents=True, exist_ok=True)
    (sql_root / "core" / "dummy.sql").write_text(
        """-- dummy.sql
SELECT
    1 AS placeholder
FROM dual
WHERE 1 = 0;
""",
        encoding= "utf-8",
    )

    with pytest.raises(ValueError):
        load_sql_template(sql_root, "dummy")
