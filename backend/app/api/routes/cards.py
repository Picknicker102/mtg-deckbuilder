from fastapi import APIRouter, HTTPException, Query

from ...services import scryfall_client

router = APIRouter(prefix="/cards", tags=["cards"])


@router.get("/autocomplete")
async def autocomplete_cards(q: str = Query(..., description="Text to autocomplete")) -> dict:
    suggestions = await scryfall_client.autocomplete_names(q)
    return {"suggestions": suggestions}


@router.get("/by-name")
async def card_by_name(name: str, fuzzy: bool = True) -> dict:
    if not name:
        raise HTTPException(status_code=400, detail="name is required")
    card = await scryfall_client.get_card_by_name(name, fuzzy=fuzzy)
    return card
