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
EOF
  echo "capture-rating: failure capture written to $FAILURE_FILE"
fi
