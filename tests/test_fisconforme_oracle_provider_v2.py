from __future__ import annotations

from pathlib import Path
from typing import Any

from pipeline.fisconforme.provider_oracle_v2 import FisconformeOracleProviderV2


class FakeOracleClient:
    def __init__(self) -> None:
        self.calls: list[tuple[str, dict[str, Any]]] = []

    def fetch_all(self, sql: str, binds: dict[str, Any]) -> list[dict[str, Any]]:
        self.calls.append((sql, binds))
        return []


def test_fisconforme_oracle_provider_v2_uses_canonical_sqls_and_oracle_period_binds() -> None:
    client = FakeOracleClient()
    provider = FisconformeOracleProviderV2(
        client=client,
        sql_root=Path('sql'),
        data_inicio='01/2021',
        data_fim='12/2025',
    )

    cadastral_df, malhas_df = provider('12.345.678/0001-90')

    assert cadastral_df.is_empty()
    assert malhas_df.is_empty()
    assert len(client.calls) == 2

    cadastral_sql, cadastral_binds = client.calls[0]
    malhas_sql, malhas_binds = client.calls[1]

    assert 'FROM bi.dm_pessoa p' in cadastral_sql
    assert cadastral_binds == {'cnpj': '12.345.678/0001-90'}

    assert 'FROM app_pendencia.pendencias dp' in malhas_sql
    assert malhas_binds == {
        'cnpj': '12.345.678/0001-90',
        'periodo_inicio': '202101',
        'periodo_fim': '202512',
    }
