#!/usr/bin/env bash
# Save compact research artifacts and promote a "what matters" digest into the
# memory files that session startup already reads.

set -euo pipefail

PAI_DIR="${PAI_DIR:-$HOME/.pai}"
MODE=""
TOPIC=""
SOURCE_URLS=""
NEXT_ACTIONS=""

usage() {
  cat <<'EOF' >&2
usage: save-research-memory.sh --topic "..." --mode quick|standard|extensive|deep [--sources "url1, url2"] [--next "next action"]

Reads a markdown summary from stdin and writes:
  - ~/.pai/MEMORY/RESEARCH/YYYY-MM/YYYY-MM-DD_topic-slug/SUMMARY.md
  - ~/.pai/MEMORY/RESEARCH/YYYY-MM/YYYY-MM-DD_topic-slug/WHAT_MATTERS.md
  - ~/.pai/MEMORY/WORK/active.md
  - ~/.pai/MEMORY/LEARNING/latest.md
EOF
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --topic) TOPIC="${2:-}"; shift 2 ;;
    --mode) MODE="${2:-}"; shift 2 ;;
    --sources) SOURCE_URLS="${2:-}"; shift 2 ;;
    --next) NEXT_ACTIONS="${2:-}"; shift 2 ;;
    *) usage ;;
  esac
done

[[ -n "$TOPIC" && -n "$MODE" ]] || usage

slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g'
}

trim_block() {
  awk 'NF { seen=1 } seen { print }' \
    | awk 'BEGIN{limit=120} { lines[++n]=$0 } END { start = (n > limit ? n - limit + 1 : 1); for (i=start; i<=n; i++) print lines[i] }'
}

TIMESTAMP_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
DATE_PREFIX="$(date -u +%Y-%m-%d)"
MONTH_PREFIX="$(date -u +%Y-%m)"
TOPIC_SLUG="$(slugify "$TOPIC")"
RESEARCH_DIR="$PAI_DIR/MEMORY/RESEARCH/$MONTH_PREFIX/${DATE_PREFIX}_${TOPIC_SLUG}"
SUMMARY_FILE="$RESEARCH_DIR/SUMMARY.md"
WHAT_MATTERS_FILE="$RESEARCH_DIR/WHAT_MATTERS.md"
ACTIVE_FILE="$PAI_DIR/MEMORY/WORK/active.md"
LEARNING_FILE="$PAI_DIR/MEMORY/LEARNING/latest.md"

mkdir -p "$RESEARCH_DIR" "$(dirname "$ACTIVE_FILE")" "$(dirname "$LEARNING_FILE")"

SUMMARY_CONTENT="$(cat)"
[[ -n "$SUMMARY_CONTENT" ]] || { echo "save-research-memory: stdin summary is empty" >&2; exit 1; }

cat >"$SUMMARY_FILE" <<EOF
# Research Summary

- **Topic:** $TOPIC
- **Mode:** $MODE
- **Captured:** $TIMESTAMP_UTC

$SUMMARY_CONTENT
EOF

WHAT_MATTERS_CONTENT="$(printf '%s\n' "$SUMMARY_CONTENT" | trim_block)"

cat >"$WHAT_MATTERS_FILE" <<EOF
# What Matters

- **Topic:** $TOPIC
- **Mode:** $MODE
- **Captured:** $TIMESTAMP_UTC
- **Summary artifact:** $SUMMARY_FILE
EOF

if [[ -n "$SOURCE_URLS" ]]; then
  printf -- '- **Verified sources:** %s\n' "$SOURCE_URLS" >>"$WHAT_MATTERS_FILE"
fi

if [[ -n "$NEXT_ACTIONS" ]]; then
  printf -- '- **Next actions:** %s\n' "$NEXT_ACTIONS" >>"$WHAT_MATTERS_FILE"
fi

printf '\n## Digest\n\n%s\n' "$WHAT_MATTERS_CONTENT" >>"$WHAT_MATTERS_FILE"

cat >>"$ACTIVE_FILE" <<EOF

## Research Snapshot — $DATE_PREFIX — $TOPIC

- **Mode:** $MODE
- **Artifact:** $SUMMARY_FILE
- **What matters:** $WHAT_MATTERS_FILE
EOF

if [[ -n "$NEXT_ACTIONS" ]]; then
  printf -- '- **Next actions:** %s\n' "$NEXT_ACTIONS" >>"$ACTIVE_FILE"
fi

printf '\n%s\n' "$WHAT_MATTERS_CONTENT" >>"$ACTIVE_FILE"

cat >"$LEARNING_FILE" <<EOF
# Latest Research Memory

- **Captured:** $TIMESTAMP_UTC
- **Topic:** $TOPIC
- **Mode:** $MODE
- **What matters:** $WHAT_MATTERS_FILE
- **Artifact:** $SUMMARY_FILE
EOF

if [[ -n "$NEXT_ACTIONS" ]]; then
  printf -- '- **Next actions:** %s\n' "$NEXT_ACTIONS" >>"$LEARNING_FILE"
fi

printf '\n## Digest\n\n%s\n' "$WHAT_MATTERS_CONTENT" >>"$LEARNING_FILE"

printf '%s\n' "$WHAT_MATTERS_FILE"
