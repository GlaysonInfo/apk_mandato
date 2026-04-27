import uuid
from typing import List

from fastapi import APIRouter, Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from database import get_db
from models import Demanda
from schemas import DemandaCreate, DemandaOut
from .auth import verify_token

router = APIRouter(prefix="/demandas", tags=["demandas"])
bearer = HTTPBearer()


def get_current_user(cred: HTTPAuthorizationCredentials = Depends(bearer)):
    return verify_token(cred.credentials)


@router.post("/", response_model=DemandaOut)
def criar_demanda(
    data: DemandaCreate,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    demanda = Demanda(
        id=str(uuid.uuid4()),
        gabinete_id=user["gabinete_id"],
        responsavel_usuario_id=user["sub"],
        origem_cadastro="MOBILE_CAMPO",
        **data.model_dump(),
    )
    db.add(demanda)
    db.commit()
    db.refresh(demanda)
    return demanda


@router.get("/", response_model=List[DemandaOut])
def listar_demandas(
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
    skip: int = 0,
    limit: int = 50,
):
    return (
        db.query(Demanda)
        .filter(
            Demanda.gabinete_id == user["gabinete_id"],
            Demanda.responsavel_usuario_id == user["sub"],
        )
        .offset(skip)
        .limit(limit)
        .all()
    )
