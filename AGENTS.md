# MTG Commander – Agents & Project Guide

Dieses Dokument erklärt für Code-Assistenten (z. B. GitHub Copilot / OpenAI Codex / GPT) die Struktur und Regeln dieses Projekts.

## 1. Projektüberblick

- **Ziel:**  
  Ein MTG Commander Deckbuilder-System mit:
  - Flutter-Frontend (UI für Deckbau, Analyse, Kartenpool, Einstellungen)
  - Python-Backend (FastAPI) mit PostgreSQL
  - Lokaler MTG-Datenbasis:
    - `MTG_Commander_Core_v8_7_minJSON.txt` (CORE)
    - `mtg_commander_wrapper_v8_7_minJSON.txt` (WRAPPER)
    - `backend/data/mtg_master.json` (oracle_overrides, alias_map, banned_snapshot)

- **Wichtige Magic-Regeln im Projekt:**
  - Commander-Decks haben **immer exakt 100 Karten** inkl. Commander.
  - Export-Listen enden mit genau **einer** Validierungszeile:

    ```text
    Validation: 100/100✔️ RC-Snapshot✔️ RC-Sync AB (Modus: <strict|hybrid|offline>)✔️ Commander-legal✔️ CI✔️ Moxfield-ready✔️
    ```

  - `mtg_master.json` ist der lokale Snapshot für:
    - Spezialkarten (UB/Secret Lair/Custom) via `oracle_overrides`.
    - Alias-Namen via `alias_map`.
    - Projekt-interne Bannliste via `banned_snapshot`.

## 2. Repository-Struktur (Zielbild)

- Flutter-Projekt (aktueller Stand in diesem Repo, z. B. Wurzel mit `lib/`, `android/`, `ios/` usw.):
  - `lib/main.dart`
  - `lib/router/app_router.dart` (geplant)
  - `lib/features/`
    - `dashboard/`
    - `deck_builder/`
    - `deck_analysis/`
    - `card_pool/`
    - `settings/`
    - `core/` (shared widgets, theme, services, models)

- `backend/`
  - **WICHTIG:** Hier existiert bereits ein Python-Virtualenv, z. B. `backend/.venv/`.
  - `app/main.py` (FastAPI Entry)
  - `app/core/config.py`
  - `app/db/session.py`
  - `app/api/routes/` (REST-Endpoints)
  - `app/services/openai_client.py`
  - `data/mtg_master.json`
  - `requirements.txt` oder `pyproject.toml`
  - `.env` (nicht committen)
  - `.env.example` (committen, enthält Platzhalter)
  - `.venv/` (bestehendes Virtualenv, **nicht** neu anlegen, **nicht** committen)

- Projekt-Dokumente im Repo-Root:
  - `MTG_Commander_Core_v8_7_minJSON.txt`
  - `mtg_commander_wrapper_v8_7_minJSON.txt`
  - `mtg_master` / `mtg_master.json` (je nach aktueller Benennung)
  - `INIT Messagee`
  - `Mtg Builder User Guide`
  - `MtgBuilder_Core`
  - `MTG Hinweise wrapper`
  - `agents.md`
  - weitere Prompt-Dateien wie `/mtg_commander_flutter_ui`

## 3. Wichtige Dateien & ihre Rollen

- **CORE – `MTG_Commander_Core_v8_7_minJSON.txt`**
  - Definiert:
    - Commander-Format-Regeln (100/100 Hardguard)
    - rc_mode (strict / hybrid / offline)
    - output_mode (deck only / deck+analysis / analysis only)
    - Color-Identity-Regeln
    - Moxfield-kompatibles Output-Format

- **WRAPPER – `mtg_commander_wrapper_v8_7_minJSON.txt`**
  - Legt praktische Regeln fest:
    - Priorität: JSON-Snapshot > internes Wissen
    - Umgang mit alias_map und oracle_overrides
    - Snapshot-first Bannlogik
    - Verhalten bei fehlenden/fehlerhaften Daten

- **JSON – `backend/data/mtg_master.json`**
  - `oracle_overrides[Name]`: Spezialkarten (UB, Secret Lair, Custom, etc.)
  - `alias_map[Alias]`: Schreibvarianten oder Kurzformen → Oracle-Name
  - `banned_snapshot.cards[Name]`: true/false = lokale Bannrealität

## 4. Agents / Prompts

### 4.1 `/mtg_commander_flutter_ui`

- Zweck:
  - Flutter-UI für das gesamte System aufsetzen.
  - Python-Backend-Skeleton mit FastAPI + PostgreSQL + OpenAI-Integration erzeugen.
- Erwartungen:
  - Feature-basierte Flutter-Struktur.
  - Riverpod + go_router.
  - Backend mit:
    - zentralem OpenAI-Client
    - PostgreSQL-Anbindung
    - Basis-Endpoints für Decks, Analyse, AI-Suggestions.

### 4.2 Weitere (geplante) Agents

Beispiele (können später ergänzt/implementiert werden):

