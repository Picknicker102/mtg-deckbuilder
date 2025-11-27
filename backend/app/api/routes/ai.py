from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from ...services.openai_client import OpenAIClient

router = APIRouter()


class AiSuggestRequest(BaseModel):
    commander: str
    colors: list[str]
    rc_mode: str = "hybrid"
    output_mode: str = "deck+analysis"
    deck_state: dict | None = None


class AiSuggestResponse(BaseModel):
    suggestions: list[str] = Field(default_factory=list)
    raw_response: str | None = None


@router.post("/suggest", response_model=AiSuggestResponse)
async def suggest_cards(
    payload: AiSuggestRequest,
    client: OpenAIClient = Depends(OpenAIClient.dependency),
) -> AiSuggestResponse:
    response = await client.generate_deck_suggestions(
        commander=payload.commander,
        colors=payload.colors,
        rc_mode=payload.rc_mode,
        output_mode=payload.output_mode,
        deck_state=payload.deck_state or {},
    )
    return AiSuggestResponse(
        suggestions=response.suggestions,
        raw_response=response.raw_response,
    )
