#!/usr/bin/env bash
# secret-scan.sh — Scan files/dirs for common secret patterns.
#
# Pure shell port of upstream PAI/Tools/SecretScan.ts semantics.
# No bun, no external dependencies beyond grep + common coreutils.
#
# Usage:
#   secret-scan.sh <path> [<path> ...]
#   secret-scan.sh .                   # current dir
#   secret-scan.sh --staged            # git staged files (pre-commit mode)
#   secret-scan.sh --quiet <path>      # exit code only
#
# Exit: 0 = no secrets found, 1 = secrets found, 2 = usage error.
#
# Patterns detected:
#   - AWS access keys (AKIA/ASIA + 16 uppercase hex)
#   - AWS secret keys (40-char base64-ish after "aws_secret")
#   - GitHub tokens (ghp_, gho_, ghu_, ghs_, ghr_ + 36 chars)
#   - Private key blocks (BEGIN ... PRIVATE KEY)
#   - Generic .env-style high-entropy KEY=value with suspicious names
#   - Slack tokens (xox[baprs]-...)
#   - Google API keys (AIza + 35)
#   - Bearer tokens in source (Authorization: Bearer ...)

set -uo pipefail

QUIET=0
STAGED=0
PATHS=()

usage() {
  sed -n '2,23p' "$0" | sed 's/^# \{0,1\}//' >&2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --quiet)  QUIET=1; shift ;;
    --staged) STAGED=1; shift ;;
    -h|--help) usage ;;
    --) shift; PATHS+=("$@"); break ;;
    -*) echo "unknown flag: $1" >&2; usage ;;
    *) PATHS+=("$1"); shift ;;
  esac
done

# Build list of files to scan.
FILES=()
if [[ "$STAGED" == "1" ]]; then
  while IFS= read -r f; do
    [[ -n "$f" && -f "$f" ]] && FILES+=("$f")
  done < <(git diff --cached --name-only --diff-filter=ACM 2>/dev/null)
elif [[ "${#PATHS[@]}" -eq 0 ]]; then
  usage
else
  for p in "${PATHS[@]}"; do
    if [[ -f "$p" ]]; then
      FILES+=("$p")
    elif [[ -d "$p" ]]; then
      while IFS= read -r f; do
        FILES+=("$f")
      done < <(find "$p" -type f \
        -not -path '*/.git/*' \
        -not -path '*/node_modules/*' \
        -not -path '*/.venv/*' \
        -not -path '*/dist/*' \
        -not -path '*/build/*' \
        2>/dev/null)
    fi
  done
fi

[[ "${#FILES[@]}" -gt 0 ]] || { [[ "$QUIET" == "1" ]] || echo "secret-scan: no files to scan" >&2; exit 0; }

# Pattern set. Each line: <label>|<regex>
# Using -E for ERE. Patterns are conservative to limit false positives.
PATTERNS='AWS_AKID|(?:AKIA|ASIA)[0-9A-Z]{16}
AWS_SECRET|aws(.{0,20})?(secret|access).{0,5}key.{0,5}[=:].{0,5}[A-Za-z0-9/+]{40}
GITHUB_PAT|gh[poushr]_[A-Za-z0-9_]{36,}
PRIVATE_KEY|-----BEGIN ([A-Z ]+ )?PRIVATE KEY( BLOCK)?-----
SLACK_TOKEN|xox[baprs]-[A-Za-z0-9-]{10,}
GOOGLE_API|AIza[0-9A-Za-z_-]{35}
BEARER_TOKEN|[Aa]uthorization:[ \t]*[Bb]earer[ \t]+[A-Za-z0-9._-]{20,}
ENV_HIGH_ENTROPY|^[[:space:]]*[A-Z][A-Z0-9_]*(SECRET|TOKEN|PASSWORD|API_KEY|PRIVATE)[A-Z0-9_]*[[:space:]]*=[[:space:]]*["'\'']?[A-Za-z0-9/+_.=-]{20,}'

HITS=0
HIT_REPORT=""

while IFS='|' read -r label pattern; do
  [[ -z "$label" ]] && continue
  while IFS= read -r hit; do
    [[ -z "$hit" ]] && continue
    HITS=$((HITS + 1))
    HIT_REPORT+=$'\n'"[$label] $hit"
  done < <(grep -EnIH "$pattern" "${FILES[@]}" 2>/dev/null || true)
done <<<"$PATTERNS"

if [[ "$HITS" -gt 0 ]]; then
  if [[ "$QUIET" == "0" ]]; then
    echo "secret-scan: $HITS potential secret(s) found" >&2
    echo "$HIT_REPORT" >&2
  fi
  exit 1
fi

[[ "$QUIET" == "1" ]] || echo "secret-scan: no secrets found in ${#FILES[@]} file(s)"
exit 0
