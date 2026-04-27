from sqlalchemy import create_engine, inspect, text
from sqlalchemy.orm import declarative_base, sessionmaker
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    DATABASE_URL: str = "sqlite:///./gabinete_ia.db"
    SECRET_KEY: str = "change-me"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


settings = Settings()


def normalize_database_url(database_url: str) -> str:
    url = database_url.strip()
    if not url or url.lower() == "failed":
        raise RuntimeError(
            "DATABASE_URL invalida. Configure a Internal Database URL do PostgreSQL "
            "do Render na variavel DATABASE_URL."
        )
    if url.startswith("postgres://"):
        return url.replace("postgres://", "postgresql+psycopg://", 1)
    if url.startswith("postgresql://"):
        return url.replace("postgresql://", "postgresql+psycopg://", 1)
    return url


database_url = normalize_database_url(settings.DATABASE_URL)
connect_args = {"check_same_thread": False} if database_url.startswith("sqlite") else {}
engine = create_engine(database_url, connect_args=connect_args)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


CONTACT_SCHEMA_PATCHES = {
    "nivel_relacionamento": "VARCHAR(50) DEFAULT 'CONTATO'",
    "engajamento": "VARCHAR(20) DEFAULT 'FRIO'",
    "eh_lideranca": "BOOLEAN DEFAULT 0",
    "eh_apoiador": "BOOLEAN DEFAULT 0",
    "eh_beneficiario": "BOOLEAN DEFAULT 0",
    "eh_parceria": "BOOLEAN DEFAULT 0",
    "beneficiario_polo": "BOOLEAN DEFAULT 0",
    "polo_nome": "VARCHAR(150)",
    "codigo_revisa": "VARCHAR(80)",
    "revisa_sync_status": "VARCHAR(30) DEFAULT 'NAO_ENVIADO'",
    "foto_base64": "TEXT",
}


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def ensure_contact_schema() -> None:
    inspector = inspect(engine)
    if "cidadao_contato" not in inspector.get_table_names():
        return

    existing_columns = {column["name"] for column in inspector.get_columns("cidadao_contato")}
    missing = [
        (name, ddl)
        for name, ddl in CONTACT_SCHEMA_PATCHES.items()
        if name not in existing_columns
    ]
    if not missing:
        return

    with engine.begin() as conn:
      for name, ddl in missing:
            conn.execute(text(f"ALTER TABLE cidadao_contato ADD COLUMN {name} {ddl}"))
