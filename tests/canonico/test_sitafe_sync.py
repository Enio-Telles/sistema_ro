"""Testes de ``sistema_ro.sitafe_sync``."""

from __future__ import annotations

from pathlib import Path

from sistema_ro.sitafe_sync import (
    ARQUIVOS_ESPERADOS,
    StatusSincronizacao,
    sincronizar_sitafe,
)


def _touch(path: Path, conteudo: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(conteudo)


def test_sincroniza_arquivo_novo(tmp_path: Path):
    fonte = tmp_path / "fonte"
    destino = tmp_path / "destino"
    for nome in ARQUIVOS_ESPERADOS:
        _touch(fonte / nome, f"conteudo-{nome}".encode())

    rel = sincronizar_sitafe(fonte, destino)

    assert {r.nome for r in rel} == set(ARQUIVOS_ESPERADOS)
    assert all(r.status is StatusSincronizacao.NOVO for r in rel)
    # arquivos materializados
    for nome in ARQUIVOS_ESPERADOS:
        assert (destino / nome).exists()


def test_sincroniza_inalterado_quando_hash_bate(tmp_path: Path):
    fonte = tmp_path / "fonte"
    destino = tmp_path / "destino"
    destino.mkdir()
    for nome in ARQUIVOS_ESPERADOS:
        _touch(fonte / nome, b"mesmo-conteudo")
        _touch(destino / nome, b"mesmo-conteudo")

    rel = sincronizar_sitafe(fonte, destino)
    assert all(r.status is StatusSincronizacao.INALTERADO for r in rel)
    assert all(r.bytes_copiados == 0 for r in rel)


def test_sincroniza_atualizado_quando_hash_difere(tmp_path: Path):
    fonte = tmp_path / "fonte"
    destino = tmp_path / "destino"
    destino.mkdir()
    nome = "sitafe_ncm.parquet"
    _touch(fonte / nome, b"novo")
    _touch(destino / nome, b"antigo")

    rel = sincronizar_sitafe(fonte, destino, arquivos=(nome,))
    assert rel[0].status is StatusSincronizacao.ATUALIZADO
    assert (destino / nome).read_bytes() == b"novo"


def test_dry_run_nao_escreve(tmp_path: Path):
    fonte = tmp_path / "fonte"
    destino = tmp_path / "destino"
    destino.mkdir()
    nome = "sitafe_cest.parquet"
    _touch(fonte / nome, b"novo")
    # no destino não existe

    rel = sincronizar_sitafe(fonte, destino, dry_run=True, arquivos=(nome,))
    assert rel[0].status is StatusSincronizacao.NOVO
    assert rel[0].bytes_copiados > 0
    assert not (destino / nome).exists()


def test_removido_na_fonte_sem_permissao(tmp_path: Path):
    fonte = tmp_path / "fonte"
    fonte.mkdir()
    destino = tmp_path / "destino"
    destino.mkdir()
    nome = "sitafe_cest.parquet"
    _touch(destino / nome, b"antigo")

    rel = sincronizar_sitafe(fonte, destino, arquivos=(nome,))
    assert rel[0].status is StatusSincronizacao.REMOVIDO_NA_FONTE
    assert (destino / nome).exists()  # preservado


def test_removido_na_fonte_com_permissao(tmp_path: Path):
    fonte = tmp_path / "fonte"
    fonte.mkdir()
    destino = tmp_path / "destino"
    destino.mkdir()
    nome = "sitafe_cest.parquet"
    _touch(destino / nome, b"antigo")

    sincronizar_sitafe(fonte, destino, arquivos=(nome,), permitir_remocao=True)
    assert not (destino / nome).exists()


def test_ausente_em_ambos(tmp_path: Path):
    rel = sincronizar_sitafe(tmp_path / "f", tmp_path / "d")
    assert all(r.status is StatusSincronizacao.AUSENTE_NA_FONTE for r in rel)
