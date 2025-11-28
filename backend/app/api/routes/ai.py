import json
from typing import List

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from ...services.openai_client import run_agent
from ...services.scryfall_client import get_card_by_name

router = APIRouter(prefix="/ai", tags=["ai"])


class CardEntryIn(BaseModel):
    name: str
    quantity: int
    mana_value: float | None = None
    color_identity: List[str] | None = None
    types: List[str] | None = None


class DeckStateIn(BaseModel):
    commander_name: str
    colors: List[str]
    cards: List[CardEntryIn]
    meta: dict | None = None


class SuggestedCard(BaseModel):
    name: str
    reason: str
    synergy_tags: List[str] | None = None
    image_url: str | None = None
    mana_cost: str | None = None
    type_line: str | None = None


class DeckSuggestionResponse(BaseModel):
    suggestions: List[SuggestedCard]
    explanation: str


class SynergyRequest(BaseModel):
    commander_name: str
    colors: List[str]
    deck: List[str] = Field(default_factory=list)


class SynergyResponse(BaseModel):
    suggestions: List[SuggestedCard]
    note: str


def _deck_summary(deck: DeckStateIn) -> str:
    top_cards = ", ".join([c.name for c in deck.cards[:10]])
    total = sum(c.quantity for c in deck.cards)
    return (
        f"Commander: {deck.commander_name}. Colors: {', '.join(deck.colors)}. "
        f"Cards total: {total}. Key cards: {top_cards}. Meta: {deck.meta}"
    )


def _parse_suggestions(output: str) -> List[dict]:
    cleaned = output.strip()
    if cleaned.startswith("```"):
        cleaned = cleaned.strip("`")
        if cleaned.startswith("json"):
            cleaned = cleaned[4:]
    cleaned = cleaned.strip()
    try:
        data = json.loads(cleaned)
        if isinstance(data, dict) and "suggestions" in data:
            return data["suggestions"]
        if isinstance(data, list):
            return data
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"OpenAI output parsing failed: {exc}") from exc
    raise HTTPException(status_code=502, detail="OpenAI output malformed")


@router.post("/suggest-deck", response_model=DeckSuggestionResponse)
async def suggest_deck(payload: DeckStateIn) -> DeckSuggestionResponse:
    summary = _deck_summary(payload)
    user_input = (
        f"{summary}\n"
        "Return STRICT JSON array with objects: "
        '{"name": "...", "reason": "...", "synergy_tags": ["..."]}. '
        "No prose outside JSON."
    )
    try:
        raw = await run_agent("deck_suggestion", user_input)
    except Exception as exc:  # surface OpenAI errors as 502
        raise HTTPException(status_code=502, detail=f"OpenAI agent failed: {exc}") from exc

    suggestions_raw = _parse_suggestions(raw)

    enriched_cards: list[SuggestedCard] = []
    for item in suggestions_raw:
        if not isinstance(item, dict) or "name" not in item:
            continue
        card_name = item.get("name")
        reason = item.get("reason", "")
        synergy_tags = item.get("synergy_tags", None)

        try:
            card_data = await get_card_by_name(card_name, fuzzy=True)
        except Exception as exc:
            card_data = {"name": card_name, "mana_cost": None, "type_line": None, "image_url": None}

        enriched_cards.append(
            SuggestedCard(
                name=card_data.get("name", card_name),
                reason=reason,
                synergy_tags=synergy_tags if isinstance(synergy_tags, list) else None,
                image_url=card_data.get("image_url"),
                mana_cost=card_data.get("mana_cost"),
                type_line=card_data.get("type_line"),
            )
        )

    if not enriched_cards:
        raise HTTPException(status_code=502, detail="No suggestions returned from OpenAI.")

    return DeckSuggestionResponse(
        suggestions=enriched_cards,
        explanation="AI-generated card picks enriched with Scryfall metadata.",
    )


@router.post("/synergy", response_model=SynergyResponse)
async def synergy(payload: SynergyRequest) -> SynergyResponse:
    deck_preview = payload.deck[:20]
    summary = (
        f"Commander: {payload.commander_name}. Colors: {', '.join(payload.colors)}. "
        f"Deck preview (max 20): {deck_preview}."
    )
    user_input = (
        f"{summary}\n"
        "Return STRICT JSON array with objects: "
        '{"name": "...", "reason": "...", "synergy_tags": ["..."]}. '
        "Max 5 items. No prose outside JSON."
    )
    try:
        raw = await run_agent("deck_synergy", user_input)
        parsed = _parse_suggestions(raw)
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"OpenAI agent failed: {exc}") from exc

    results: list[SuggestedCard] = []
    for item in parsed[:5]:
        if not isinstance(item, dict) or "name" not in item:
            continue
        card_name = item.get("name")
        reason = item.get("reason", "")
        synergy_tags = item.get("synergy_tags", None)
        try:
            card_data = await get_card_by_name(card_name, fuzzy=True)
        except Exception:
            card_data = {"name": card_name}
        results.append(
            SuggestedCard(
                name=card_data.get("name", card_name),
                reason=reason,
                synergy_tags=synergy_tags if isinstance(synergy_tags, list) else None,
                image_url=card_data.get("image_url"),
                mana_cost=card_data.get("mana_cost"),
                type_line=card_data.get("type_line"),
            )
        )
    if not results:
        raise HTTPException(status_code=502, detail="No synergy suggestions returned from OpenAI.")
    return SynergyResponse(suggestions=results, note="Synergy suggestions generated via OpenAI.")
