#!/usr/bin/env bash
# Save compact research artifacts and promote a "what matters" digest into the
# memory files that session startup already reads.

set -euo pipefail

PAI_DIR="${PAI_DIR:-$HOME/.pai}"
MODE=""
TOPIC=""
SOURCE_URLS=""
NEXT_ACTIONS=""
ARTIFACT=""

usage() {
  cat <<'EOF' >&2
usage: save-research-memory.sh --topic "..." --mode quick|standard|extensive|deep [--sources "url1, url2"] [--next "next action"] [--artifact <path-to-full-report>]

Reads a markdown "what matters" digest from stdin and writes:
  - ~/.pai/MEMORY/RESEARCH/YYYY-MM/YYYY-MM-DD_topic-slug/SUMMARY.md
  - ~/.pai/MEMORY/RESEARCH/YYYY-MM/YYYY-MM-DD_topic-slug/WHAT_MATTERS.md
  - ~/.pai/MEMORY/LEARNING/latest.md

If --artifact is given, the file at <path> is copied into the research dir as
REPORT.md and surfaced in latest.md as the primary full-report pointer.

Does NOT touch ~/.pai/MEMORY/WORK/active.md — that file is curated by hand
per the single-overwritten-block convention; do not append there.
EOF
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --topic) TOPIC="${2:-}"; shift 2 ;;
    --mode) MODE="${2:-}"; shift 2 ;;
    --sources) SOURCE_URLS="${2:-}"; shift 2 ;;
    --next) NEXT_ACTIONS="${2:-}"; shift 2 ;;
    --artifact) ARTIFACT="${2:-}"; shift 2 ;;
    *) usage ;;
  esac
done

[[ -n "$TOPIC" && -n "$MODE" ]] || usage

if [[ -n "$ARTIFACT" && ! -r "$ARTIFACT" ]]; then
  echo "save-research-memory: --artifact path not readable: $ARTIFACT" >&2
  exit 1
fi

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
REPORT_FILE="$RESEARCH_DIR/REPORT.md"
LEARNING_FILE="$PAI_DIR/MEMORY/LEARNING/latest.md"

mkdir -p "$RESEARCH_DIR" "$(dirname "$LEARNING_FILE")"

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

if [[ -n "$ARTIFACT" ]]; then
  cp "$ARTIFACT" "$REPORT_FILE"
  printf -- '- **Full report:** %s\n' "$REPORT_FILE" >>"$WHAT_MATTERS_FILE"
fi

if [[ -n "$SOURCE_URLS" ]]; then
  printf -- '- **Verified sources:** %s\n' "$SOURCE_URLS" >>"$WHAT_MATTERS_FILE"
fi

if [[ -n "$NEXT_ACTIONS" ]]; then
  printf -- '- **Next actions:** %s\n' "$NEXT_ACTIONS" >>"$WHAT_MATTERS_FILE"
fi

printf '\n## Digest\n\n%s\n' "$WHAT_MATTERS_CONTENT" >>"$WHAT_MATTERS_FILE"

cat >"$LEARNING_FILE" <<EOF
# Latest Research Memory

- **Captured:** $TIMESTAMP_UTC
- **Topic:** $TOPIC
- **Mode:** $MODE
EOF

if [[ -n "$ARTIFACT" ]]; then
  printf -- '- **Full report:** %s\n' "$REPORT_FILE" >>"$LEARNING_FILE"
fi

cat >>"$LEARNING_FILE" <<EOF
- **What matters:** $WHAT_MATTERS_FILE
- **Summary:** $SUMMARY_FILE
EOF

if [[ -n "$NEXT_ACTIONS" ]]; then
  printf -- '- **Next actions:** %s\n' "$NEXT_ACTIONS" >>"$LEARNING_FILE"
fi

printf '\n## Digest\n\n%s\n' "$WHAT_MATTERS_CONTENT" >>"$LEARNING_FILE"

printf '%s\n' "$RESEARCH_DIR"

# ── Best-effort: append AAAK pointer record ──────────────────────────
# Failures here MUST NOT fail the parent capture (artifact already saved).
APPEND_POINTER="$PAI_DIR/tools/append-pointer.sh"
APPEND_DAILY="$PAI_DIR/tools/append-daily.sh"
PTR_ID=""
if [[ -x "$APPEND_POINTER" ]]; then
  PTR_TARGET=""
  if [[ -n "$ARTIFACT" ]]; then
    PTR_TARGET="pai://MEMORY/RESEARCH/$MONTH_PREFIX/${DATE_PREFIX}_${TOPIC_SLUG}/REPORT.md"
  else
    PTR_TARGET="pai://MEMORY/RESEARCH/$MONTH_PREFIX/${DATE_PREFIX}_${TOPIC_SLUG}/SUMMARY.md"
  fi
  if PTR_ID=$("$APPEND_POINTER" \
        --wing research \
        --drawer "$TOPIC_SLUG" \
        --target "$PTR_TARGET" \
        --event-tag "research,$MODE" \
        --time "$TIMESTAMP_UTC" \
      2>/dev/null); then
    :
  else
    PTR_ID=""
    printf 'save-research-memory: warning: pointer append failed (research dir saved at %s)\n' \
      "$RESEARCH_DIR" >&2
  fi
fi

# Best-effort: drop a DAILY ledger entry as well.
if [[ -x "$APPEND_DAILY" ]]; then
  "$APPEND_DAILY" \
    --source save-research \
    --event research-capture \
    ${PAI_SESSION_ID:+--session "$PAI_SESSION_ID"} \
    ${PTR_ID:+--ptr "$PTR_ID"} \
    --detail "$TOPIC_SLUG mode=$MODE" \
    >/dev/null 2>&1 \
    || printf 'save-research-memory: warning: daily-ledger append failed\n' >&2
fi