- `/mtg_commander_deckbuilder_core`  
  Fokus: reine Deckbau-Logik, Nutzung von CORE/WRAPPER/JSON im Backend.

- `/mtg_commander_analysis_engine`  
  Fokus: Wahrscheinlichkeitsrechnung, Curve-Analyse, Ramp/Draw/Interaction-Checks.

- `/mtg_commander_rules_helper`  
  Fokus: MTG-Regel-Erklärungen während des Spiels (separates Projekt möglich).

## 5. OpenAI API Integration

- **Bibliothek:** Offizielles OpenAI Python SDK.
- **Konfiguration:**
  - Über `.env` im `backend/`:
    - `OPENAI_API_KEY=...`
    - `OPENAI_MODEL=gpt-4o` (oder ähnlich)
    - `OPENAI_BASE_URL` (optional)
    - `DATABASE_URL=postgresql+psycopg2://user:password@localhost:5432/mtg_commander`
    - `BACKEND_ENV=dev|prod`
  - `.env.example` enthält die gleichen Keys, aber ohne echte Werte.

- **Design:**
  - Alle API-Aufrufe laufen über `app/services/openai_client.py`.
  - Keine direkten OpenAI-Aufrufe in Routes oder Models.
  - Der Client stellt Methoden bereit wie:
    - `generate_deck_suggestions(...)`
    - `analyze_deck_structure(...)`
    - `run_agent(prompt_name, input_payload)`  
  - Prompts sollen CORE/WRAPPER-Regeln respektieren:
    - 100/100 Decklisten
    - lokale Banlist aus `banned_snapshot`
    - alias_map/oracle_overrides bei Karten-Namen berücksichtigen.

- **Sicherheit:**
  - API-Key nie loggen.
  - API-Key nie in Frontend oder statischen Dateien ausgeben.
  - `.env` und `.venv` sind IMMER in `.gitignore`.

## 6. PostgreSQL & Datenmodell

- **DB:** PostgreSQL.
- **Zugang:** `DATABASE_URL` in `.env`, z.B.  
  `postgresql+psycopg2://user:password@localhost:5432/mtg_commander`
- **Empfohlenes Schema (vereinfachtes Zielbild):**
  - `decks` (id, name, commander_name, colors, meta_json, created_at, updated_at)
  - `deck_cards` (id, deck_id, card_name, quantity, mana_value, meta_json)
  - `card_pool` (id, card_name, total_owned, location_code, meta_json)
- SQLAlchemy-Models können später um Details erweitert werden (Tags, CI, Flags etc.).

## 7. Regeln für Code-Assistenten

- **Virtualenv im Backend beachten:**
  - Es existiert bereits ein Virtualenv im Ordner `backend/` (typischer Name: `.venv`).
  - Wenn Python-Befehle ausgeführt werden sollen (z. B. `pip install`, `uvicorn`, `alembic`), dann:
    1. ins Backend-Verzeichnis wechseln:
       - `cd backend`
    2. Virtualenv aktivieren:
       - **Windows PowerShell:** `.\.venv\Scripts\activate`
       - **CMD:** `.venv\Scripts\activate.bat`
       - **(Nur falls auf anderen Systemen geklont)**  
         Linux/macOS: `source .venv/bin/activate`
    3. Befehle ausführen (z. B. `pip install -r requirements.txt`, `uvicorn app.main:app --reload`).
  - Kein zweites Virtualenv in `backend/` anlegen, solange `.venv` existiert.
  - `.venv` niemals verändern oder committen, außer auf ausdrücklichen Wunsch.

- **Respektiere CORE & WRAPPER:**
  - Keine Decks mit ≠100 Karten erzeugen.
  - Lokale Bannliste aus `banned_snapshot` ist maßgeblich.
  - Farbidentität (color_identity) der Commander beachten.

- **Trennung Frontend / Backend:**
  - Flutter enthält keine geheimen Keys.
  - Backend kapselt Datenzugriff und OpenAI-Aufrufe.

- **Konfiguration / Secrets:**
  - Verwende `.env` + `config.py` für Settings.
  - Lege IMMER eine `.env.example` an, wenn du neue Variablen brauchst.

- **Code-Qualität:**
  - Typannotationen in Python.
  - Null-safes Dart.
  - Klar benannte Services/Repositories.
  - Kurze, fokussierte Dateien und Funktionen.

## 8. Onboarding für neue Agents

Wenn ein neuer Agent (Prompt) mit diesem Projekt arbeitet, sollte er:

1. Diese `agents.md` lesen.
2. CORE, WRAPPER und `mtg_master.json` zumindest grob scannen.
3. Prüfen, ob die aktuelle Struktur von Flutter-Frontend und `backend/` zum Zielbild passt.
4. Beim Arbeiten mit Python IMMER das bestehende Virtualenv `backend/.venv` aktivieren, bevor Befehle ausgeführt werden.
5. Nur Änderungen vornehmen, die die bestehenden Regeln respektieren.
6. Niemals API-Keys oder andere Secrets ins Repo schreiben.
