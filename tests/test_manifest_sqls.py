from __future__ import annotations

import csv
from pathlib import Path

from pipeline.extraction.sql_catalog import CORE_SQL_FILES


def test_manifest_sqls_covers_catalog_and_matches_placeholder_state() -> None:
    manifest_path = Path('manifest_sqls.csv')
    rows = list(csv.DictReader(manifest_path.read_text(encoding='utf-8').splitlines()))

    manifest_names = {row['catalog_name'] for row in rows}
    assert manifest_names == set(CORE_SQL_FILES.keys())

    for row in rows:
        core_filename = row['core_filename']
        sql_path = Path('sql') / 'core' / core_filename
        content = sql_path.read_text(encoding='utf-8')
        has_placeholder = '1 AS placeholder' in content
        assert str(has_placeholder).lower() == row['has_placeholder']
