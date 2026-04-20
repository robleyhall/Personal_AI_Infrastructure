#!/usr/bin/env bash
# synthesize-learnings.sh — Aggregate session ratings into actionable patterns.
#
# Wraps synthesize-learnings.ts (ported from
# Releases/v4.0.3/.claude/PAI/Tools/LearningPatternSynthesis.ts). Reads
# ~/.pai/MEMORY/LEARNING/SIGNALS/ratings.jsonl, groups ratings by window,
# and writes synthesis reports to ~/.pai/MEMORY/LEARNING/SYNTHESIS/.
#
# Pass-through flags (all forwarded to the TS tool):
#   --week      Analyze last 7 days (default)
#   --month     Analyze last 30 days
#   --all       Analyze all ratings
#   --dry-run   Show analysis without writing
#
# Copilot spike note: this tool becomes meaningful only after ~3 weeks of
# accumulated ratings — early runs will report "insufficient data".

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS_ENTRY="$SCRIPT_DIR/synthesize-learnings.ts"

if ! command -v bun >/dev/null 2>&1; then
  echo "synthesize-learnings: bun is required on PATH" >&2
  exit 127
fi

if [[ ! -f "$TS_ENTRY" ]]; then
  echo "synthesize-learnings: missing $TS_ENTRY" >&2
  exit 1
fi

exec bun run "$TS_ENTRY" "$@"
