from pathlib import Path

from pipeline.extraction.sql_catalog import resolve_sql_path


def test_resolve_sql_path_points_to_canonical_promoted_core_sqls() -> None:
    sql_root = Path("sql")
    assert resolve_sql_path(sql_root, "efd_bloco_h").name == "efd_bloco_h.sql"
    assert resolve_sql_path(sql_root, "nfe_itens").name == "nfe_itens.sql"
    assert resolve_sql_path(sql_root, "fisconforme_cadastral").name == "fisconforme_cadastral.sql"
