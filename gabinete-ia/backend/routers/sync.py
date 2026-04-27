import hashlib
import json
import uuid

from fastapi import APIRouter, Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from database import get_db
from models import CidadaoContato, Demanda, SyncMobile, VisitaCampo
from schemas import SyncRequest, SyncResponse, SyncResultItem
from .auth import verify_token

router = APIRouter(prefix="/mobile", tags=["sync"])
bearer = HTTPBearer()


def get_current_user(cred: HTTPAuthorizationCredentials = Depends(bearer)):
    return verify_token(cred.credentials)


def hash_payload(payload: dict) -> str:
    return hashlib.sha256(json.dumps(payload, sort_keys=True).encode()).hexdigest()


@router.post("/sync", response_model=SyncResponse)
def sync(req: SyncRequest, db: Session = Depends(get_db), user=Depends(get_current_user)):
    processed = []
    errors = []

    for item in req.items:
        existing = db.query(SyncMobile).filter(
            SyncMobile.client_generated_id == item.client_generated_id
        ).first()
        if existing:
            processed.append(
                SyncResultItem(
                    client_generated_id=item.client_generated_id,
                    entidade=item.entidade,
                    entidade_id=existing.entidade_id,
                    status="PROCESSADO",
                    message="Já processado anteriormente",
                )
            )
            continue

        try:
            entidade_id = str(uuid.uuid4())
            payload = item.payload
            hp = hash_payload(payload)

            if item.entidade == "contato":
                obj = CidadaoContato(
                    id=entidade_id,
                    gabinete_id=user["gabinete_id"],
                    origem_cadastro="MOBILE_CAMPO",
                    **{k: v for k, v in payload.items() if hasattr(CidadaoContato, k)},
                )
            elif item.entidade == "demanda":
                obj = Demanda(
                    id=entidade_id,
                    gabinete_id=user["gabinete_id"],
                    responsavel_usuario_id=user["sub"],
                    origem_cadastro="MOBILE_CAMPO",
                    **{k: v for k, v in payload.items() if hasattr(Demanda, k)},
                )
            elif item.entidade == "visita":
                obj = VisitaCampo(
                    id=entidade_id,
                    gabinete_id=user["gabinete_id"],
                    usuario_id=user["sub"],
                    **{k: v for k, v in payload.items() if hasattr(VisitaCampo, k)},
                )
            else:
                raise ValueError(f"Entidade desconhecida: {item.entidade}")

            db.add(obj)
            db.add(
                SyncMobile(
                    id=str(uuid.uuid4()),
                    gabinete_id=user["gabinete_id"],
                    usuario_id=user["sub"],
                    client_generated_id=item.client_generated_id,
                    entidade=item.entidade,
                    entidade_id=entidade_id,
                    status="PROCESSADO",
                    hash_payload=hp,
                )
            )
            db.commit()
            processed.append(
                SyncResultItem(
                    client_generated_id=item.client_generated_id,
                    entidade=item.entidade,
                    entidade_id=entidade_id,
                    status="PROCESSADO",
                )
            )
        except Exception as exc:
            db.rollback()
            db.add(
                SyncMobile(
                    id=str(uuid.uuid4()),
                    gabinete_id=user["gabinete_id"],
                    usuario_id=user["sub"],
                    client_generated_id=item.client_generated_id,
                    entidade=item.entidade,
                    status="ERRO",
                    mensagem_erro=str(exc),
                )
            )
            db.commit()
            errors.append(
                SyncResultItem(
                    client_generated_id=item.client_generated_id,
                    entidade=item.entidade,
                    status="ERRO",
                    message=str(exc),
                )
            )

    return SyncResponse(processed=processed, errors=errors)
