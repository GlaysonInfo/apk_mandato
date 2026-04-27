import os

from passlib.context import CryptContext

from database import SessionLocal
from models import Equipe, Gabinete, Usuario

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

DEMO_GABINETE_ID = "demo-gabinete"
DEMO_EQUIPE_ID = "demo-equipe"
DEMO_USER_ID = "demo-user"
DEMO_EMAIL = os.getenv("DEMO_USER_EMAIL", "demo@gabinete.local")
DEMO_PASSWORD = os.getenv("DEMO_USER_PASSWORD", "123456")


def seed_demo_data() -> None:
    db = SessionLocal()
    try:
        gabinete = db.query(Gabinete).filter(Gabinete.id == DEMO_GABINETE_ID).first()
        if not gabinete:
            gabinete = Gabinete(
                id=DEMO_GABINETE_ID,
                nome="Gabinete IA Demo",
                sigla="GIA",
                descricao="Ambiente inicial do app mobile",
            )
            db.add(gabinete)

        equipe = db.query(Equipe).filter(Equipe.id == DEMO_EQUIPE_ID).first()
        if not equipe:
            equipe = Equipe(
                id=DEMO_EQUIPE_ID,
                gabinete_id=DEMO_GABINETE_ID,
                nome="Equipe de Campo",
                descricao="Equipe demo para acesso inicial",
                supervisor_usuario_id=DEMO_USER_ID,
            )
            db.add(equipe)

        user = db.query(Usuario).filter(Usuario.email_login == DEMO_EMAIL).first()
        if not user:
            user = Usuario(
                id=DEMO_USER_ID,
                gabinete_id=DEMO_GABINETE_ID,
                equipe_id=DEMO_EQUIPE_ID,
                nome="Usuario Demo",
                email_login=DEMO_EMAIL,
                telefone="",
                senha_hash=pwd_context.hash(DEMO_PASSWORD),
                perfil="COLABORADOR_EXTERNO",
                ativo=True,
            )
            db.add(user)

        db.commit()
    finally:
        db.close()
