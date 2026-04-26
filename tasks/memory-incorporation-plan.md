# Plan — Incorporate worthwhile pieces of MemPalace / open-claw into PAI

> **Source:** `~/.pai/MEMORY/RESEARCH/2026-04/2026-04-26_claude-code-memory-systems-vs-pai/REPORT.md`
> **Status:** revised after rubber-duck critique 2026-04-26. Implementation in progress.
> **Anchor tag:** `pre-memory-tier-a-<UTC>` set at start of build.
> **Boundary doc:** `tasks/memory-boundary-decision.md` (decisions 1–6 accepted as recommended; 5 corrected to keep `10_Knowledge/wiki/` workflow).

---

## Problem

PAI has solid markdown-first memory (`ABOUTME`, `TELOS/`, `MEMORY/{LEARNING,WORK,RELATIONSHIP,RESEARCH}`) and a sidecar that builds `startup-digest.md`. As that corpus grows, four gaps will hit:

1. No daily ambient log (light sessions leave no trace).
2. No compressed cross-reference index — LLM has to load whole files to know what exists.
3. No temporal validity on entity facts (when was a fact last verified? superseded by what?).
4. No verbatim conversation recall across past Copilot sessions.

The video's MemPalace + AAAK pattern, the open-claw daily-note layer, and Tier-3-noted dreaming pass close exactly these gaps without breaking the markdown-first stance.

---

## Approach

Three tiers, **must complete A before B**, never adopt C unless a real cross-tool pain emerges.

### Tier A — markdown-only, no new dependencies (revised post-critique)

**A0. Safe-append primitive (NEW — added after rubber-duck critique).**
- `~/.pai/tools/lib/with-pai-lock.sh` — sourceable bash function that wraps a block of writes with `python3 -c 'import fcntl; ...'` advisory lock. macOS-portable (no GNU `flock`).
- All multi-line writers (`append-pointer.sh`, `append-daily.sh`, future `verify-pointers.sh`, monthly rollup) MUST use it.
- Lock file convention: `~/.pai/state/locks/<target-basename>.lock`.

**A2. AAAK pointer index (revised: append-only event log, stable IDs, ASCII-tolerant grammar).**
- New dir: `~/.pai/MEMORY/INDEX/`.
- `pointers.aaak` — append-only **event** log. Each record is an event on a stable pointer ID; promotion / supersession appends a new event with the same ID.
- **Header doc** lives at top of `pointers.aaak` describing the grammar in-band so future tooling and humans can self-orient.
- **Grammar:**
  ```
  § id P-<UTC-stamp>-<slug>
  § W-<wing>/R-<YYYY-MM-DD>/D-<drawer-slug>
  @event created | promoted | superseded | reaffirmed
  @t <ISO-8601 UTC>
  @p <comma-sep or empty>
  @l <comma-sep or empty>
  @e <comma-sep or empty>
  @i <comma-sep or empty>
  § ptr primary <uri>
  § ptr canonical <uri>     (optional; on promote)
  § ptr historical <uri>    (optional; on promote)
  § end
  ```
  - Blank line after `§ end` between records.
  - Parser also accepts `ptr -> ` as alias for `§ ptr primary` (ASCII fallback for tools).
- **Target schemes** (Tier A validates *URI syntax only*, no live resolver):
  - `pai://MEMORY/RESEARCH/...` (PAI-relative; resolver = `~/.pai/` + path)
  - `file:///abs/path` (last resort for OneDrive/PKM paths)
  - `devonthink://<db-uuid>/<record-uuid>` (PAI resolver URI; live verify deferred to on-demand)
  - `mempalace://D-<id>` (forward-looking; verify always `deferred` until Tier B)
- **Wing slugs (initial):** `pai`, `microsoft`, `homestead`, `pkm`, `relationship`, `research`, `health`, `consulting`. Extensible — new wings allowed; tool warns if unknown.
- New tool: `~/.pai/tools/append-pointer.sh` — single writer.
  - Args: `--wing <slug> --drawer <slug> --target <uri> --event <created|promoted|...> [--people --location --event-tag --interest --time]`.
  - Generates stable ID: `P-<UTCstamp>-<wing>-<drawer-slug>` (truncated to 80 chars).
  - Uses `with-pai-lock`. Writes via grouped `printf` (no heredocs).
  - Validates URI scheme prefix; rejects unknown schemes.
  - Returns the pointer ID on stdout.
