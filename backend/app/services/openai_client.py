from __future__ import annotations

import json
from pathlib import Path
from typing import Iterable

from openai import AsyncOpenAI

from ..core.config import BASE_DIR, settings

# Prompt sources (CORE/WRAPPER/init files) that should inform every agent call.
PROMPT_FILES: Iterable[Path] = (
    Path(BASE_DIR).parent / "MTG_Commander_Core_v8_7_minJSON.txt",
    Path(BASE_DIR).parent / "mtg_commander_wrapper_v8_7_minJSON.txt",
    BASE_DIR / "prompts" / "INIT Messagee.txt",
    BASE_DIR / "prompts" / "Mtg Builder User Guide.txt",
    BASE_DIR / "prompts" / "MTG Hinweise wrapper.txt",
    BASE_DIR / "prompts" / "MtgBuilder_Core.txt",
)

# Shared async OpenAI client. API key must be provided via backend/.env (OPENAI_API_KEY).
_base_url = (settings.openai_base_url or "").strip() or "https://api.openai.com/v1"
OPENAI_CLIENT = AsyncOpenAI(
    api_key=settings.openai_api_key or None,
    base_url=_base_url,
)


def _load_file(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return ""


def _load_snapshot_context() -> str:
    snapshot_path = BASE_DIR / "data" / "mtg_master.json"
    if not snapshot_path.exists():
        return ""
    try:
        data = json.loads(snapshot_path.read_text(encoding="utf-8"))
    except Exception:
        return ""

    alias_count = len(data.get("alias_map", {}))
    override_count = len(data.get("oracle_overrides", {}))
    banned = data.get("banned_snapshot", {}).get("cards", {})
    banned_names = [name for name, banned_flag in banned.items() if banned_flag]
    banned_preview = ", ".join(banned_names[:20])
    return (
        f"Local snapshot counts -> alias_map: {alias_count}, oracle_overrides: {override_count}, "
        f"banned true: {len(banned_names)} (preview: {banned_preview}). "
        "Always treat banned_snapshot as authoritative."
    )


def _build_instruction_block(agent: str) -> str:
    prompt_texts = [_load_file(p) for p in PROMPT_FILES]
    snapshot = _load_snapshot_context()
    return (
        f"Agent: {agent}\n"
        "Follow CORE + WRAPPER instructions, enforce exactly 100 Commander cards with one validation line. "
        "Use alias_map and oracle_overrides from the local snapshot, and never output banned_snapshot cards. "
        f"{snapshot}\n\n"
        "Attached prompt files:\n" + "\n---\n".join(prompt_texts)
    )


async def run_agent(agent: str, user_input: str) -> str:
    """
    Execute an agent prompt via OpenAI Chat Completions.
    Always returns the model output (no mock fallbacks).
    """
    if not settings.openai_api_key:
        raise RuntimeError("OpenAI API key missing; cannot run agent.")

    instructions = _build_instruction_block(agent)
    try:
        completion = await OPENAI_CLIENT.chat.completions.create(
            model=settings.openai_model,
            messages=[
                {"role": "system", "content": instructions},
                {"role": "user", "content": user_input},
            ],
            temperature=0.4,
        )
    except Exception as exc:
        raise RuntimeError(f"OpenAI request failed: {exc}") from exc
    content = completion.choices[0].message.content
    if not content:
        raise RuntimeError("OpenAI returned empty content.")
    return content
