from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from database import get_db, settings
from models import Usuario
from schemas import LoginRequest, RefreshRequest, TokenResponse

router = APIRouter(prefix="/auth", tags=["auth"])
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
PERFIS_MOBILE = ["COLABORADOR_EXTERNO", "SUPERVISOR_EQUIPE", "ASSESSOR_NIVEL_1"]


def create_token(data: dict, expires_delta: timedelta) -> str:
    to_encode = data.copy()
    to_encode["exp"] = datetime.utcnow() + expires_delta
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def verify_token(token: str) -> dict:
    try:
        return jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
    except JWTError as exc:
        raise HTTPException(status_code=401, detail="Token inválido ou expirado") from exc


@router.post("/login", response_model=TokenResponse)
def login(req: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(Usuario).filter(Usuario.email_login == req.email, Usuario.ativo.is_(True)).first()
    if not user or not pwd_context.verify(req.senha, user.senha_hash):
        raise HTTPException(status_code=401, detail="Credenciais inválidas")
    if user.perfil not in PERFIS_MOBILE:
        raise HTTPException(status_code=403, detail="Perfil sem acesso ao app mobile")

    user.ultimo_login = datetime.utcnow()
    db.commit()

    payload = {
        "sub": user.id,
        "gabinete_id": user.gabinete_id,
        "perfil": user.perfil,
        "nome": user.nome,
    }
    access = create_token(payload, timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES))
    refresh = create_token(
        {"sub": user.id, "type": "refresh"},
        timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
    )
    return TokenResponse(
        access_token=access,
        refresh_token=refresh,
        perfil=user.perfil,
        nome=user.nome,
        gabinete_id=user.gabinete_id,
    )


@router.post("/refresh", response_model=TokenResponse)
def refresh(req: RefreshRequest, db: Session = Depends(get_db)):
    payload = verify_token(req.refresh_token)
    if payload.get("type") != "refresh":
        raise HTTPException(status_code=401, detail="Token inválido")

    user = db.query(Usuario).filter(Usuario.id == payload["sub"]).first()
    if not user or not user.ativo:
        raise HTTPException(status_code=401, detail="Usuário inativo")

    new_payload = {
        "sub": user.id,
        "gabinete_id": user.gabinete_id,
        "perfil": user.perfil,
        "nome": user.nome,
    }
    access = create_token(new_payload, timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES))
    new_refresh = create_token(
        {"sub": user.id, "type": "refresh"},
        timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
    )
    return TokenResponse(
        access_token=access,
        refresh_token=new_refresh,
        perfil=user.perfil,
        nome=user.nome,
        gabinete_id=user.gabinete_id,
    )
