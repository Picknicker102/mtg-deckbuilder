from fastapi import APIRouter

from .ai import router as ai_router
from .analysis import router as analysis_router
from .cards import router as cards_router
from .deck_build import router as deck_build_router
from .decks import router as decks_router
from .health import router as health_router

api_router = APIRouter()
api_router.include_router(health_router, tags=["health"])
api_router.include_router(decks_router, tags=["decks"])
api_router.include_router(deck_build_router, tags=["decks"])
api_router.include_router(analysis_router, tags=["analysis"])
api_router.include_router(cards_router)
# ai_router already defines prefix="/ai"
api_router.include_router(ai_router, tags=["ai"])
