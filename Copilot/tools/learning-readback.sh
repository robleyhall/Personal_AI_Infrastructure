#!/usr/bin/env bash
# learning-readback.sh — Produce a compact startup digest from recent learnings.
#
# Reads the 3 most recent files from ALGORITHM/ and SYSTEM/, any wisdom
# frames, and recent failure patterns. Outputs a compact (<2000 char)
# digest to stdout suitable for injection into the session context.
#
# Usage:
#   learning-readback.sh              # default: 3 recent per category
#   learning-readback.sh --limit 5    # 5 recent per category

set -euo pipefail

PAI_DIR="${PAI_DIR:-$HOME/.pai}"
LIMIT=3

while [[ $# -gt 0 ]]; do
  case "$1" in
    --limit) LIMIT="${2:-3}"; shift 2 ;;
    *) shift ;;
  esac
done

LEARNING_DIR="$PAI_DIR/MEMORY/LEARNING"
WISDOM_DIR="$PAI_DIR/MEMORY/WISDOM/FRAMES"
OUTPUT=""

# ── Helper: extract first heading + first few content lines ──────────
extract_digest() {
  local file="$1"
  local max_lines="${2:-4}"
  # Grab the first heading and the first N non-empty, non-heading lines after it
  awk -v max="$max_lines" '
    /^#/ && !seen_heading { heading=$0; seen_heading=1; next }
    seen_heading && NF && !/^#/ && !/^-.*Captured:/ && !/^-.*Session:/ && !/^-.*Category:/ && !/^---$/ {
      lines[++n] = $0
      if (n >= max) exit
    }
    END {
      if (heading) print heading
      for (i=1; i<=n; i++) print lines[i]
    }
  ' "$file"
}

# ── Recent learnings (ALGORITHM + SYSTEM) ────────────────────────────
collect_recent() {
  local category="$1"
  local dir="$LEARNING_DIR/$category"
  [[ -d "$dir" ]] || return 0

  local files
  files="$(find "$dir" -name '*.md' -type f 2>/dev/null | sort -r | head -n "$LIMIT")"
  [[ -n "$files" ]] || return 0

  local section=""
  while IFS= read -r f; do
    local digest
    digest="$(extract_digest "$f" 3)"
    [[ -n "$digest" ]] && section="${section}${digest}\n\n"
  done <<< "$files"

  if [[ -n "$section" ]]; then
    OUTPUT="${OUTPUT}### Recent ${category} Learnings\n\n${section}"
  fi
}

# ── Wisdom frames ────────────────────────────────────────────────────
collect_wisdom() {
  [[ -d "$WISDOM_DIR" ]] || return 0
  local files
  files="$(find "$WISDOM_DIR" -name '*.md' -type f 2>/dev/null | sort -r | head -n 3)"
  [[ -n "$files" ]] || return 0

  local section=""
  while IFS= read -r f; do
    local digest
    digest="$(extract_digest "$f" 2)"
    [[ -n "$digest" ]] && section="${section}${digest}\n\n"
  done <<< "$files"

  if [[ -n "$section" ]]; then
    OUTPUT="${OUTPUT}### Wisdom Frames\n\n${section}"
  fi
}

# ── Recent failures ──────────────────────────────────────────────────
collect_failures() {
  local dir="$LEARNING_DIR/FAILURES"
  [[ -d "$dir" ]] || return 0

  local files
  files="$(find "$dir" -name '*.md' -type f 2>/dev/null | sort -r | head -n 2)"
  [[ -n "$files" ]] || return 0

  local section=""
  while IFS= read -r f; do
    local digest
    digest="$(extract_digest "$f" 3)"
    [[ -n "$digest" ]] && section="${section}${digest}\n\n"
  done <<< "$files"

  if [[ -n "$section" ]]; then
    OUTPUT="${OUTPUT}### Recent Failures to Avoid\n\n${section}"
  fi
}

# ── Project engagement (active + stale) ──────────────────────────────
collect_engagement() {
  local distiller="$PAI_DIR/tools/engagement-distill.sh"
  [[ -x "$distiller" ]] || return 0
  local section
  section="$("$distiller" 2>/dev/null || true)"
  [[ -n "$section" ]] || return 0
  OUTPUT="${OUTPUT}${section}\n\n"
}

# ── Assemble ─────────────────────────────────────────────────────────
collect_recent "ALGORITHM"
collect_recent "SYSTEM"
collect_wisdom
collect_failures
collect_engagement

if [[ -n "$OUTPUT" ]]; then
  printf '## Session Memory Digest\n\n'
  printf '%b' "$OUTPUT"
else
  echo "_(no learnings recorded yet)_"
fi
