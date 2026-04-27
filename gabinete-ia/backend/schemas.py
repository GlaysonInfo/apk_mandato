from datetime import date, datetime
from typing import List, Optional

from pydantic import BaseModel


class LoginRequest(BaseModel):
    email: str
    senha: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    perfil: str
    nome: str
    gabinete_id: str


class RefreshRequest(BaseModel):
    refresh_token: str


class ContatoCreate(BaseModel):
    nome: str
    telefone_principal: Optional[str] = None
    telefone_secundario: Optional[str] = None
    email: Optional[str] = None
    cpf: Optional[str] = None
    data_nascimento: Optional[date] = None
    logradouro: Optional[str] = None
    numero: Optional[str] = None
    complemento: Optional[str] = None
    bairro: Optional[str] = None
    cidade: Optional[str] = None
    cep: Optional[str] = None
    territorio_id: Optional[str] = None
    tipo_contato: str = "CIDADAO"
    nivel_relacionamento: str = "CONTATO"
    engajamento: str = "FRIO"
    eh_lideranca: bool = False
    eh_apoiador: bool = False
    eh_beneficiario: bool = False
    eh_parceria: bool = False
    beneficiario_polo: bool = False
    polo_nome: Optional[str] = None
    codigo_revisa: Optional[str] = None
    revisa_sync_status: str = "NAO_ENVIADO"
    foto_base64: Optional[str] = None
    consentimento_registrado: bool = False
    canal_permitido: Optional[str] = None
    observacoes: Optional[str] = None


class ContatoOut(ContatoCreate):
    id: str
    gabinete_id: str
    status: str
    duplicidade_suspeita: bool
    origem_cadastro: str
    created_at: datetime

    class Config:
        from_attributes = True


class DemandaCreate(BaseModel):
    titulo: str
    descricao: str
    categoria: Optional[str] = None
    prioridade: str = "MEDIA"
    cidadao_id: Optional[str] = None
    territorio_id: Optional[str] = None


class DemandaOut(DemandaCreate):
    id: str
    gabinete_id: str
    status: str
    origem_cadastro: str
    data_abertura: datetime
    created_at: datetime

    class Config:
        from_attributes = True


class VisitaCreate(BaseModel):
    tipo: str = "VISITA_DOMICILIAR"
    data_hora: datetime
    resultado: str = "REALIZADA"
    observacao: Optional[str] = None
    cidadao_id: Optional[str] = None
    territorio_id: Optional[str] = None
    evidencia_url: Optional[str] = None


class VisitaOut(VisitaCreate):
    id: str
    gabinete_id: str
    usuario_id: str
    created_at: datetime

    class Config:
        from_attributes = True


class AgendaOut(BaseModel):
    id: str
    titulo: str
    descricao: Optional[str]
    data_hora_inicio: datetime
    data_hora_fim: Optional[datetime]
    status: str

    class Config:
        from_attributes = True


class SyncItem(BaseModel):
    client_generated_id: str
    entidade: str
    payload: dict


class SyncRequest(BaseModel):
    items: List[SyncItem]


class SyncResultItem(BaseModel):
    client_generated_id: str
    entidade: str
    entidade_id: Optional[str] = None
    status: str
    message: Optional[str] = None


class SyncResponse(BaseModel):
    processed: List[SyncResultItem]
    errors: List[SyncResultItem]


class TerritorioOut(BaseModel):
    id: str
    nome: str
    tipo: str
    parent_id: Optional[str]

    class Config:
        from_attributes = True
