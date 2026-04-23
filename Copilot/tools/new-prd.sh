#!/usr/bin/env bash
# new-prd.sh — Scaffold a PAI Algorithm PRD dir under ~/.pai/MEMORY/WORK/
#
# Usage:
#   new-prd.sh --task "8 word task description" --slug task-slug [--effort standard]
#
# Creates: ~/.pai/MEMORY/WORK/<YYYYMMDDTHHMMSSZ>_<slug>/PRD.md
# Format: upstream PAI PRDFORMAT v2.0 frontmatter + ISC scaffold.
#
# Mechanical port of upstream PRD scaffolding. Upstream uses a hook to
# generate PRDs on Algorithm start; Copilot CLI has no hook API, so we
# expose it as a tool that Algorithm-mode invokes explicitly.

set -euo pipefail

PAI_DIR="${PAI_DIR:-$HOME/.pai}"
TASK=""
SLUG=""
EFFORT="standard"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --task)    TASK="$2"; shift 2 ;;
    --slug)    SLUG="$2"; shift 2 ;;
    --effort)  EFFORT="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "unknown flag: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$TASK" || -z "$SLUG" ]]; then
  echo "error: --task and --slug are required" >&2
  exit 2
fi

case "$EFFORT" in
  standard|extended|advanced|deep|comprehensive) ;;
  *) echo "error: --effort must be one of standard|extended|advanced|deep|comprehensive" >&2; exit 2 ;;
esac

TS_DIR="$(date -u +%Y%m%dT%H%M%SZ)"
TS_ISO="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
SLUG_SAFE="$(echo "$SLUG" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9-' '-' | sed 's/--*/-/g; s/^-//; s/-$//')"

DIR="$PAI_DIR/MEMORY/WORK/${TS_DIR}_${SLUG_SAFE}"
if [[ -e "$DIR" ]]; then
  echo "error: $DIR already exists" >&2
  exit 1
fi

mkdir -p "$DIR"
PRD="$DIR/PRD.md"

cat > "$PRD" <<EOF
---
task: "${TASK}"
slug: ${TS_DIR}_${SLUG_SAFE}
effort: ${EFFORT}
phase: observe
progress: 0/0
mode: interactive
started: ${TS_ISO}
updated: ${TS_ISO}
---

# PRD — ${TASK}

## Context

_Describe the problem and why it matters._

## Ideal State Criteria (ISC)

_Testable checkboxes. Update progress as each passes._

- [ ] TODO: first criterion

## Approach

_Phase-2 THINK output. How you plan to solve it._

## Notes

_Observations, constraints, decisions. Append as you go._

EOF

echo "$PRD"
