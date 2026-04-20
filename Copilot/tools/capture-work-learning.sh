#!/usr/bin/env bash
# capture-work-learning.sh — Persist a work-session learning artifact.
#
# Reads learning content from stdin (markdown) and writes it to the
# appropriate LEARNING subdirectory (ALGORITHM or SYSTEM) using simple
# keyword-based categorisation ported from learning-utils.ts.
#
# Usage:
#   echo "learned X about Y" | capture-work-learning.sh --slug "my-task"
#   capture-work-learning.sh --slug "infra-fix" --category system < notes.md

set -euo pipefail

PAI_DIR="${PAI_DIR:-$HOME/.pai}"
SLUG=""
CATEGORY=""

usage() {
  cat <<'EOF' >&2
usage: capture-work-learning.sh --slug "topic-slug" [--category algorithm|system]
  Reads learning content from stdin.
EOF
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --slug)     SLUG="${2:-}"; shift 2 ;;
    --category) CATEGORY="${2:-}"; shift 2 ;;
    *) usage ;;
  esac
done

[[ -n "$SLUG" ]] || usage

CONTENT="$(cat)"
[[ -n "$CONTENT" ]] || { echo "capture-work-learning: stdin is empty" >&2; exit 1; }

# ── Auto-categorise (ported from learning-utils.ts) ──────────────────
# SYSTEM keywords: tooling, infra, CI, environment, build, config, install,
#   dependency, version, path, permission, timeout, network, API limit.
# Everything else defaults to ALGORITHM.
if [[ -z "$CATEGORY" ]]; then
  SYSTEM_PATTERN='(tooling|infra|CI|environment|build|config|install|dependency|version|path|permission|timeout|network|API limit|rate.limit|deploy|docker|npm|pip|brew|apt|cargo|bun)'
  if echo "$CONTENT" | grep -iEq "$SYSTEM_PATTERN"; then
    CATEGORY="SYSTEM"
  else
    CATEGORY="ALGORITHM"
  fi
fi

CATEGORY="$(echo "$CATEGORY" | tr '[:lower:]' '[:upper:]')"
[[ "$CATEGORY" == "ALGORITHM" || "$CATEGORY" == "SYSTEM" ]] || {
  echo "capture-work-learning: category must be algorithm or system" >&2; exit 1
}

TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
MONTH="$(date -u +%Y-%m)"
FILE_TS="$(date -u +%Y-%m-%d_%H%M%S)"

slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g'
}
SLUG_CLEAN="$(slugify "$SLUG")"

OUT_DIR="$PAI_DIR/MEMORY/LEARNING/$CATEGORY/$MONTH"
mkdir -p "$OUT_DIR"
OUT_FILE="$OUT_DIR/${FILE_TS}_work_${SLUG_CLEAN}.md"

cat > "$OUT_FILE" <<EOF
# Work Learning — $SLUG

- **Category:** $CATEGORY
- **Captured:** $TIMESTAMP
- **Session:** ${PAI_SESSION_ID:-unknown}

---

$CONTENT
EOF

echo "capture-work-learning: saved to $OUT_FILE"
