from __future__ import annotations

from fastapi import APIRouter, Request
from fastapi.responses import Response

from backend.app.services.estoque_table_service import consultar_tabela_estoque, exportar_tabela_estoque_csv

router = APIRouter()


@router.get("/{cnpj}/tabelas/{dataset}")
def get_tabela_estoque(cnpj: str, dataset: str, request: Request) -> dict:
    return consultar_tabela_estoque(cnpj, dataset, request.query_params)


@router.get("/{cnpj}/tabelas/{dataset}/export")
def export_tabela_estoque(cnpj: str, dataset: str, request: Request) -> Response:
    conteudo, filename = exportar_tabela_estoque_csv(cnpj, dataset, request.query_params)
    return Response(
        content=conteudo,
        media_type="text/csv; charset=utf-8",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
