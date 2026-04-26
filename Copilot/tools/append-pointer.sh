#!/usr/bin/env bash
# append-pointer.sh — single writer for ~/.pai/MEMORY/INDEX/pointers.aaak
#
# Writes one append-only event record per invocation. Locked via
# with-pai-lock.sh. Validates URI scheme prefix only (no live resolution).
# Uses grouped printf calls (no heredocs) to avoid Copilot CLI shell-filter
# surprises and to keep escaping deterministic.
#
# Usage:
#   append-pointer.sh \
#     --wing <slug> \
#     --drawer <slug> \
#     --target <uri> \
#     [--id <existing-pointer-id>]            # for promote/supersede/reaffirm
#     [--event created|promoted|superseded|reaffirmed]   # default: created
#     [--canonical <uri>]                     # optional, on promotion
#     [--historical <uri>]                    # optional, on promotion
#     [--people "a,b"] [--location "x"] [--event-tag "..."] [--interest "..."]
#     [--time <ISO-8601>]                     # default: now (UTC)
#     [--quiet]                               # suppress stdout pointer ID
#
# Outputs the pointer ID on stdout (unless --quiet).
# Returns 0 on success; non-zero on validation error or lock timeout.
#
# Callers should treat invocation as best-effort: log a warning on failure,
# do not propagate the failure to the caller's primary write.
#
# Refs: tasks/memory-incorporation-plan.md A2.

set -uo pipefail

PAI_DIR="${PAI_DIR:-$HOME/.pai}"
POINTER_FILE="${POINTER_FILE:-$PAI_DIR/MEMORY/INDEX/pointers.aaak}"
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"
# shellcheck disable=SC1091
source "$LIB_DIR/with-pai-lock.sh"

KNOWN_WINGS=(pai microsoft homestead pkm relationship research health consulting)
KNOWN_SCHEMES=(pai:// file:// devonthink:// mempalace://)
KNOWN_EVENTS=(created promoted superseded reaffirmed)

usage() {
  sed -n 's/^# \{0,1\}//p' "$0" | sed -n '/^Usage:/,/^Refs:/p'
  exit 64
}

die() {
  printf 'append-pointer.sh: %s\n' "$*" >&2
  exit "${2:-65}"
}

contains() {
  # contains <needle> <haystack...>
  local needle="$1"; shift
  for x in "$@"; do
    [[ "$x" == "$needle" ]] && return 0
  done
  return 1
}

scheme_ok() {
  local uri="$1"
  for s in "${KNOWN_SCHEMES[@]}"; do
    [[ "$uri" == "$s"* ]] && return 0
  done
  return 1
}

slugify() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9-' '-' | sed -E 's/-+/-/g; s/^-//; s/-$//'
}

# --- arg parsing ---
WING=""; DRAWER=""; TARGET=""; ID=""; EVENT="created"
CANONICAL=""; HISTORICAL=""
PEOPLE=""; LOCATION=""; EVENT_TAG=""; INTEREST=""; TIME_OVERRIDE=""
QUIET=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --wing)        WING="${2:-}"; shift 2 ;;
    --drawer)      DRAWER="${2:-}"; shift 2 ;;
    --target)      TARGET="${2:-}"; shift 2 ;;
    --id)          ID="${2:-}"; shift 2 ;;
    --event)       EVENT="${2:-}"; shift 2 ;;
    --canonical)   CANONICAL="${2:-}"; shift 2 ;;
    --historical)  HISTORICAL="${2:-}"; shift 2 ;;
    --people)      PEOPLE="${2:-}"; shift 2 ;;
    --location)    LOCATION="${2:-}"; shift 2 ;;
    --event-tag)   EVENT_TAG="${2:-}"; shift 2 ;;
    --interest)    INTEREST="${2:-}"; shift 2 ;;
    --time)        TIME_OVERRIDE="${2:-}"; shift 2 ;;
    --quiet)       QUIET=1; shift ;;
    -h|--help)     usage ;;
    *)             die "unknown arg: $1" 64 ;;
  esac
done

# --- validate ---
[[ -n "$WING"   ]] || die "--wing is required" 64
[[ -n "$DRAWER" ]] || die "--drawer is required" 64
[[ -n "$TARGET" ]] || die "--target is required" 64

WING=$(slugify "$WING")
DRAWER=$(slugify "$DRAWER")

contains "$EVENT" "${KNOWN_EVENTS[@]}" || die "unknown --event '$EVENT' (allowed: ${KNOWN_EVENTS[*]})" 64
scheme_ok "$TARGET" || die "--target uses unknown URI scheme: $TARGET (allowed: ${KNOWN_SCHEMES[*]})" 64
[[ -z "$CANONICAL"  ]] || scheme_ok "$CANONICAL"  || die "--canonical bad scheme: $CANONICAL" 64
[[ -z "$HISTORICAL" ]] || scheme_ok "$HISTORICAL" || die "--historical bad scheme: $HISTORICAL" 64

if ! contains "$WING" "${KNOWN_WINGS[@]}"; then
  printf 'append-pointer.sh: warning: unknown wing slug "%s" (known: %s)\n' \
    "$WING" "${KNOWN_WINGS[*]}" >&2
fi

NOW_UTC="${TIME_OVERRIDE:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
ROOM_DATE=$(printf '%s' "$NOW_UTC" | cut -c1-10)
ROOM_DATE_VALID=$(printf '%s' "$ROOM_DATE" | grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' || true)
[[ -n "$ROOM_DATE_VALID" ]] || die "computed room date '$ROOM_DATE' is not a valid YYYY-MM-DD" 65

if [[ -z "$ID" ]]; then
  ID_STAMP=$(date -u +%Y%m%dT%H%M%SZ)
  ID="P-${ID_STAMP}-${WING}-${DRAWER}"
  if (( ${#ID} > 80 )); then
    ID="${ID:0:80}"
  fi
fi

# --- ensure target file exists (header is non-fatal if missing) ---
mkdir -p "$(dirname "$POINTER_FILE")"
if [[ ! -f "$POINTER_FILE" ]]; then
  printf '### pointers.aaak created by append-pointer.sh (header missing — see plan)\n\n' >> "$POINTER_FILE"
fi

# --- write record under lock ---
emit_record() {
  # All output goes through one printf-grouped block; redirected by caller.
  printf '§ id %s\n' "$ID"
  printf '§ W-%s/R-%s/D-%s\n' "$WING" "$ROOM_DATE" "$DRAWER"
  printf '@event %s\n' "$EVENT"
  printf '@t %s\n' "$NOW_UTC"
  [[ -n "$PEOPLE"    ]] && printf '@p %s\n' "$PEOPLE"
  [[ -n "$LOCATION"  ]] && printf '@l %s\n' "$LOCATION"
  [[ -n "$EVENT_TAG" ]] && printf '@e %s\n' "$EVENT_TAG"
  [[ -n "$INTEREST"  ]] && printf '@i %s\n' "$INTEREST"
  printf '§ ptr primary %s\n' "$TARGET"
  [[ -n "$CANONICAL"  ]] && printf '§ ptr canonical %s\n' "$CANONICAL"
  [[ -n "$HISTORICAL" ]] && printf '§ ptr historical %s\n' "$HISTORICAL"
  printf '§ end\n\n'
  return 0
}

export -f emit_record
export ID WING DRAWER ROOM_DATE EVENT NOW_UTC PEOPLE LOCATION EVENT_TAG INTEREST TARGET CANONICAL HISTORICAL

with_pai_lock pointers.aaak bash -c "emit_record" >> "$POINTER_FILE" || die "lock or write failed" 75

(( QUIET )) || printf '%s\n' "$ID"
