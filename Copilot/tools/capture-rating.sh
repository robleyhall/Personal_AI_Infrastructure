#!/usr/bin/env bash
# capture-rating.sh — Record an explicit satisfaction rating.
#
# Appends a JSON line to ~/.pai/MEMORY/LEARNING/SIGNALS/ratings.jsonl.
# For ratings ≤ 3, also writes a failure capture file.
#
# Usage:
#   capture-rating.sh --rating 8 [--comment "good work"] \
#                     [--session-id ID] [--summary "last response summary"]

set -euo pipefail

PAI_DIR="${PAI_DIR:-$HOME/.pai}"
RATING=""
COMMENT=""
SESSION_ID="${PAI_SESSION_ID:-unknown}"
SUMMARY=""

usage() {
  cat <<'EOF' >&2
usage: capture-rating.sh --rating N [--comment "..."] [--session-id ID] [--summary "..."]
  N must be 1-10.
EOF
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rating)     RATING="${2:-}"; shift 2 ;;
    --comment)    COMMENT="${2:-}"; shift 2 ;;
    --session-id) SESSION_ID="${2:-}"; shift 2 ;;
    --summary)    SUMMARY="${2:-}"; shift 2 ;;
    *) usage ;;
  esac
done

[[ -n "$RATING" ]] || usage
[[ "$RATING" =~ ^([1-9]|10)$ ]] || { echo "capture-rating: rating must be 1-10" >&2; exit 1; }

SIGNALS_DIR="$PAI_DIR/MEMORY/LEARNING/SIGNALS"
FAILURES_DIR="$PAI_DIR/MEMORY/LEARNING/FAILURES"
mkdir -p "$SIGNALS_DIR" "$FAILURES_DIR"

TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Use python3 for reliable JSON serialisation
python3 -c "
import json, sys
obj = {
    'ts': '$TIMESTAMP',
    'rating': $RATING,
    'session': '''$SESSION_ID''',
    'source': 'explicit',
    'comment': '''$(printf '%s' "$COMMENT" | sed "s/'/\\\\'/g")''',
    'summary': '''$(printf '%s' "$SUMMARY" | sed "s/'/\\\\'/g")'''
}
# Drop empty optional fields
obj = {k: v for k, v in obj.items() if v}
json.dump(obj, sys.stdout, ensure_ascii=False)
print()
" >> "$SIGNALS_DIR/ratings.jsonl"

echo "capture-rating: recorded rating $RATING"

# Failure capture for low ratings
if [[ "$RATING" -le 3 ]]; then
  FAILURE_FILE="$FAILURES_DIR/${TIMESTAMP//:/-}_rating${RATING}.md"

  # FailureCapture (upstream FailureCapture.ts): dump last N tool calls +
  # assistant snippets from the current Copilot session's events.jsonl so the
  # capture has concrete context, not just summary text.
  CONTEXT_BLOCK=""
  EVENTS_FILE=""
  if [[ -n "${SESSION_ID:-}" && "$SESSION_ID" != "unknown" ]]; then
    # Copilot session folders are keyed by a UUID; session env var may carry
    # either the UUID or the sidecar-derived id. Match either by stripping
    # sidecar prefix and searching.
    SHORT_ID="${SESSION_ID##*-}"
    CAND="$(ls -td "$HOME/.copilot/session-state/"*/ 2>/dev/null | head -5)"
    for d in $CAND; do
      if [[ -f "$d/events.jsonl" ]]; then
        EVENTS_FILE="$d/events.jsonl"
        break
      fi
    done
  fi
  if [[ -n "$EVENTS_FILE" && -f "$EVENTS_FILE" ]]; then
    CONTEXT_BLOCK="$(python3 - "$EVENTS_FILE" <<'PY'
import json, sys
path = sys.argv[1]
events = []
try:
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                events.append(json.loads(line))
            except Exception:
                pass
except Exception:
    sys.exit(0)

# Keep last 20 notable events
notable = [e for e in events if e.get('type') in (
    'user.message', 'assistant.message',
    'tool.execution_start', 'tool.execution_complete'
)][-20:]

def fmt(ev):
    t = ev.get('type', '?')
    ts = ev.get('timestamp', '')
    if t == 'user.message':
        msg = (ev.get('user_content') or '')[:200]
        return f"- [{ts}] USER: {msg}"
    if t == 'assistant.message':
        msg = (ev.get('assistant_content') or '')[:200]
        return f"- [{ts}] ASSIST: {msg}"
    if t == 'tool.execution_start':
        name = ev.get('tool_start_name') or ev.get('name', '?')
        return f"- [{ts}] TOOL start: {name}"
    if t == 'tool.execution_complete':
        name = ev.get('tool_start_name') or ev.get('name', '?')
        ok = ev.get('tool_complete_success')
        return f"- [{ts}] TOOL done: {name} success={ok}"
    return f"- [{ts}] {t}"

print('\n'.join(fmt(e) for e in notable))
PY
)"
  fi

  cat > "$FAILURE_FILE" <<EOF
# Failure Capture — Rating $RATING

- **Timestamp:** $TIMESTAMP
- **Session:** $SESSION_ID
- **Rating:** $RATING
- **Source:** explicit

## Comment

${COMMENT:-_(no comment provided)_}

## Response Summary

${SUMMARY:-_(no summary provided)_}

## Recent Session Context (last ~20 events)

${CONTEXT_BLOCK:-_(events.jsonl not found for this session)_}
EOF
  echo "capture-rating: failure capture written to $FAILURE_FILE"
fi
