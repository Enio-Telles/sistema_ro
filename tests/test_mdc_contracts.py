from pipeline.mdc.mdc_contracts import get_mdc_contract, list_priority_mdc_contracts


def test_list_priority_mdc_contracts_contains_expected_dataset() -> None:
    contracts = list_priority_mdc_contracts()
    assert 'efd_produtos_base' in contracts
    assert contracts['efd_produtos_base']['priority'] == 1


def test_get_mdc_contract_returns_source_sql() -> None:
    contract = get_mdc_contract('diagnostico_conversao_unidade_base')
    assert contract['source_sql'] == '24_diagnostico_necessidade_conversao_unidade.sql'
