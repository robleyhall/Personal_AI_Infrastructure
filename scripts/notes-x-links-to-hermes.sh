#!/usr/bin/env bash
# notes-x-links-to-hermes.sh
#
# Harvests Twitter/X URLs from Mac Notes and drops a single Hermes inbox job
# containing all URLs. Hermes handles content fetching, PKM note creation,
# and git push. Processed notes are moved to "Processed X Links" folder.
#
# Usage: ./notes-x-links-to-hermes.sh [--dry-run]

set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

INBOX="/Users/robley/Documents/Hermes Exchange/inbox"
PROCESSED_FOLDER="Processed X Links"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="$HOME/.pai/logs"
LOG="$LOG_DIR/notes-x-links-${TIMESTAMP}.log"
mkdir -p "$LOG_DIR"

log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG"; }

if [[ ! -d "$INBOX" ]]; then
  echo "ERROR: Hermes Exchange inbox not found at $INBOX" >&2
  exit 1
fi

log "Starting Notes X-link scan"
$DRY_RUN && log "DRY RUN — no changes will be made"

# --- Step 1: Dump all note bodies in one AppleScript pass (no shell calls per note) ---
# Output format: one record per line: NOTE_ID<TAB>TITLE<TAB>BODY_ONELINE
log "Querying Mac Notes..."

RAW_DUMP=$(osascript <<'APPLESCRIPT'
tell application "Notes"
    set output to {}
    repeat with n in every note
        set nb to body of n
        if nb contains "x.com/" or nb contains "twitter.com/" then
            set end of output to (id of n) & ASCII character 9 & (name of n) & ASCII character 9 & nb
        end if
    end repeat
    return output
end tell
APPLESCRIPT
)

if [[ -z "$RAW_DUMP" ]]; then
  log "No notes with X/Twitter links found. Exiting."
  exit 0
fi

NOTE_COUNT=$(echo "$RAW_DUMP" | grep -c "x.com/\|twitter.com/" || true)
log "Found notes with X/Twitter content, extracting URLs..."

# --- Step 2: Parse URLs and note IDs in Python ---
# Write Python script to temp file to avoid pipe+heredoc conflict
PYTHON_SCRIPT=$(mktemp)
cat > "$PYTHON_SCRIPT" <<'PY'
import sys, re

ts, log_dir, dry_run_str = sys.argv[1:]

# Matches URLs in unquoted href= and bare text; stops at whitespace, quotes, < > & ,
X_URL_RE = re.compile(r'https?://(?:www\.)?(?:twitter\.com|x\.com)/[^\s"\'<>&,\)]+', re.IGNORECASE)

raw = sys.stdin.read().strip()
print(f"[Python] Raw input length: {len(raw)} chars", file=sys.stderr, flush=True)

# AppleScript returns a list as records joined by "\n, " (newline-comma-space)
# Each record: NOTE_ID<TAB>TITLE<TAB>HTML_BODY
records_raw = re.split(r'\n,\s*', raw)
print(f"[Python] Parsed {len(records_raw)} note record(s)", file=sys.stderr, flush=True)

all_urls = []
note_ids = []

for idx, rec in enumerate(records_raw, 1):
    rec = rec.strip()
    if not rec:
        continue
    parts = rec.split('\t', 2)
    if len(parts) < 3:
        print(f"[Python] Record {idx}: skipped (invalid format)", file=sys.stderr, flush=True)
        continue
    note_id, title, body = parts[0].strip(), parts[1].strip(), parts[2]
    urls = list(dict.fromkeys(X_URL_RE.findall(body)))
    label = title if (title and title != "New Note") else f"untitled ({note_id[-8:]})"
    if urls:
        print(f"[Python] Record {idx}/{len(records_raw)}: '{label}' → {len(urls)} URL(s)", file=sys.stderr, flush=True)
        all_urls.extend(urls)
        note_ids.append(note_id)
    else:
        print(f"[Python] Record {idx}/{len(records_raw)}: '{label}' → 0 URLs (skipped)", file=sys.stderr, flush=True)

# Deduplicate preserving order
seen = set()
unique_urls = [u for u in all_urls if not (u in seen or seen.add(u))]

