# MTG DECK BUILD PROTO Backend Skeleton

This repository uses a layered backend layout to implement the Commander deck builder described in the project specs (CORE, WRAPPER, JSON data, and User Guide). The structure is bootstrapped by `scripts/create_structure.sh`, which creates the directories and placeholder modules below:

```
backend/
  index.js              # Backend entrypoint (wire engine modules here later)
  data/                 # Local data sources: collection.json, mtg_master.json, oracle-cards.json
  engine/               # Core engine modules (scryfallIndex, projectOverlay, tagging, poolBuilder, llmDeckBuilder, validator)
  spec/                 # Spec copies for quick reference: CORE, WRAPPER, User Guide
```

## Usage
Run the helper script from the repository root to recreate the scaffolding and copy available spec/data files without overwriting existing ones:

```bash
./scripts/create_structure.sh
```

The script preserves any already-present module implementations and only fills in missing stubs. Specs and data are copied from the repository root into `backend/spec` and `backend/data` when present.
