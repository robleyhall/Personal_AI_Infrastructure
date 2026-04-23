#!/usr/bin/env bash
# backfill-prd-frontmatter.sh — Add PRDFORMAT v2.0 frontmatter to existing
# MEMORY/WORK/<slug>/ docs that predate `bun ~/.pai/PAI/Tools/algorithm.ts new` (Tier 2).
#
# Idempotent: skips files that already have YAML frontmatter with `task:`.
#
# Usage:
#   backfill-prd-frontmatter.sh                # dry-run against ~/.pai/MEMORY/WORK/
#   backfill-prd-frontmatter.sh --apply        # write changes
#   backfill-prd-frontmatter.sh --apply --dir <path>

set -euo pipefail

PAI_DIR="${PAI_DIR:-$HOME/.pai}"
TARGET_DIR="$PAI_DIR/MEMORY/WORK"
APPLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=1; shift ;;
    --dir)   TARGET_DIR="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "unknown flag: $1" >&2; exit 2 ;;
  esac
done

[[ -d "$TARGET_DIR" ]] || { echo "error: $TARGET_DIR not a directory" >&2; exit 1; }

TOUCHED=0
SKIPPED=0

# Iterate each subdir (skip plain files + the `projects/` subdir which is
# engagement tracking, not PRD territory).
for slug_dir in "$TARGET_DIR"/*/; do
  [[ -d "$slug_dir" ]] || continue
  base="$(basename "${slug_dir%/}")"
  [[ "$base" == "projects" ]] && continue

  # Target the PRD file. Prefer PRD.md if present; else first .md in dir.
  prd_file=""
  if [[ -f "$slug_dir/PRD.md" ]]; then
    prd_file="$slug_dir/PRD.md"
  else
    shopt -s nullglob
    for f in "$slug_dir"*.md; do prd_file="$f"; break; done
    shopt -u nullglob
  fi
  [[ -n "$prd_file" ]] || { SKIPPED=$((SKIPPED+1)); continue; }

  # Skip if already has frontmatter with task: field.
  if head -10 "$prd_file" | grep -qE '^task:[[:space:]]'; then
    SKIPPED=$((SKIPPED+1))
    continue
  fi

  # Derive fields. slug = dir name. task = slug's human portion.
  slug="$base"
  # <YYYYMMDDTHHMMSSZ>_<slug-text>  or  <YYYYMMDDTHHMMSSZ>-<slug-text>
  task_raw="${slug#*_}"
  [[ "$task_raw" == "$slug" ]] && task_raw="${slug#*-}"
  # Convert dashes/underscores to spaces, title-case first letter of each word.
  # BSD-sed compatible: use awk.
  task="$(printf '%s' "$task_raw" | tr '_-' '  ' | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1)) tolower(substr($i,2))}; print}')"

  # started: best-effort. Parse the timestamp in the slug prefix.
  stamp="${slug%%_*}"
  stamp="${stamp%%-*}"
  if [[ "$stamp" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})T([0-9]{2})([0-9]{2})([0-9]{2})Z$ ]]; then
    started="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}T${BASH_REMATCH[4]}:${BASH_REMATCH[5]}:${BASH_REMATCH[6]}Z"
  else
    # Fallback: file mtime
    started="$(date -u -r "$prd_file" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  fi
  updated="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  if [[ "$APPLY" == "1" ]]; then
    tmp="$(mktemp)"
    cat > "$tmp" <<EOF
---
task: "${task}"
slug: ${slug}
effort: standard
phase: complete
progress: 1/1
mode: interactive
started: ${started}
updated: ${updated}
backfilled: true
---

EOF
    cat "$prd_file" >> "$tmp"
    mv "$tmp" "$prd_file"
    echo "backfilled: $prd_file"
  else
    echo "would backfill: $prd_file (task=\"$task\" slug=$slug started=$started)"
  fi
  TOUCHED=$((TOUCHED + 1))
done

if [[ "$APPLY" == "1" ]]; then
  echo "backfill-prd-frontmatter: $TOUCHED file(s) updated, $SKIPPED skipped (already have frontmatter or no .md)"
else
  echo "backfill-prd-frontmatter: $TOUCHED file(s) would be updated, $SKIPPED skipped. Re-run with --apply to write."
fi
