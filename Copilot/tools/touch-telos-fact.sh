#!/usr/bin/env bash
# touch-telos-fact.sh — bump or add `_Verified: YYYY-MM-DD_` on a single
# TELOS bullet matched by exact heading + bold field label.
#
# Refuses if the match isn't unique (0 or >1 lines). Default mode is
# dry-run; pass --yes to actually mutate the file. Locks the target.
#
# Usage:
#   touch-telos-fact.sh --file PROJECTS.md --heading "OpenAI TUB" --field "Status"
#   touch-telos-fact.sh --file GOALS.md    --heading "1-Year Horizon — by April 2027" --field "Savings: \$750K." --yes
#
# Path resolution:
#   --file <name>          — relative to ~/.pai/USER/TELOS/
#   --file </abs/path.md>  — used as-is
#
# Heading match:
#   Matches the nearest preceding `## <heading>` or `### <heading>` line
#   (literal, trimmed). Subheadings inherit until the next h2.
#
# Field match:
#   Matches a bullet whose first bold span equals the field label, e.g.
#   `- **Status:** ...` matches --field "Status".
#
# Refs: tasks/memory-incorporation-plan.md A3; ~/.pai/USER/TELOS/README.md.

set -uo pipefail

PAI_DIR="${PAI_DIR:-$HOME/.pai}"
TELOS_DIR="$PAI_DIR/USER/TELOS"
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"
# shellcheck disable=SC1091
source "$LIB_DIR/with-pai-lock.sh"

FILE_ARG=""; HEADING=""; FIELD=""; APPLY=0

usage() {
  sed -n '1,30p' "$0" >&2
  exit 64
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file)    FILE_ARG="${2:-}"; shift 2 ;;
    --heading) HEADING="${2:-}"; shift 2 ;;
    --field)   FIELD="${2:-}"; shift 2 ;;
    --yes)     APPLY=1; shift ;;
    -h|--help) usage ;;
    *) printf 'touch-telos-fact: unknown arg: %s\n' "$1" >&2; usage ;;
  esac
done

[[ -n "$FILE_ARG" && -n "$HEADING" && -n "$FIELD" ]] || usage

if [[ "$FILE_ARG" == /* ]]; then
  TARGET="$FILE_ARG"
else
  TARGET="$TELOS_DIR/$FILE_ARG"
fi

[[ -f "$TARGET" ]] || { printf 'touch-telos-fact: file not found: %s\n' "$TARGET" >&2; exit 65; }

TODAY=$(date -u +%Y-%m-%d)

run_python() {
  python3 - "$TARGET" "$HEADING" "$FIELD" "$TODAY" "$APPLY" <<'PY'
import os
import re
import sys

target, heading, field, today, apply_flag = sys.argv[1:]
apply_flag = apply_flag == '1'

with open(target, 'r', encoding='utf-8') as f:
    lines = f.read().splitlines(keepends=True)

current_heading = ""
matches = []
for i, line in enumerate(lines):
    m = re.match(r'^(##+)\s+(.*?)\s*$', line)
    if m:
        current_heading = m.group(2).strip()
        continue
    if current_heading != heading:
        continue
    m2 = re.match(r'^\s*[-*+]\s+\*\*([^*]+?):\*\*', line)
    if not m2:
        continue
    label = m2.group(1).strip()
    if label == field:
        matches.append((i, line))

if not matches:
    sys.stderr.write(
        f'touch-telos-fact: no bullet matched heading="{heading}" field="{field}" in {target}\n'
    )
    sys.exit(66)
if len(matches) > 1:
    sys.stderr.write(
        f'touch-telos-fact: {len(matches)} bullets matched heading="{heading}" field="{field}" — refusing.\n'
    )
    for idx, ln in matches:
        sys.stderr.write(f'  line {idx + 1}: {ln.rstrip()}\n')
    sys.exit(67)

idx, original = matches[0]
verified_re = re.compile(r'_Verified:\s*\d{4}-\d{2}-\d{2}_')
new_marker = f'_Verified: {today}_'

if verified_re.search(original):
    new_line = verified_re.sub(new_marker, original)
else:
    if original.endswith('\n'):
        new_line = original[:-1].rstrip() + ' ' + new_marker + '\n'
    else:
        new_line = original.rstrip() + ' ' + new_marker

if new_line == original:
    sys.stderr.write('touch-telos-fact: line already up-to-date; nothing to do.\n')
    sys.exit(0)

sys.stderr.write('--- proposed change ---\n')
sys.stderr.write(f'- {original.rstrip()}\n')
sys.stderr.write(f'+ {new_line.rstrip()}\n')

if not apply_flag:
    sys.stderr.write('(dry-run — pass --yes to apply)\n')
    sys.exit(0)

lines[idx] = new_line
tmp = target + '.tmp'
with open(tmp, 'w', encoding='utf-8') as f:
    f.writelines(lines)
os.replace(tmp, target)
sys.stderr.write(f'touch-telos-fact: applied to {target}:{idx + 1}\n')
PY
}

export -f run_python
export TARGET HEADING FIELD TODAY APPLY

# Lock the file by basename so concurrent --yes invocations don't race.
LOCK_NAME="telos-$(basename "$TARGET")"
with_pai_lock "$LOCK_NAME" bash -c "run_python"
exit $?

