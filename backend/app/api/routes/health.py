from fastapi import APIRouter

from ...core.config import settings

router = APIRouter()


@router.get("/health")
def healthcheck() -> dict:
    return {
        "status": "ok",
        "environment": settings.backend_env,
        "database_url": settings.database_url,
        "openai_model": settings.openai_model,
    }
