from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Optional


@dataclass
class MasterSnapshot:
    alias_map: Dict[str, str] = field(default_factory=dict)
    oracle_overrides: Dict[str, Dict[str, Any]] = field(default_factory=dict)
    banned_cards: Dict[str, bool] = field(default_factory=dict)

    @classmethod
    def from_json(cls, data: Dict[str, Any]) -> "MasterSnapshot":
        banned_raw = data.get("banned_snapshot", {}).get("cards", {})
        return cls(
            alias_map={k.lower(): v for k, v in data.get("alias_map", {}).items()},
            oracle_overrides=data.get("oracle_overrides", {}),
            banned_cards={k.lower(): bool(v) for k, v in banned_raw.items()},
        )

    def resolve_alias(self, name: str) -> str:
        lookup = name.lower().strip()
        return self.alias_map.get(lookup, name)

    def is_banned(self, name: str) -> bool:
        return self.banned_cards.get(name.lower().strip(), False)

    def get_override(self, name: str) -> Dict[str, Any]:
        return self.oracle_overrides.get(name, {})


@dataclass
class CoreRules:
    rc_modes: List[str] = field(default_factory=lambda: ["strict", "hybrid", "offline"])
    output_modes: List[str] = field(default_factory=lambda: ["deck only", "deck+analysis", "analysis only"])
    validation_template: str = (
        "Validation: 100/100✔️ RC-Snapshot✔️ RC-Sync AB (Modus: {rc_mode})✔️ "
        "Commander-legal✔️ CI✔️ Moxfield-ready✔️"
    )
    target_slots: Dict[str, int] = field(default_factory=lambda: {
        "lands": 38,
        "ramp": 10,
        "draw": 9,
        "interaction": 12,
        "protection": 3,
        "wincons": 4,
    })


@dataclass
class OracleCard:
    name: str
    color_identity: List[str]
    mana_value: float
    types: List[str]
    is_basic_land: bool = False
    roles: List[str] = field(default_factory=list)

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "OracleCard":
        return cls(
            name=data.get("name", ""),
            color_identity=data.get("color_identity", []),
            mana_value=float(data.get("cmc", data.get("mana_value", 0)) or 0),
            types=data.get("type_line", "").split(" ") if "type_line" in data else data.get("types", []),
            is_basic_land=data.get("is_basic_land", False),
            roles=data.get("roles", []),
        )

    def matches_color_identity(self, commander_ci: List[str]) -> bool:
        # card CI must be subset of commander CI
        return set(self.color_identity).issubset(set(commander_ci))


@dataclass
class DeckBuildRequest:
    commander_name: str
    rc_mode: str = "hybrid"
    language: str = "DE"
    allow_loops: bool = False
    colors: Optional[List[str]] = None
    playstyle: Optional[str] = None


@dataclass
class DeckBuildResult:
    commander: str
    color_identity: List[str]
    decklist: List[str]
    validation: str
    stats: Dict[str, Any]
    notes: List[str] = field(default_factory=list)
