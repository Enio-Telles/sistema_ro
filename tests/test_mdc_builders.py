import polars as pl

from pipeline.mdc.build_from_existing_layers import (
    build_diagnostico_conversao_unidade_base,
    build_efd_produtos_base,
)


def test_build_efd_produtos_base_prefers_base_info() -> None:
    itens = pl.DataFrame([
        {'cnpj': '1', 'codigo_produto_original': 'A', 'descr_item': 'ARROZ', 'unid': 'CX'}
    ])
    base_info = pl.DataFrame([
        {'cnpj': '1', 'codigo_produto_original': 'A', 'descr_item': 'ARROZ TIPO 1', 'unid': 'UN', 'unid_ref': 'UN'}
    ])
    result = build_efd_produtos_base(itens, base_info)
    assert result.height == 1
    assert result['descr_item'][0] == 'ARROZ TIPO 1'


def test_build_diagnostico_conversao_unidade_base_detects_divergent_units() -> None:
    itens = pl.DataFrame([
        {'cnpj': '1', 'codigo_produto_original': 'A', 'id_agrupado': 'AGR1', 'unid': 'CX'}
    ])
    produtos = pl.DataFrame([
        {'id_agrupado': 'AGR1', 'unid_ref': 'UN'}
    ])
    result = build_diagnostico_conversao_unidade_base(itens, produtos_df=produtos)
    assert result.height == 1
    assert result['necessita_conversao'][0] is True
    assert result['evidencia'][0] == 'unidade_divergente'
