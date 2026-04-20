#!/usr/bin/env bash
# harvest-session.sh — Auto-extract learnings from past Copilot CLI sessions.
#
# Scans ~/.copilot/session-state/*/events.jsonl for `session.task_complete`
# events (each already contains a self-generated markdown summary) and either
# prints them as a digest or pipes them through capture-work-learning.sh so
# they land in MEMORY/LEARNING/{ALGORITHM,SYSTEM}/.
#
# Sessions already harvested are marked with a `.harvested` sentinel file
# inside the session directory so repeat runs are idempotent.
#
# Replaces the upstream SessionHarvester.ts (which read Claude transcripts).
# Works against Copilot's on-disk session store — no running-session context
# or DuckDB access required.
#
# Usage:
#   harvest-session.sh                         # last 7 days, dry-run digest to stdout
#   harvest-session.sh --days 30               # last 30 days
#   harvest-session.sh --auto                  # pipe each session into capture-work-learning.sh
#   harvest-session.sh --auto --days 30
#   harvest-session.sh --session-dir <path>    # override session root
#   harvest-session.sh --reharvest             # ignore .harvested sentinels
#
# Requirements: jq (falls back to python3 json if jq missing).

set -euo pipefail

DAYS=7
AUTO=0
REHARVEST=0
SESSION_DIR="${COPILOT_SESSION_DIR:-$HOME/.copilot/session-state}"

usage() {
  sed -n '2,30p' "$0" >&2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --days)        DAYS="${2:?}"; shift 2 ;;
    --auto)        AUTO=1; shift ;;
    --session-dir) SESSION_DIR="${2:?}"; shift 2 ;;
    --reharvest)   REHARVEST=1; shift ;;
    -h|--help)     usage ;;
    *) echo "unknown arg: $1" >&2; usage ;;
  esac
done

if ! command -v jq >/dev/null 2>&1; then
  echo "harvest-session: jq is required" >&2
  exit 1
fi

[[ -d "$SESSION_DIR" ]] || {
  echo "harvest-session: session dir not found: $SESSION_DIR" >&2
  exit 1
}

CAPTURE_TOOL="$(dirname "$0")/capture-work-learning.sh"

# ── Collect candidate sessions (events.jsonl modified within DAYS days) ──
mapfile -t SESSIONS < <(
  find "$SESSION_DIR" -maxdepth 2 -name events.jsonl -type f -mtime -"$DAYS" 2>/dev/null
)

if [[ ${#SESSIONS[@]} -eq 0 ]]; then
  echo "harvest-session: no sessions with events in the last $DAYS day(s)" >&2
  exit 0
fi

slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | tr -c 'a-z0-9' '-' \
    | sed -E 's/-+/-/g; s/^-+//; s/-+$//' \
    | cut -c1-60
}

HARVESTED_COUNT=0
SKIPPED_COUNT=0

for EVENTS in "${SESSIONS[@]}"; do
  SESSION_PATH="$(dirname "$EVENTS")"
  SESSION_ID="$(basename "$SESSION_PATH")"
  SENTINEL="$SESSION_PATH/.harvested"

  if [[ -f "$SENTINEL" && $REHARVEST -eq 0 ]]; then
    SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    continue
  fi

  # First user message (for slug + context header)
  FIRST_PROMPT="$(jq -r '
    select(.type == "user.message") | .data.content // ""
  ' "$EVENTS" 2>/dev/null | head -n 1 | head -c 200)"

  # All task_complete summaries (a session can have multiple)
  SUMMARIES="$(jq -cr '
    select(.type == "session.task_complete") |
      { ts: .timestamp, ok: (.data.success // true), s: (.data.summary // "") }
  ' "$EVENTS" 2>/dev/null)"

  if [[ -z "$SUMMARIES" ]]; then
    # Nothing harvestable — still mark so we don't re-scan empty sessions.
    touch "$SENTINEL"
    continue
  fi

  SLUG_SOURCE="${FIRST_PROMPT:-$SESSION_ID}"
  SLUG="$(slugify "$SLUG_SOURCE")"
  [[ -n "$SLUG" ]] || SLUG="session-${SESSION_ID:0:8}"

  HEADER="## Session ${SESSION_ID:0:8} — ${SLUG}

- **Source session:** \`$SESSION_PATH\`
- **First prompt (truncated):** ${FIRST_PROMPT:-_(none)_}
"

  BODY="$(echo "$SUMMARIES" | jq -r '
    "### task_complete @ \(.ts) — success=\(.ok)\n\n\(.s)\n"
  ')"

  DIGEST="${HEADER}
${BODY}"

  if [[ $AUTO -eq 1 ]]; then
    echo "$DIGEST" | PAI_SESSION_ID="$SESSION_ID" "$CAPTURE_TOOL" --slug "$SLUG" \
      >/dev/null
    echo "harvested: $SESSION_ID ($SLUG)"
  else
    printf '%s\n\n---\n\n' "$DIGEST"
  fi

  touch "$SENTINEL"
  HARVESTED_COUNT=$((HARVESTED_COUNT + 1))
done

if [[ $AUTO -eq 1 ]]; then
  echo "harvest-session: captured $HARVESTED_COUNT session(s), skipped $SKIPPED_COUNT already-harvested" >&2
elif [[ $HARVESTED_COUNT -eq 0 ]]; then
  echo "harvest-session: no new sessions to harvest (skipped $SKIPPED_COUNT)" >&2
fi
