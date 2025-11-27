from __future__ import annotations

from typing import Any

import httpx
from fastapi import HTTPException

BASE_URL = "https://api.scryfall.com"
HEADERS = {
    "User-Agent": "MTGDeckbuilderApp/0.1 (contact: example@example.com)",
    "Accept": "application/json",
}


def _simplify_card(card: dict[str, Any]) -> dict[str, Any]:
    image_url = None
    if "image_uris" in card:
        image_url = card["image_uris"].get("normal") or card["image_uris"].get("large")
    elif "card_faces" in card and card["card_faces"]:
        faces = card["card_faces"]
        image_url = faces[0].get("image_uris", {}).get("normal")

    return {
        "name": card.get("name"),
        "mana_cost": card.get("mana_cost"),
        "type_line": card.get("type_line"),
        "oracle_text": card.get("oracle_text"),
        "color_identity": card.get("color_identity", []),
        "image_url": image_url,
    }


async def _fetch_json(path: str, params: dict[str, Any] | None = None) -> dict[str, Any]:
    async with httpx.AsyncClient(base_url=BASE_URL, headers=HEADERS, timeout=20) as client:
        response = await client.get(path, params=params)
        if response.status_code != 200:
            raise HTTPException(status_code=502, detail=f"Scryfall error: {response.text}")
        return response.json()


async def autocomplete_names(query: str) -> list[str]:
    payload = await _fetch_json("/cards/autocomplete", params={"q": query})
    return payload.get("data", [])


async def get_card_by_name(name: str, fuzzy: bool = True) -> dict[str, Any]:
    params = {"fuzzy": name} if fuzzy else {"exact": name}
    payload = await _fetch_json("/cards/named", params=params)
    return _simplify_card(payload)


async def search_cards(query: str, page: int = 1) -> list[dict[str, Any]]:
    payload = await _fetch_json("/cards/search", params={"q": query, "page": page})
    cards = payload.get("data", [])
    return [_simplify_card(card) for card in cards]
