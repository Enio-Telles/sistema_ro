from pathlib import Path

from pipeline.extraction.sql_catalog import load_sql_template
from pipeline.extraction.sql_runner import build_binds


REPO_ROOT = Path(__file__).resolve().parents[1]
SQL_ROOT = REPO_ROOT / 'sql'


def test_load_sql_template_and_placeholders() -> None:
    template = load_sql_template(SQL_ROOT, 'efd_c170')
    assert 'periodo_inicio' in template.placeholders
    assert 'periodo_fim' in template.placeholders
    assert 'cnpj' in template.placeholders


def test_build_binds_filters_only_expected_keys() -> None:
    template = load_sql_template(SQL_ROOT, 'fisconforme_malhas')
    binds = build_binds(template, {
        'cnpj': '12345678000190',
        'periodo_inicio': '202401',
        'periodo_fim': '202412',
        'nao_usado': 'x',
    })
    assert binds == {
        'cnpj': '12345678000190',
        'periodo_inicio': '202401',
        'periodo_fim': '202412',
    }
