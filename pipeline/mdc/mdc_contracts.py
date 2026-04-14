from __future__ import annotations

MDC_BASE_CONTRACTS: dict[str, dict] = {
    "efd_produtos_base": {
        "priority": 1,
        "source_sql": "04_efd_produtos_0200_0220_base.sql",
        "description": "Cadastro de produtos EFD com unidades e apoio à 0220.",
        "minimal_keys": ["cnpj", "codigo_produto_original"],
        "recommended_columns": ["cnpj", "codigo_produto_original", "descr_item", "unid", "descr_compl", "ncm", "cest", "gtin"],
        "used_by": ["agregacao", "conversao", "gold_produtos"],
    },
    "efd_documentos_base": {
        "priority": 1,
        "source_sql": "05_efd_c100_documentos_base.sql",
        "description": "Cabeçalho documental da EFD para chaves e contexto fiscal.",
        "minimal_keys": ["cnpj", "chave_doc"],
        "recommended_columns": ["cnpj", "chave_doc", "dt_doc", "ind_oper", "ind_emit", "cod_part"],
        "used_by": ["fontes_agr", "gold_produtos"],
    },
    "efd_itens_base": {
        "priority": 1,
        "source_sql": "06_efd_c170_itens_base.sql",
        "description": "Itens fiscais EFD para entradas e saídas com rastreabilidade por linha.",
        "minimal_keys": ["cnpj", "id_linha_origem"],
        "recommended_columns": ["cnpj", "id_linha_origem", "chave_doc", "codigo_produto_original", "descr_item", "qtd", "vl_item", "unid"],
        "used_by": ["agregacao", "fontes_agr", "gold_produtos"],
    },
    "efd_inventario_base": {
        "priority": 1,
        "source_sql": "08_efd_h005_h010_h020_inventario_base.sql",
        "description": "Inventário EFD para estoque inicial, final e períodos de apuração.",
        "minimal_keys": ["cnpj", "id_linha_origem"],
        "recommended_columns": ["cnpj", "id_linha_origem", "dt_inventario", "codigo_produto_original", "descr_item", "qtd", "unid"],
        "used_by": ["agregacao", "fontes_agr", "gold_produtos"],
    },
    "sitafe_nota_item_base": {
        "priority": 1,
        "source_sql": "14_sitafe_nota_item_calculo_base.sql",
        "description": "Base de cálculo SITAFE/Fronteira por item documental.",
        "minimal_keys": ["cnpj", "chave_doc", "codigo_produto_original"],
        "recommended_columns": ["cnpj", "chave_doc", "codigo_produto_original", "valor_item", "ncm", "cest"],
        "used_by": ["gold_produtos", "fiscal", "ressarcimento"],
    },
    "dim_fiscal_sefin_base": {
        "priority": 1,
        "source_sql": "17_dimensoes_fiscais_ncm_cest_sefin_base.sql",
        "description": "Dimensão fiscal para NCM, CEST e CO_SEFIN.",
        "minimal_keys": ["ncm", "cest"],
        "recommended_columns": ["ncm", "cest", "co_sefin", "aliq_interna", "it_in_st", "it_pc_mva"],
        "used_by": ["gold_produtos", "fiscal"],
    },
    "diagnostico_conversao_unidade_base": {
        "priority": 1,
        "source_sql": "24_diagnostico_necessidade_conversao_unidade.sql",
        "description": "Diagnóstico operacional da necessidade de conversão de unidade.",
        "minimal_keys": ["cnpj", "codigo_produto_original"],
        "recommended_columns": ["cnpj", "codigo_produto_original", "unid_origem", "unid_destino", "necessita_conversao", "evidencia"],
        "used_by": ["conversao", "gold_produtos"],
    },
}


def list_priority_mdc_contracts() -> dict[str, dict]:
    return MDC_BASE_CONTRACTS


def get_mdc_contract(dataset_name: str) -> dict:
    if dataset_name not in MDC_BASE_CONTRACTS:
        raise KeyError(dataset_name)
    return MDC_BASE_CONTRACTS[dataset_name]
