from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from ...services.rule_engine import RuleEngine
from ...models.rules import DeckBuildRequest

router = APIRouter(prefix="/decks", tags=["decks"])

_engine = RuleEngine.from_files()


class DeckBuildIn(BaseModel):
    commanderName: str = Field(..., alias="commanderName")
    rc_mode: str = "hybrid"
    language: str = "DE"
    allowLoops: bool = False
    colors: list[str] | None = None
    playstyle: str | None = None

    model_config = {
        "populate_by_name": True,
    }


class DeckBuildOut(BaseModel):
    commander: str
    color_identity: list[str]
    deck: list[str]
    validation: str
    stats: dict
    notes: list[str] = []


@router.post("/build", response_model=DeckBuildOut)
def build_deck(payload: DeckBuildIn) -> DeckBuildOut:
    try:
        req = DeckBuildRequest(
            commander_name=payload.commanderName,
            rc_mode=payload.rc_mode,
            language=payload.language,
            allow_loops=payload.allowLoops,
            colors=payload.colors,
            playstyle=payload.playstyle,
        )
        result = _engine.build_deck(req)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail={"type": "InvalidCommander", "message": str(exc)}) from exc
    except Exception as exc:
        raise HTTPException(status_code=500, detail={"type": "DeckBuildFailed", "message": str(exc)}) from exc

    return DeckBuildOut(
        commander=result.commander,
        color_identity=result.color_identity,
        deck=result.decklist,
        validation=result.validation,
        stats=result.stats,
        notes=result.notes,
    )
