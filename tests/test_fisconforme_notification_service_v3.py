from backend.app.services.fisconforme_notification_service_v3 import _html_table_v3


def test_html_table_v3_returns_placeholder_when_empty() -> None:
    assert '(Sem pendências registradas)' in _html_table_v3([])


def test_html_table_v3_renders_html_table() -> None:
    html = _html_table_v3([
        {
            'id_pendencia': '1',
            'id_notificacao': '2',
            'titulo_malha': 'Pendência X',
            'periodo': '202401',
            'status_pendencia': 'ABERTA',
        }
    ])
    assert '<table' in html
    assert 'Pendência X' in html
    assert 'ABERTA' in html
