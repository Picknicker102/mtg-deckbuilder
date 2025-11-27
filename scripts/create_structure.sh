#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "$ROOT_DIR/backend/engine" "$ROOT_DIR/backend/data" "$ROOT_DIR/backend/spec"

# Engine module stubs
for module in scryfallIndex.js projectOverlay.js tagging.js poolBuilder.js llmDeckBuilder.js validator.js; do
  if [ ! -f "$ROOT_DIR/backend/engine/$module" ]; then
    cat <<'STUB' > "$ROOT_DIR/backend/engine/$module"
// Placeholder for MTG DECK BUILD PROTO engine module.
// Implement according to CORE and WRAPPER specifications.
STUB
  fi
done

# Backend entrypoint stub
if [ ! -f "$ROOT_DIR/backend/index.js" ]; then
  cat <<'INDEX' > "$ROOT_DIR/backend/index.js"
// Entry point for MTG DECK BUILD PROTO backend.
// Wire up engine modules here when implementing runtime behavior.
INDEX
fi

# Preserve data/spec directories in version control
: > "$ROOT_DIR/backend/data/.gitkeep"
: > "$ROOT_DIR/backend/spec/.gitkeep"

# Optionally stage rule/spec files into backend/spec without overwriting existing copies
for spec_file in "MtgBuilder_Core.txt" "MTG Hinweise wrapper.txt" "Mtg Builder User Guide.txt"; do
  if [ -f "$ROOT_DIR/$spec_file" ] && [ ! -f "$ROOT_DIR/backend/spec/$spec_file" ]; then
    cp "$ROOT_DIR/$spec_file" "$ROOT_DIR/backend/spec/"
  fi
done

# Optionally stage data sources into backend/data without overwriting existing copies
for data_file in "mtg_master.json" "collection.json" "oracle-cards.json"; do
  if [ -f "$ROOT_DIR/$data_file" ] && [ ! -f "$ROOT_DIR/backend/data/$data_file" ]; then
    cp "$ROOT_DIR/$data_file" "$ROOT_DIR/backend/data/"
  fi
done

printf "Backend folder and file skeleton created under %s\n" "$ROOT_DIR/backend"
