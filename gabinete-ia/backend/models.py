import uuid
from datetime import datetime

from sqlalchemy import Boolean, Column, Date, DateTime, ForeignKey, String, Text

from database import Base


def gen_uuid() -> str:
    return str(uuid.uuid4())


class Gabinete(Base):
    __tablename__ = "gabinete"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    nome = Column(String(150), nullable=False)
    sigla = Column(String(50))
    descricao = Column(Text)
    ativo = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class Equipe(Base):
    __tablename__ = "equipe"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    gabinete_id = Column(String(36), ForeignKey("gabinete.id"), nullable=False)
    nome = Column(String(150), nullable=False)
    descricao = Column(Text)
    supervisor_usuario_id = Column(String(36), nullable=True)
    ativo = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class Usuario(Base):
    __tablename__ = "usuario"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    gabinete_id = Column(String(36), ForeignKey("gabinete.id"), nullable=False)
    equipe_id = Column(String(36), ForeignKey("equipe.id"), nullable=True)
    nome = Column(String(150), nullable=False)
    email_login = Column(String(150), nullable=False, unique=True)
    telefone = Column(String(20))
    senha_hash = Column(Text, nullable=False)
    perfil = Column(String(50), nullable=False)
    ultimo_login = Column(DateTime, nullable=True)
    mfa_habilitado = Column(Boolean, default=False)
    ativo = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class Territorio(Base):
    __tablename__ = "territorio"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    gabinete_id = Column(String(36), ForeignKey("gabinete.id"), nullable=False)
    parent_id = Column(String(36), ForeignKey("territorio.id"), nullable=True)
    nome = Column(String(150), nullable=False)
    tipo = Column(String(30), nullable=False)
    codigo_externo = Column(String(50))
    ativo = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class CidadaoContato(Base):
    __tablename__ = "cidadao_contato"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    gabinete_id = Column(String(36), ForeignKey("gabinete.id"), nullable=False)
    territorio_id = Column(String(36), ForeignKey("territorio.id"), nullable=True)
    origem_cadastro = Column(String(30), nullable=False, default="MOBILE_CAMPO")
    nome = Column(String(150), nullable=False)
    cpf = Column(String(14), nullable=True)
    data_nascimento = Column(Date, nullable=True)
    telefone_principal = Column(String(20))
    telefone_secundario = Column(String(20))
    email = Column(String(150))
    logradouro = Column(Text)
    numero = Column(String(20))
    complemento = Column(String(100))
    bairro = Column(String(100))
    cidade = Column(String(100))
    cep = Column(String(10))
    tipo_contato = Column(String(50), default="CIDADAO")
    nivel_relacionamento = Column(String(50), default="CONTATO")
    engajamento = Column(String(20), default="FRIO")
    eh_lideranca = Column(Boolean, default=False)
    eh_apoiador = Column(Boolean, default=False)
    eh_beneficiario = Column(Boolean, default=False)
    eh_parceria = Column(Boolean, default=False)
    beneficiario_polo = Column(Boolean, default=False)
    polo_nome = Column(String(150))
    codigo_revisa = Column(String(80))
    revisa_sync_status = Column(String(30), default="NAO_ENVIADO")
    foto_base64 = Column(Text)
    status = Column(String(30), default="ATIVO")
    duplicidade_suspeita = Column(Boolean, default=False)
    consentimento_registrado = Column(Boolean, default=False)
    canal_permitido = Column(String(100))
    observacoes = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class Demanda(Base):
    __tablename__ = "demanda"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    gabinete_id = Column(String(36), ForeignKey("gabinete.id"), nullable=False)
    cidadao_id = Column(String(36), ForeignKey("cidadao_contato.id"), nullable=True)
    territorio_id = Column(String(36), ForeignKey("territorio.id"), nullable=True)
    titulo = Column(String(200), nullable=False)
    descricao = Column(Text, nullable=False)
    categoria = Column(String(50))
    prioridade = Column(String(20), default="MEDIA")
    status = Column(String(30), default="ABERTA")
    responsavel_usuario_id = Column(String(36), ForeignKey("usuario.id"), nullable=True)
    origem_cadastro = Column(String(30), default="MOBILE_CAMPO")
    data_abertura = Column(DateTime, default=datetime.utcnow)
    sla_data = Column(DateTime, nullable=True)
    data_conclusao = Column(DateTime, nullable=True)
    motivo_reabertura = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class VisitaCampo(Base):
    __tablename__ = "visita_campo"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    gabinete_id = Column(String(36), ForeignKey("gabinete.id"), nullable=False)
    usuario_id = Column(String(36), ForeignKey("usuario.id"), nullable=False)
    cidadao_id = Column(String(36), ForeignKey("cidadao_contato.id"), nullable=True)
    territorio_id = Column(String(36), ForeignKey("territorio.id"), nullable=True)
    tipo = Column(String(50), default="VISITA_DOMICILIAR")
    data_hora = Column(DateTime, nullable=False)
    resultado = Column(String(50), default="REALIZADA")
    observacao = Column(Text)
    evidencia_url = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)


class AgendaItem(Base):
    __tablename__ = "agenda_item"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    gabinete_id = Column(String(36), ForeignKey("gabinete.id"), nullable=False)
    usuario_id = Column(String(36), ForeignKey("usuario.id"), nullable=False)
    titulo = Column(String(200), nullable=False)
    descricao = Column(Text)
    data_hora_inicio = Column(DateTime, nullable=False)
    data_hora_fim = Column(DateTime)
    territorio_id = Column(String(36), ForeignKey("territorio.id"), nullable=True)
    status = Column(String(30), default="AGENDADO")
    created_at = Column(DateTime, default=datetime.utcnow)


class SyncMobile(Base):
    __tablename__ = "sync_mobile"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    gabinete_id = Column(String(36), ForeignKey("gabinete.id"), nullable=False)
    usuario_id = Column(String(36), ForeignKey("usuario.id"), nullable=False)
    client_generated_id = Column(String(100), nullable=False, unique=True)
    entidade = Column(String(50), nullable=False)
    entidade_id = Column(String(36), nullable=True)
    status = Column(String(20), default="PROCESSADO")
    hash_payload = Column(String(64))
    mensagem_erro = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
