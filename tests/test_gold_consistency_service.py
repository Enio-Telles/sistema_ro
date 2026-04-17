from datetime import date

import polars as pl

import backend.app.services.gold_consistency_service as service


def test_validate_required_ok() -> None:
    df = pl.DataFrame([
        {
            "id_agregado": "AGR1",
            "cod_per": 1,
            "data_inicio": date(2024, 1, 1),
            "data_fim": date(2024, 1, 31),
            "periodo_label": "01/01/2024 até 31/01/2024",
            "ST": "ST",
            "ICMS_saidas_desac": 0.0,
            "ICMS_estoque_desac": 1.0,
        }
    ])
    result = service._validate_required(df, "aba_periodos")
    assert result["ok"] is True
    assert result["missing_columns"] == []


def test_validate_required_detects_missing_columns() -> None:
    df = pl.DataFrame([
        {"id_agregado": "AGR1", "cod_per": 1}
    ])
    result = service._validate_required(df, "aba_periodos")
    assert result["ok"] is False
    assert "data_inicio" in result["missing_columns"]
    assert "periodo_label" in result["missing_columns"]


def test_get_gold_consistency_flags_inventory_and_period_contract_gaps(monkeypatch) -> None:
    mov_df = pl.DataFrame([
        {
            "id_agrupado": "AGR1",
            "tipo_operacao": "0 - ESTOQUE INICIAL",
            "qtd": 10.0,
            "q_conv": 10.0,
            "periodo_inventario": None,
            "saldo_estoque_anual": 10.0,
        },
        {
            "id_agrupado": "AGR1",
            "tipo_operacao": "3 - ESTOQUE FINAL",
            "qtd": 8.0,
            "q_conv": 2.0,
            "periodo_inventario": 1,
            "__qtd_decl_final_audit__": None,
            "saldo_estoque_anual": 8.0,
        },
    ])
    mensal_df = pl.DataFrame([
        {
            "id_agregado": "AGR1",
            "ano": 2024,
            "mes": 1,
            "ST": "SEM ST",
            "ICMS_entr_desacob": 0.0,
        }
    ])
    anual_df = pl.DataFrame([
        {
            "id_agregado": "AGR1",
            "ano": 2024,
            "ST": "SEM ST",
            "ICMS_saidas_desac": 0.0,
            "ICMS_estoque_desac": 0.0,
        }
    ])
    periodos_df = pl.DataFrame([
        {
            "id_agregado": "AGR1",
            "cod_per": 1,
            "data_inicio": date(2024, 2, 1),
            "data_fim": date(2024, 1, 31),
            "periodo_label": None,
            "ST": "SEM ST",
            "ICMS_saidas_desac": 0.0,
            "ICMS_estoque_desac": 0.0,
        },
        {
            "id_agregado": "AGR1",
            "cod_per": 1,
            "data_inicio": date(2024, 2, 1),
            "data_fim": date(2024, 2, 29),
            "periodo_label": "01/02/2024 até 29/02/2024",
            "ST": "SEM ST",
            "ICMS_saidas_desac": 0.0,
            "ICMS_estoque_desac": 0.0,
        },
    ])

    datasets = {
        "mov_estoque": mov_df,
        "aba_mensal": mensal_df,
        "aba_anual": anual_df,
        "aba_periodos": periodos_df,
    }
    monkeypatch.setattr(service, "_load_gold", lambda cnpj, name: datasets[name])

    payload = service.get_gold_consistency("123")

    assert payload["ok"] is False
    assert payload["inventory_contract"]["linhas_estoque_inicial_sem_periodo"] == 1
    assert payload["inventory_contract"]["linhas_estoque_final_sem_qtd_decl_final_audit"] == 1
    assert payload["inventory_contract"]["linhas_estoque_final_com_q_conv_nao_zero"] == 1
    assert payload["periodos_contract"]["linhas_sem_periodo_label"] == 1
    assert payload["periodos_contract"]["linhas_com_janela_invertida"] == 1
    assert payload["periodos_contract"]["chaves_duplicadas"] == 1


def test_get_gold_consistency_accepts_inventory_and_period_contracts_when_valid(monkeypatch) -> None:
    mov_df = pl.DataFrame([
        {
            "id_agrupado": "AGR1",
            "tipo_operacao": "0 - ESTOQUE INICIAL",
            "qtd": 10.0,
            "q_conv": 10.0,
            "periodo_inventario": 1,
            "saldo_estoque_anual": 10.0,
        },
        {
            "id_agrupado": "AGR1",
            "tipo_operacao": "3 - ESTOQUE FINAL",
            "qtd": 8.0,
            "q_conv": 0.0,
            "periodo_inventario": 1,
            "__qtd_decl_final_audit__": 8.0,
            "saldo_estoque_anual": 8.0,
        },
    ])
    mensal_df = pl.DataFrame([
        {
            "id_agregado": "AGR1",
            "ano": 2024,
            "mes": 1,
            "ST": "SEM ST",
            "ICMS_entr_desacob": 0.0,
        }
    ])
    anual_df = pl.DataFrame([
        {
            "id_agregado": "AGR1",
            "ano": 2024,
            "ST": "SEM ST",
            "ICMS_saidas_desac": 0.0,
            "ICMS_estoque_desac": 0.0,
        }
    ])
    periodos_df = pl.DataFrame([
        {
            "id_agregado": "AGR1",
            "cod_per": 1,
            "data_inicio": date(2024, 1, 1),
            "data_fim": date(2024, 1, 31),
            "periodo_label": "01/01/2024 até 31/01/2024",
            "ST": "SEM ST",
            "ICMS_saidas_desac": 0.0,
            "ICMS_estoque_desac": 0.0,
        }
    ])

    datasets = {
        "mov_estoque": mov_df,
        "aba_mensal": mensal_df,
        "aba_anual": anual_df,
        "aba_periodos": periodos_df,
    }
    monkeypatch.setattr(service, "_load_gold", lambda cnpj, name: datasets[name])

    payload = service.get_gold_consistency("123")

    assert payload["ok"] is True
    assert payload["inventory_contract"]["ok"] is True
    assert payload["periodos_contract"]["ok"] is True
