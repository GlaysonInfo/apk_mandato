import uuid
from typing import List

from fastapi import APIRouter, Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from database import get_db
from models import VisitaCampo
from schemas import VisitaCreate, VisitaOut
from .auth import verify_token

router = APIRouter(prefix="/visitas", tags=["visitas"])
bearer = HTTPBearer()


def get_current_user(cred: HTTPAuthorizationCredentials = Depends(bearer)):
    return verify_token(cred.credentials)


@router.post("/", response_model=VisitaOut)
def criar_visita(
    data: VisitaCreate,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    visita = VisitaCampo(
        id=str(uuid.uuid4()),
        gabinete_id=user["gabinete_id"],
        usuario_id=user["sub"],
        **data.model_dump(),
    )
    db.add(visita)
    db.commit()
    db.refresh(visita)
    return visita


@router.get("/", response_model=List[VisitaOut])
def listar_visitas(db: Session = Depends(get_db), user=Depends(get_current_user)):
    return (
        db.query(VisitaCampo)
        .filter(
            VisitaCampo.gabinete_id == user["gabinete_id"],
            VisitaCampo.usuario_id == user["sub"],
        )
        .all()
    )