- Wire `save-research-memory.sh` and `capture-work-learning.sh` to call `append-pointer.sh` **best-effort**: if append fails, log warning to stderr and continue. Do NOT fail the parent capture.
- Wire `harvest-session.sh` similarly for each captured session.
- Sidecar `pai-copilot` startup-digest builder gains a "Pointer index — last 20 events" excerpt (Tier-A-simple; revisit "last 3 per high-value wing" once noise profile is observed).

**A1. DAILY/ machine event ledger (revised: strict one-line, idempotent, session-stamped).**
- New dir: `~/.pai/MEMORY/DAILY/`.
- One file per UTC day: `~/.pai/MEMORY/DAILY/YYYY-MM-DD.md`.
- New tool: `~/.pai/tools/append-daily.sh` — single writer.
  - Args: `--source <name> --event <type> [--session <id>] [--ptr <pointer-id>] [--detail <≤80 chars>]`.
  - Format produced (one line per event, no prose):
    ```
    - HH:MMZ — <event> — source=<name> session=<id> ptr=<P-...> <detail>
    ```
  - Uses `with-pai-lock`.
  - **Idempotency:** if same `(source, event, session, minute-bucket)` already present in today's file, skip silently.
- Sidecar `pai-copilot` invokes `append-daily.sh --source sidecar --event session-start --session $PAI_SESSION_ID` on each session start.
- `harvest-session.sh` invokes `append-daily.sh --source harvest --event session-close --session <id> --detail "harvested=<N>"` per harvested session.
- Capture scripts invoke `append-daily.sh` after their primary write (best-effort; never fails parent).
- **Monthly rollup:** non-destructive. Daily files stay. Sidecar generates `DAILY/YYYY/MM.md` (overwriteable derived index) on first session of new month, gated by sentinel `~/.pai/state/daily-rollup-<YYYY-MM>.done`. Rollup itself is locked.

**A3. TELOS temporal validity tags (revised: NO mass backfill, NO AISTEERINGRULES rule).**
- Convention: `_Verified: YYYY-MM-DD_` and `_Superseded by: P-<pointer-id>_` markers may appear on TELOS bullets. Missing marker = unknown freshness.
- **No mass backfill.** Add a one-time file-level note at top of `~/.pai/USER/TELOS/PROJECTS.md`, `GOALS.md`, and `~/.pai/USER/ABOUTME.md`:
  > Facts without `_Verified:` predate temporal tagging — treat as unknown freshness.
- New tool: `~/.pai/tools/touch-telos-fact.sh`:
  - Required args: `--file <path> --heading <h2-or-h3-text> --field <field-label>`.
  - Locates exactly one bullet matching that heading + field. **Refuses if 0 or >1 matches**, prints diff to stderr.
  - Default mode: **dry-run** (prints proposed change). `--yes` to apply.
  - Uses `with-pai-lock` on the target file.
  - Bumps `_Verified:_` to today's UTC date, or appends if missing.
