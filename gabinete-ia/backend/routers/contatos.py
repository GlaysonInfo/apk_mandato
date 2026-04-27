import uuid
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from database import get_db
from models import CidadaoContato
from schemas import ContatoCreate, ContatoOut
from .auth import verify_token

router = APIRouter(prefix="/contatos", tags=["contatos"])
bearer = HTTPBearer()


def get_current_user(cred: HTTPAuthorizationCredentials = Depends(bearer)):
    return verify_token(cred.credentials)


@router.post("/", response_model=ContatoOut)
def criar_contato(
    data: ContatoCreate,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    dup = False
    if data.cpf:
        existe = db.query(CidadaoContato).filter(
            CidadaoContato.cpf == data.cpf,
            CidadaoContato.gabinete_id == user["gabinete_id"],
        ).first()
        dup = existe is not None
    elif data.telefone_principal:
        existe = db.query(CidadaoContato).filter(
            CidadaoContato.telefone_principal == data.telefone_principal,
            CidadaoContato.gabinete_id == user["gabinete_id"],
        ).first()
        dup = existe is not None

    contato = CidadaoContato(
        id=str(uuid.uuid4()),
        gabinete_id=user["gabinete_id"],
        origem_cadastro="MOBILE_CAMPO",
        duplicidade_suspeita=dup,
        **data.model_dump(),
    )
    db.add(contato)
    db.commit()
    db.refresh(contato)
    return contato


@router.get("/", response_model=List[ContatoOut])
def listar_contatos(
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
    skip: int = 0,
    limit: int = 50,
    q: Optional[str] = None,
):
    query = db.query(CidadaoContato).filter(CidadaoContato.gabinete_id == user["gabinete_id"])
    if q:
        query = query.filter(CidadaoContato.nome.ilike(f"%{q}%"))
    return query.offset(skip).limit(limit).all()


@router.get("/{contato_id}", response_model=ContatoOut)
def obter_contato(
    contato_id: str,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    contato = db.query(CidadaoContato).filter(
        CidadaoContato.id == contato_id,
        CidadaoContato.gabinete_id == user["gabinete_id"],
    ).first()
    if not contato:
        raise HTTPException(status_code=404, detail="Contato não encontrado")
    return contato