print(f"[Python] Done: {len(note_ids)} note(s) with {len(unique_urls)} unique URL(s)", file=sys.stderr, flush=True)
print("URLS:" + '\n'.join(unique_urls))
print("NOTE_IDS:" + '\n'.join(note_ids))
PY

PARSE_OUTPUT=$(echo "$RAW_DUMP" | python3 "$PYTHON_SCRIPT" "$TIMESTAMP" "$LOG_DIR" "$DRY_RUN" 2>&1)
rm -f "$PYTHON_SCRIPT"

# PARSE_OUTPUT contains both stderr (progress logs) and stdout (URLS:/NOTE_IDS:)
# Separate them for processing
PARSE_STDOUT=$(echo "$PARSE_OUTPUT" | grep -v "^\[Python\]" || true)
PARSE_STDERR=$(echo "$PARSE_OUTPUT" | grep "^\[Python\]" || true)

URLS_SECTION=$(echo "$PARSE_STDOUT" | awk '/^URLS:/{found=1; sub(/^URLS:/,""); print; next} found && /^NOTE_IDS:/{exit} found{print}')
NOTE_IDS_SECTION=$(echo "$PARSE_STDOUT" | awk '/^NOTE_IDS:/{found=1; sub(/^NOTE_IDS:/,""); print; next} found{print}')

# Log stderr lines from Python (progress and debug info)
echo "$PARSE_STDERR" | tee -a "$LOG"

URL_COUNT=$(echo "$URLS_SECTION" | grep -c "http" || true)
log "$URL_COUNT unique X/Twitter URL(s) found"

if [[ "$URL_COUNT" -eq 0 ]]; then
  log "No URLs extracted. Exiting."
  exit 0
fi

if $DRY_RUN; then
  log "[dry-run] would create Hermes inbox job with $URL_COUNT URL(s)"
  log "[dry-run] URLs:"
  echo "$URLS_SECTION" | tee -a "$LOG"
  exit 0
fi

# --- Step 3: Create single Hermes inbox job with all URLs ---
JOB_SLUG="x-links-from-notes_${TIMESTAMP}"
JOB_DIR="$INBOX/$JOB_SLUG"
mkdir -p "$JOB_DIR"

# Write URL list file
echo "$URLS_SECTION" > "$JOB_DIR/urls.txt"

# Write prompt for Hermes worker
cat > "$JOB_DIR/prompt.md" << PROMPT
# Process X/Twitter posts captured from Mac Notes

Captured at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
URL count: $URL_COUNT

## Task

For each URL in urls.txt:

1. Use the youtube-content skill or save_x_content.sh to fetch the post content.
   Prefer the built-in skill if available (check skills_list()).
2. Create a well-structured PKM note under /workspace/projects/pkm/00_Inbox/
   with this shape:
   - Title (from post or inferred)
   - Source URL
   - Author/handle
   - Captured timestamp
   - Topic tags
   - Summary
   - Key ideas
   - Source text
3. After all notes are created:
   git -C /workspace/projects/pkm add -A
   git -C /workspace/projects/pkm commit -m "Add X posts from Notes capture $(date +%Y-%m-%d)"
   git -C /workspace/projects/pkm push origin main
4. Write a RESULT.md in /workspace/outbox/dashboard/${JOB_SLUG}/ listing
   each URL and the PKM note path it was saved to.

## URLs
$(cat "$JOB_DIR/urls.txt")
PROMPT

log "Hermes inbox job created: $JOB_SLUG"
log "  $JOB_DIR"

# --- Step 4: Move processed notes to "Processed X Links" folder ---
if [[ -n "$NOTE_IDS_SECTION" ]]; then
  log "Moving processed notes to '$PROCESSED_FOLDER'..."
  while IFS= read -r note_id; do
    [[ -z "$note_id" ]] && continue
    osascript <<APPLESCRIPT
tell application "Notes"
    set targetFolder to missing value
    repeat with f in every folder
        if name of f is "$PROCESSED_FOLDER" then
            set targetFolder to f
            exit repeat
        end if
    end repeat
    if targetFolder is missing value then
        set targetFolder to make new folder with properties {name:"$PROCESSED_FOLDER"}
    end if
    set theNote to note id "$note_id"
    move theNote to targetFolder
end tell
APPLESCRIPT
    log "  Moved: $note_id"
  done <<< "$NOTE_IDS_SECTION"
fi

log "Done. Log: $LOG"
