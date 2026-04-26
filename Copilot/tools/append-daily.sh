#!/usr/bin/env bash
# append-daily.sh — single writer for ~/.pai/MEMORY/DAILY/<YYYY-MM-DD>.md
#
# Strict one-line machine event ledger. No prose. Each entry includes enough
# metadata to trace back to a session and a pointer.
#
# Usage:
#   append-daily.sh \
#     --source <name> \           # sidecar | harvest | save-research | capture-work | manual
#     --event <type> \            # session-start | session-close | research-capture | work-learning | ...
#     [--session <id>] \
#     [--ptr <P-...>] \
#     [--detail "<≤80 chars>"]
#
# Idempotency: if today's file already contains an entry with the same
# (source, event, session-id, minute-bucket), the new entry is skipped.
#
# Locked via with-pai-lock to keep concurrent sidecar/harvest/capture writes
# from interleaving.
#
# Refs: tasks/memory-incorporation-plan.md A1.

set -uo pipefail

PAI_DIR="${PAI_DIR:-$HOME/.pai}"
DAILY_DIR="$PAI_DIR/MEMORY/DAILY"
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"
# shellcheck disable=SC1091
source "$LIB_DIR/with-pai-lock.sh"

SOURCE=""; EVENT=""; SESSION=""; PTR=""; DETAIL=""

usage() {
  cat >&2 <<'EOF'
usage: append-daily.sh --source <name> --event <type> [--session <id>] [--ptr <P-...>] [--detail "<text>"]

Examples:
  append-daily.sh --source sidecar --event session-start --session $PAI_SESSION_ID
  append-daily.sh --source harvest --event session-close --session abc12345 --detail "harvested=2"
  append-daily.sh --source save-research --event research-capture --ptr P-... --detail "claude-memory"
EOF
  exit 64
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)  SOURCE="${2:-}";  shift 2 ;;
    --event)   EVENT="${2:-}";   shift 2 ;;
    --session) SESSION="${2:-}"; shift 2 ;;
    --ptr)     PTR="${2:-}";     shift 2 ;;
    --detail)  DETAIL="${2:-}";  shift 2 ;;
    -h|--help) usage ;;
    *) printf 'append-daily.sh: unknown arg: %s\n' "$1" >&2; usage ;;
  esac
done

[[ -n "$SOURCE" && -n "$EVENT" ]] || usage

# Truncate detail to 80 chars and strip newlines so the line stays one-line.
DETAIL=$(printf '%s' "$DETAIL" | tr '\n\r' '  ' | cut -c1-80)

NOW_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)
TODAY=$(date -u +%Y-%m-%d)
HHMMZ=$(date -u +%H:%MZ)
MINUTE_BUCKET=$(date -u +%Y-%m-%dT%H:%M)

mkdir -p "$DAILY_DIR"
DAILY_FILE="$DAILY_DIR/$TODAY.md"

# Initialize today's file with a header on first write.
init_if_needed() {
  if [[ ! -f "$DAILY_FILE" ]]; then
    {
      printf '# DAILY %s (UTC)\n\n' "$TODAY"
      printf 'Machine event ledger. Single-line entries. Do not edit by hand.\n\n'
    } >> "$DAILY_FILE"
  fi
}

build_line() {
  # Format: - HH:MMZ — <event> — source=<name> session=<id> ptr=<P-...> <detail>
  local parts="source=$SOURCE"
  [[ -n "$SESSION" ]] && parts="$parts session=$SESSION"
  [[ -n "$PTR"     ]] && parts="$parts ptr=$PTR"
  [[ -n "$DETAIL"  ]] && parts="$parts $DETAIL"
  printf -- '- %s — %s — %s\n' "$HHMMZ" "$EVENT" "$parts"
}

# Idempotency key: source + event + session + minute bucket. If a line
# already exists today matching this key, skip.
idempotency_match() {
  [[ -f "$DAILY_FILE" ]] || return 1
  local pattern_session
  if [[ -n "$SESSION" ]]; then
    pattern_session="session=$SESSION"
  else
    pattern_session="session=NONE_DUMMY_TOKEN_$$"
  fi
  # Match minute prefix in HH:MM and source/event/session triple anywhere on line.
  local hm
  hm=${MINUTE_BUCKET:11:5}  # HH:MM
  grep -F -- "- $hm" "$DAILY_FILE" 2>/dev/null \
    | grep -F -- " — $EVENT — " \
    | grep -F -- "source=$SOURCE" \
    | grep -F -- "$pattern_session" \
    >/dev/null
}

write_locked() {
  init_if_needed
  if idempotency_match; then
    return 0
  fi
  build_line >> "$DAILY_FILE"
}

export -f init_if_needed idempotency_match build_line write_locked
export DAILY_FILE TODAY HHMMZ MINUTE_BUCKET SOURCE EVENT SESSION PTR DETAIL

with_pai_lock "daily-$TODAY" bash -c "write_locked" || {
  printf 'append-daily.sh: lock or write failed for %s\n' "$DAILY_FILE" >&2
  exit 75
}
