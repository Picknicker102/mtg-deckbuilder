from datetime import datetime
from typing import List

from fastapi import APIRouter
from pydantic import BaseModel, Field

router = APIRouter(prefix="/decks")


class DeckMeta(BaseModel):
    rc_mode: str = "hybrid"
    output_mode: str = "deck+analysis"
    allow_loops: bool = False
    power_level: str = "7"
    meta_speed: str = "mid"
    budget: str = "mid"
    language: str = "DE"


class DeckCounts(BaseModel):
    lands: int = 0
    ramp: int = 0
    draw: int = 0
    interaction: int = 0
    protection: int = 0
    wincons: int = 0


class DeckStatus(BaseModel):
    has_banned_cards: bool = False
    has_ci_violations: bool = False
    is_valid_100: bool = False
    last_validation_message: str = ""


class CardEntry(BaseModel):
    name: str
    quantity: int = 1
    mana_value: float = 0
    color_identity: List[str] = Field(default_factory=list)
    types: List[str] = Field(default_factory=list)
    tags: List[str] = Field(default_factory=list)
    is_banned: bool = False
    is_from_overrides: bool = False
    is_outside_color_identity: bool = False
    location_code_from_pool: str | None = None


class DeckOut(BaseModel):
    id: str
    name: str
    commander_name: str
    colors: List[str]
    cards: List[CardEntry]
    meta: DeckMeta
    counts: DeckCounts
    status: DeckStatus
    validation_line: str
    created_at: datetime
    updated_at: datetime


@router.get("", response_model=List[DeckOut])
def list_decks() -> List[DeckOut]:
    validation_line = (
        "Validation: 100/100✔️ RC-Snapshot✔️ RC-Sync AB (Modus: hybrid)✔️ "
        "Commander-legal✔️ CI✔️ Moxfield-ready✔️"
    )
    mock_cards = [
        CardEntry(
            name="Sonic the Hedgehog",
            quantity=1,
            mana_value=4,
            color_identity=["U", "R"],
            types=["Legendary", "Creature"],
            tags=["Commander", "UB Override"],
            is_from_overrides=True,
        ),
        CardEntry(
            name="Lightning Bolt",
            quantity=3,
            mana_value=1,
            color_identity=["R"],
            types=["Instant"],
            tags=["Removal"],
        ),
        CardEntry(
            name="Island",
            quantity=35,
            mana_value=0,
            color_identity=["U"],
            types=["Land"],
            tags=["Land"],
        ),
        CardEntry(
            name="Mountain",
            quantity=35,
            mana_value=0,
            color_identity=["R"],
            types=["Land"],
            tags=["Land"],
        ),
        CardEntry(
            name="Arcane Signet",
            quantity=4,
            mana_value=2,
            color_identity=["U", "R"],
            types=["Artifact"],
            tags=["Ramp"],
        ),
        CardEntry(
            name="Tempo Tools",
            quantity=22,
            mana_value=3,
            color_identity=["U", "R"],
            types=["Sorcery"],
            tags=["Interaction"],
        ),
    ]

    deck = DeckOut(
        id="deck-sonic",
        name="Sonic Tempo Rush",
        commander_name="Sonic the Hedgehog",
        colors=["U", "R"],
        cards=mock_cards,
        meta=DeckMeta(rc_mode="hybrid", output_mode="deck+analysis", meta_speed="fast"),
        counts=DeckCounts(lands=70, ramp=6, draw=10, interaction=12, protection=3, wincons=4),
        status=DeckStatus(
            has_banned_cards=False,
            has_ci_violations=False,
            is_valid_100=True,
            last_validation_message="Ready for export",
        ),
        validation_line=validation_line,
        created_at=datetime(2024, 11, 1),
        updated_at=datetime(2024, 11, 20),
    )
    return [deck]
