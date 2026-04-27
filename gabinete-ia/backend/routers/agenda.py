from datetime import date, datetime, time
from typing import List

from fastapi import APIRouter, Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from database import get_db
from models import AgendaItem
from schemas import AgendaOut
from .auth import verify_token

router = APIRouter(prefix="/agenda", tags=["agenda"])
bearer = HTTPBearer()


def get_current_user(cred: HTTPAuthorizationCredentials = Depends(bearer)):
    return verify_token(cred.credentials)


@router.get("/hoje", response_model=List[AgendaOut])
def agenda_hoje(db: Session = Depends(get_db), user=Depends(get_current_user)):
    hoje = date.today()
    inicio = datetime.combine(hoje, time.min)
    fim = datetime.combine(hoje, time.max)
    return (
        db.query(AgendaItem)
        .filter(
            AgendaItem.gabinete_id == user["gabinete_id"],
            AgendaItem.usuario_id == user["sub"],
            AgendaItem.data_hora_inicio >= inicio,
            AgendaItem.data_hora_inicio <= fim,
        )
        .all()
    )
