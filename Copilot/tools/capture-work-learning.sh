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
REFLECTION=0

usage() {
  cat <<'EOF' >&2
usage: capture-work-learning.sh --slug "topic-slug" [--category algorithm|system] [--reflection]
  Reads learning content from stdin.
  --reflection also appends a JSONL line to MEMORY/LEARNING/REFLECTIONS/algorithm-reflections.jsonl
  (intended for Algorithm Phase-7 LEARN captures).
EOF
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --slug)       SLUG="${2:-}"; shift 2 ;;
    --category)   CATEGORY="${2:-}"; shift 2 ;;
    --reflection) REFLECTION=1; shift ;;
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

# ── Best-effort: append AAAK pointer record ──────────────────────────
APPEND_POINTER="$PAI_DIR/tools/append-pointer.sh"
APPEND_DAILY="$PAI_DIR/tools/append-daily.sh"
PTR_ID=""
if [[ -x "$APPEND_POINTER" ]]; then
  WING_GUESS="pai"
  case "$SLUG_CLEAN" in
    *microsoft*|*ms-*|*tub*|*mcaps*) WING_GUESS="microsoft" ;;
    *homestead*|*farm*|*chicken*|*goat*) WING_GUESS="homestead" ;;
    *pkm*|*devonthink*|*onedrive*) WING_GUESS="pkm" ;;
    *health*|*medical*|*fitness*) WING_GUESS="health" ;;
    *consulting*|*client*) WING_GUESS="consulting" ;;
  esac
  PTR_REL="${OUT_FILE#$PAI_DIR/}"
  if PTR_ID=$("$APPEND_POINTER" \
        --wing "$WING_GUESS" \
        --drawer "$SLUG_CLEAN" \
        --target "pai://$PTR_REL" \
        --event-tag "work-learning,$(echo "$CATEGORY" | tr '[:upper:]' '[:lower:]')" \
        --time "$TIMESTAMP" \
      2>/dev/null); then
    :
  else
    PTR_ID=""
    printf 'capture-work-learning: warning: pointer append failed (artifact saved at %s)\n' \
      "$OUT_FILE" >&2
  fi
fi

# Best-effort: DAILY ledger entry.
if [[ -x "$APPEND_DAILY" ]]; then
  "$APPEND_DAILY" \
    --source capture-work \
    --event work-learning \
    ${PAI_SESSION_ID:+--session "$PAI_SESSION_ID"} \
    ${PTR_ID:+--ptr "$PTR_ID"} \
    --detail "$SLUG_CLEAN cat=$CATEGORY" \
    >/dev/null 2>&1 \
    || printf 'capture-work-learning: warning: daily-ledger append failed\n' >&2
fi


# ── Optional: append JSONL reflection for Algorithm Phase-7 ───────────
if [[ "$REFLECTION" == "1" ]]; then
  REFL_DIR="$PAI_DIR/MEMORY/LEARNING/REFLECTIONS"
  mkdir -p "$REFL_DIR"
  REFL_FILE="$REFL_DIR/algorithm-reflections.jsonl"
  # Use python for safe JSON encoding of arbitrary markdown content.
  python3 - "$TIMESTAMP" "$SLUG_CLEAN" "$CATEGORY" "$OUT_FILE" "${PAI_SESSION_ID:-unknown}" "$CONTENT" "$REFL_FILE" <<'PY'
import json, sys
ts, slug, cat, artifact, session, content, out = sys.argv[1:]
line = {
    "timestamp": ts,
    "slug": slug,
    "category": cat,
    "session": session,
    "artifact": artifact,
    "content": content,
}
with open(out, "a", encoding="utf-8") as f:
    f.write(json.dumps(line, ensure_ascii=False) + "\n")
PY
  echo "capture-work-learning: appended reflection to $REFL_FILE"
fi
