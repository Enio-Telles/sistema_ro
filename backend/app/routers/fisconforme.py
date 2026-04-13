from fastapi import APIRouter

router = APIRouter()


@router.post("/consulta-cadastral")
def consulta_cadastral() -> dict:
    return {"domain": "fisconforme", "mode": "single", "status": "todo"}


@router.post("/consulta-lote")
def consulta_lote() -> dict:
    return {"domain": "fisconforme", "mode": "lote", "status": "todo"}


@router.post("/gerar-notificacao")
def gerar_notificacao() -> dict:
    return {"domain": "fisconforme", "artifact": "txt", "status": "todo"}


@router.post("/gerar-notificacoes-lote")
def gerar_notificacoes_lote() -> dict:
    return {"domain": "fisconforme", "artifact": "zip", "status": "todo"}
