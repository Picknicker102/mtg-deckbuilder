from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from openai import AsyncOpenAI, timeout

from ..core.config import settings


@dataclass
class OpenAiSuggestionResponse:
    suggestions: list[str]
    raw_response: str | None = None


class OpenAIClient:
    def __init__(
        self,
        api_key: str | None = None,
        model: str | None = None,
        base_url: str | None = None,
    ) -> None:
        api_key = api_key or settings.openai_api_key
        self.model = model or settings.openai_model
        self.enabled = bool(api_key)
        self.client = AsyncOpenAI(
            api_key=api_key,
            base_url=base_url or settings.openai_base_url or None,
        ) if self.enabled else None

    @classmethod
    def dependency(cls) -> "OpenAIClient":
        return cls()

    async def generate_deck_suggestions(
        self,
        commander: str,
        colors: list[str],
        rc_mode: str,
        output_mode: str,
        deck_state: dict[str, Any],
    ) -> OpenAiSuggestionResponse:
        prompt = (
            "You are an assistant that proposes Commander deck cards. "
            "Always respect local rules: exactly 100 cards, use banned_snapshot to exclude banned cards, "
            "respect alias_map/oracle_overrides, and return concise names only. "
            f"Commander: {commander}. Colors: {', '.join(colors)}. rc_mode: {rc_mode}. "
            f"output_mode: {output_mode}. "
            f"Deck state: {deck_state}."
        )
        if not self.enabled or self.client is None:
            return OpenAiSuggestionResponse(
                suggestions=self._fallback_suggestions(colors),
                raw_response="OpenAI disabled; returning mock suggestions.",
            )
        try:
            completion = await self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": "Return a short bullet list of card names only."},
                    {"role": "user", "content": prompt},
                ],
                temperature=0.7,
                timeout=20,
            )
            raw = completion.choices[0].message.content or ""
            parsed = self._parse_card_list(raw)
            return OpenAiSuggestionResponse(suggestions=parsed, raw_response=raw)
        except Exception as exc:  # pragma: no cover - OpenAI errors
            return OpenAiSuggestionResponse(
                suggestions=self._fallback_suggestions(colors),
                raw_response=f"OpenAI error: {exc}",
            )

    async def analyze_deck_structure(
        self,
        deck_state: dict[str, Any],
    ) -> str:
        if not self.enabled or self.client is None:
            return "OpenAI disabled; analysis stub."
        try:
            completion = await self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {
                        "role": "system",
                        "content": "Analyze Commander deck structure and mention 100/100 validity.",
                    },
                    {"role": "user", "content": str(deck_state)},
                ],
                temperature=0.4,
                timeout=20,
            )
            return completion.choices[0].message.content or ""
        except Exception:
            return "OpenAI analysis failed."

    async def run_agent(self, prompt_name: str, input_payload: dict[str, Any]) -> str:
        if not self.enabled or self.client is None:
            return f"Prompt {prompt_name} stub with payload {input_payload}"
        try:
            completion = await self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {
                        "role": "system",
                        "content": f"Run agent {prompt_name} with CORE/WRAPPER compliance and 100/100 guard.",
                    },
                    {"role": "user", "content": str(input_payload)},
                ],
                temperature=0.6,
                timeout=20,
            )
            return completion.choices[0].message.content or ""
        except Exception:
            return f"Agent {prompt_name} failed."

    def _parse_card_list(self, raw: str) -> list[str]:
        lines = [line.strip("-• ").strip() for line in raw.splitlines() if line.strip()]
        return [line for line in lines if line]

    def _fallback_suggestions(self, colors: list[str]) -> list[str]:
        return [
            "Sol Ring",
            "Arcane Signet",
            f"Flexible Interaction ({', '.join(colors)})",
        ]
