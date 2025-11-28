from __future__ import annotations

import json
import random
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

from ..core.config import BASE_DIR
from ..models.rules import (
    CoreRules,
    DeckBuildRequest,
    DeckBuildResult,
    MasterSnapshot,
    OracleCard,
)


class RuleEngine:
    def __init__(
        self,
        core_rules: CoreRules,
        snapshot: MasterSnapshot,
        oracle_cards: List[OracleCard],
    ) -> None:
        self.core_rules = core_rules
        self.snapshot = snapshot
        self.oracle_cards = oracle_cards
        self._card_lookup = {card.name.lower(): card for card in oracle_cards}

    @classmethod
    def from_files(
        cls,
        mtg_master_path: Optional[Path] = None,
        oracle_path: Optional[Path] = None,
    ) -> "RuleEngine":
        master_path = mtg_master_path or (BASE_DIR / "data" / "mtg_master.json")
        snapshot = MasterSnapshot.from_json(json.loads(master_path.read_text(encoding="utf-8")))

        # Attempt to load oracle pool; fallback to minimal set if not found.
        oracle_cards: List[OracleCard] = []
        if oracle_path and oracle_path.exists():
            data = json.loads(oracle_path.read_text(encoding="utf-8"))
            raw_cards = data if isinstance(data, list) else data.get("data", [])
            oracle_cards = [OracleCard.from_dict(_simplify_card(d)) for d in raw_cards]
        else:
            oracle_cards = _fallback_oracle_cards()

        core_rules = CoreRules()
        return cls(core_rules=core_rules, snapshot=snapshot, oracle_cards=oracle_cards)

    def build_deck(self, req: DeckBuildRequest) -> DeckBuildResult:
        commander_name, commander_card = self._resolve_commander(req.commander_name)
        commander_ci = commander_card.color_identity or req.colors or []

        if self.snapshot.is_banned(commander_name):
            raise ValueError(f"Commander '{commander_name}' ist gebannt laut Snapshot.")

        pool = self._filter_pool(commander_ci)
        roles = self.core_rules.target_slots
        deck_cards: List[str] = []
        notes: List[str] = []

        # Commander first
        deck_cards.append(commander_name)

        # Lands
        deck_cards.extend(self._pick_by_role(pool, commander_ci, roles["lands"], role="land"))

        # Ramp / draw / interaction / protection / wincons
        deck_cards.extend(self._pick_by_role(pool, commander_ci, roles["ramp"], role="ramp"))
        deck_cards.extend(self._pick_by_role(pool, commander_ci, roles["draw"], role="draw"))
        deck_cards.extend(self._pick_by_role(pool, commander_ci, roles["interaction"], role="interaction"))
        deck_cards.extend(self._pick_by_role(pool, commander_ci, roles["protection"], role="protection"))
        deck_cards.extend(self._pick_by_role(pool, commander_ci, roles["wincons"], role="wincon"))

        # Fill to 100 with color-appropriate basics
        total_needed = 100 - len(deck_cards)
        if total_needed > 0:
            deck_cards.extend(self._basic_lands(commander_ci, total_needed))

        validation = self.core_rules.validation_template.format(rc_mode=req.rc_mode)
        stats = self._stats(deck_cards)
        if len(deck_cards) != 100:
            notes.append(f"Deckgröße {len(deck_cards)} statt 100 – fehlende Karten wurden nicht gefunden.")
        return DeckBuildResult(
            commander=commander_name,
            color_identity=commander_ci,
            decklist=deck_cards[:100],
            validation=validation,
            stats=stats,
            notes=notes,
        )

    def _resolve_commander(self, name: str) -> Tuple[str, OracleCard]:
        resolved = self.snapshot.resolve_alias(name)
        # try overrides
        override = self.snapshot.get_override(resolved)
        color_identity = override.get("color_identity", [])
        if override:
            card = OracleCard(
                name=resolved,
                color_identity=color_identity,
                mana_value=float(override.get("mana_value", 0)),
                types=override.get("types", ["Legendary", "Creature"]),
                is_basic_land=False,
                roles=["commander"],
            )
            return resolved, card

        key = resolved.lower()
        card = self._card_lookup.get(key)
        if not card:
            # fallback generic commander
            card = OracleCard(
                name=resolved,
                color_identity=color_identity or [],
                mana_value=4,
                types=["Legendary", "Creature"],
                roles=["commander"],
            )
        return resolved, card

    def _filter_pool(self, commander_ci: List[str]) -> List[OracleCard]:
        return [
            card
            for card in self.oracle_cards
            if card.matches_color_identity(commander_ci) and not self.snapshot.is_banned(card.name)
        ]

    def _pick_by_role(
        self,
        pool: List[OracleCard],
        commander_ci: List[str],
        count: int,
        role: str,
    ) -> List[str]:
        candidates = [c for c in pool if role in (c.roles or []) and c.matches_color_identity(commander_ci)]
        if len(candidates) < count:
            # pad with any CI-legal cards
            candidates.extend([c for c in pool if c.matches_color_identity(commander_ci)])
        random.shuffle(candidates)
        return [c.name for c in candidates[:count]]

    def _basic_lands(self, commander_ci: List[str], count: int) -> List[str]:
        basics_by_color = {
            "W": "Plains",
            "U": "Island",
            "B": "Swamp",
            "R": "Mountain",
            "G": "Forest",
        }
        basics = [basics_by_color.get(c, "Wastes") for c in commander_ci] or ["Wastes"]
        out: List[str] = []
        for i in range(count):
            out.append(basics[i % len(basics)])
        return out

    def _stats(self, decklist: List[str]) -> Dict[str, Any]:
        counts: Dict[str, int] = {"lands": 0, "ramp": 0, "draw": 0, "interaction": 0, "protection": 0, "wincons": 0}
        for name in decklist:
            card = self._card_lookup.get(name.lower())
            if not card:
                continue
            lower_types = [t.lower() for t in card.types]
            if "land" in lower_types or card.is_basic_land:
                counts["lands"] += 1
            if "ramp" in card.roles:
                counts["ramp"] += 1
            if "draw" in card.roles:
                counts["draw"] += 1
            if "interaction" in card.roles:
                counts["interaction"] += 1
            if "protection" in card.roles:
                counts["protection"] += 1
            if "wincon" in card.roles:
                counts["wincons"] += 1
        counts["total"] = len(decklist)
        return counts