- **No AISTEERINGRULES rule added.** The convention is documented in `~/.pai/USER/TELOS/README.md` (created if missing) and at the top of each TELOS file. Promotion to AISTEERINGRULES deferred until observed friction (per the file's own "rules are earned" principle).
- `_Superseded by:_` uses pointer IDs (`P-<UTC>-<slug>`), not raw paths — stable across pointer file edits.

### Tier B — adds Chroma+SQLite, only after Tier A is in daily use

B1. **MemPalace install scoped to Copilot session events.**
- Install via `pipx install mempalace` (or `pip install -e` in a dedicated venv at `~/.pai/vendor/mempalace/`).
- **Do not** point it at `~/.pai/MEMORY/` — markdown stays canonical.
- Run `mempalace mine ~/.copilot/session-state/<id>/events.jsonl` driven by `harvest-session.sh` per-session, after the existing harvest step. `.harvested` sentinel becomes `.harvested.v2` to force one-time re-mining.
- Palace lives at `~/.pai/vendor/mempalace/.mempalace/`. Backup-excluded.
- New skill: `Copilot/skills/MemoryRecall/SKILL.md` — gated workflow that calls `mempalace search "<query>"` when the user says "search my conversations for X" / "what did we say about Y". Falls back to grep over `events.jsonl` if mempalace is not installed.

B2. **Dreaming / weekly synthesis (already half-stubbed: `~/.pai/state/last-synthesis.stamp`).**
- New script: `~/.pai/tools/dream.sh` — gated by ISO-week stamp.
  - Score recurring `@e`/`@i` tags in pointers.aaak from the last 14 days.
  - Score recurring patterns in DAILY/ (entity mentions, repeated topics).
  - Score recurring entries in `LEARNING/REFLECTIONS/algorithm-reflections.jsonl`.
  - Promote top-N durable patterns into `LEARNING/SYNTHESIS/<UTC>_synthesis.md` with backlinks.
  - Suggest (but do not auto-write) candidates for AISTEERINGRULES — emit `~/.pai/state/queue/steering-candidates-<UTC>.md` for Robley to triage.
- Sidecar invokes `dream.sh` on first session of each ISO week.

### Tier C — defer / skip

- mem-search plugin (needs UserPromptSubmit hook Copilot doesn't expose).
- Karpathy LLM wiki / LightRAG / Recall (DEVONthink+PKM already covers).
- Open Brain / Mem0 (cloud, conflicts with ownership).
- Claude Mem (strictly worse than MemPalace).

Only revisit if a real cross-tool pain point or a vector-search ceiling shows up in lived use.

---

## Risks and decisions to flag before build

- **DAILY/ growth:** unchecked, this becomes hundreds of files. Mitigation: auto-archive into `DAILY/YYYY/QN.md` quarterly. Decision: confirm quarterly granularity at archive time, or roll monthly?
- **Pointer index drift:** if `pointers.aaak` is hand-edited it will desync from filesystem. Mitigation: single-writer rule via `append-pointer.sh`; a periodic `verify-pointers.sh` lint that flags missing files. Decision needed: should `verify-pointers.sh` run on shutdown or weekly with dream.sh?
- **TELOS backfill scope:** stamping every bullet at once with today's date is technically a lie (we didn't actually verify them today). Alternative: stamp `_Verified: <file-mtime>_` from git log. Decision needed.
- **MemPalace dependency surface:** ChromaDB pulls in onnxruntime + sentence-transformers (~500MB). Acceptable on Robley's M5 Max, but means PAI now has a non-trivial Python stack. Confirm before Tier B.
- **Hook absence:** MemPalace's design assumes Claude Code's `stop`/`precompact` hooks. Driving from `harvest-session.sh` runs after-the-fact (next session start, not real-time at session end). Acceptable for verbatim recall; may produce a 1-session lag. Document in PORTING_NOTES.

---

## Out of scope (explicit non-goals)

- Migrating any existing markdown into MemPalace's drawer storage. Markdown stays canonical.
- Building a UI for the pointer index. CLI grep + startup-digest excerpt is the interface.
- Changing the mode contract (MINIMAL/NATIVE/ALGORITHM) or sidecar startup-digest format beyond appending the pointer-index excerpt.
- Cross-tool sync to DEVONthink, ChatGPT, Cursor — Tier C only.

---

## Tracking

Todos are reflected into the session SQL `todos` table. New ordering after critique: A0 (lock primitive) → A2 (pointers, depends on A0) → A1 (DAILY, depends on A0+A2) → A3 (TELOS lite, depends on A0). Tier B deferred (decision 4). Tier C not tracked.

Status flow: `pending` → `in_progress` → `done` / `blocked`.

---

## Build Log

Per-todo record kept here as work proceeds. Each entry: what was built, files touched, commit SHA, anything noteworthy.

(populated as work proceeds)

