from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from database import Base, engine, ensure_contact_schema
from routers import agenda, auth, contatos, demandas, sync, visitas

ALLOWED_ORIGINS = [
    "http://localhost:8085",
    "http://127.0.0.1:8085",
    "http://localhost:3000",
    "http://127.0.0.1:3000",
]

Base.metadata.create_all(bind=engine)
ensure_contact_schema()

app = FastAPI(
    title="Gabinete IA - API Mobile",
    version="1.0.0",
    description="Backend do App Mobile Campo - Gabinete IA",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(contatos.router)
app.include_router(demandas.router)
app.include_router(visitas.router)
app.include_router(agenda.router)
app.include_router(sync.router)


@app.get("/health")
def health():
    return {"status": "ok", "service": "gabinete-ia-api"}
