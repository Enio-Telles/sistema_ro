from backend.app.services.fisconforme_notification_service_v2 import _table_text_v2


def test_table_text_v2_returns_placeholder_when_empty() -> None:
    assert _table_text_v2([]) == '(Sem pendências registradas)'


def test_table_text_v2_renders_basic_line() -> None:
    result = _table_text_v2([
        {
            'id_pendencia': '1',
            'id_notificacao': '2',
            'titulo_malha': 'Pendência X',
            'periodo': '202401',
            'status_pendencia': 'ABERTA',
        }
    ])
    assert 'Pendência X' in result
    assert 'ABERTA' in result
