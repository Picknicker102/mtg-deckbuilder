from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .api.routes import api_router
from .core.config import settings

app = FastAPI(
    title="MTG Commander Backend",
    version="0.1.0",
    debug=settings.backend_env != "prod",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router)


@app.get("/")
def root() -> dict:
    return {"message": "MTG Commander backend up", "env": settings.backend_env}
