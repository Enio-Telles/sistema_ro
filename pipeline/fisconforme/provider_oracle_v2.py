from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import polars as pl

from pipeline.extraction.oracle_adapter_v2 import OracleAdapterConfigV2, OracleAdapterV2
from pipeline.extraction.sql_runner import execute_query


def _periodo_para_oracle(periodo: str, default: str) -> str:
    if periodo and "/" in periodo:
        try:
            mes, ano = periodo.split("/")
            return f"{ano.strip()}{mes.strip().zfill(2)}"
        except Exception:
            return default
    return default


@dataclass(frozen=True)
class FisconformeOracleProviderV2:
    client: OracleAdapterV2
    sql_root: Path
    data_inicio: str = "01/2021"
    data_fim: str = "12/2025"

    def __call__(self, cnpj: str) -> tuple[pl.DataFrame, pl.DataFrame]:
        cadastral_rows = execute_query(
            client=self.client,
            sql_root=self.sql_root,
            template_name="fisconforme_cadastral",
            values={
                "cnpj": cnpj,
                "co_cnpj_cpf": cnpj,
                "cnpj_cpf": cnpj,
                "cpf_cnpj": cnpj,
            },
        )
        malhas_rows = execute_query(
            client=self.client,
            sql_root=self.sql_root,
            template_name="fisconforme_malhas",
            values={
                "cnpj": cnpj,
                "periodo_inicio": _periodo_para_oracle(self.data_inicio, "190001"),
                "periodo_fim": _periodo_para_oracle(self.data_fim, "209912"),
            },
        )
        return pl.DataFrame(cadastral_rows) if cadastral_rows else pl.DataFrame(), pl.DataFrame(malhas_rows) if malhas_rows else pl.DataFrame()


def build_oracle_provider_v2(
    *,
    host: str,
    port: int,
    service: str,
    user: str,
    secret: str,
    sql_root: Path,
    data_inicio: str = "01/2021",
    data_fim: str = "12/2025",
) -> FisconformeOracleProviderV2:
    client = OracleAdapterV2(
        OracleAdapterConfigV2(
            host=host,
            port=port,
            service=service,
            user=user,
            secret=secret,
        )
    )
    return FisconformeOracleProviderV2(
        client=client,
        sql_root=sql_root,
        data_inicio=data_inicio,
        data_fim=data_fim,
    )