def _simplify_card(data: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "name": data.get("name"),
        "color_identity": data.get("color_identity", []),
        "cmc": data.get("cmc") or data.get("mana_value") or 0,
        "type_line": data.get("type_line", ""),
        "is_basic_land": "Basic" in data.get("type_line", ""),
        "roles": data.get("roles", []),
    }


def _fallback_oracle_cards() -> List[OracleCard]:
    # Minimal offline pool to keep token cost low and allow quick testing.
    raw_cards = [
        {"name": "Sol Ring", "color_identity": [], "cmc": 1, "type_line": "Artifact", "roles": ["ramp"]},
        {"name": "Arcane Signet", "color_identity": [], "cmc": 2, "type_line": "Artifact", "roles": ["ramp"]},
        {"name": "Cultivate", "color_identity": ["G"], "cmc": 3, "type_line": "Sorcery", "roles": ["ramp"]},
        {"name": "Farseek", "color_identity": ["G"], "cmc": 2, "type_line": "Sorcery", "roles": ["ramp"]},
        {"name": "Rhystic Study", "color_identity": ["U"], "cmc": 3, "type_line": "Enchantment", "roles": ["draw"]},
        {"name": "Fact or Fiction", "color_identity": ["U"], "cmc": 4, "type_line": "Instant", "roles": ["draw"]},
        {"name": "Beast Within", "color_identity": ["G"], "cmc": 3, "type_line": "Instant", "roles": ["interaction"]},
        {"name": "Swords to Plowshares", "color_identity": ["W"], "cmc": 1, "type_line": "Instant", "roles": ["interaction"]},
        {"name": "Cyclonic Rift", "color_identity": ["U"], "cmc": 2, "type_line": "Instant", "roles": ["interaction"]},
        {"name": "Heroic Intervention", "color_identity": ["G"], "cmc": 2, "type_line": "Instant", "roles": ["protection"]},
        {"name": "Teferi's Protection", "color_identity": ["W"], "cmc": 3, "type_line": "Instant", "roles": ["protection"]},
        {"name": "Craterhoof Behemoth", "color_identity": ["G"], "cmc": 8, "type_line": "Creature", "roles": ["wincon"]},
        {"name": "Exsanguinate", "color_identity": ["B"], "cmc": 2, "type_line": "Sorcery", "roles": ["wincon"]},
        {"name": "Blue Sun's Zenith", "color_identity": ["U"], "cmc": 3, "type_line": "Instant", "roles": ["wincon"]},
        {"name": "Lightning Bolt", "color_identity": ["R"], "cmc": 1, "type_line": "Instant", "roles": ["interaction"]},
        {"name": "Island", "color_identity": ["U"], "cmc": 0, "type_line": "Basic Land — Island", "roles": ["land"], "is_basic_land": True},
        {"name": "Forest", "color_identity": ["G"], "cmc": 0, "type_line": "Basic Land — Forest", "roles": ["land"], "is_basic_land": True},
        {"name": "Plains", "color_identity": ["W"], "cmc": 0, "type_line": "Basic Land — Plains", "roles": ["land"], "is_basic_land": True},
        {"name": "Swamp", "color_identity": ["B"], "cmc": 0, "type_line": "Basic Land — Swamp", "roles": ["land"], "is_basic_land": True},
        {"name": "Mountain", "color_identity": ["R"], "cmc": 0, "type_line": "Basic Land — Mountain", "roles": ["land"], "is_basic_land": True},
        {"name": "Avenger of Zendikar", "color_identity": ["G"], "cmc": 7, "type_line": "Creature", "roles": ["wincon"]},
    ]
    return [OracleCard.from_dict(rc) for rc in raw_cards]
