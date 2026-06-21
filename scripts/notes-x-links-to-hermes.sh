#!/usr/bin/env bash
# notes-x-links-to-hermes.sh
#
# Scans Mac Notes for notes containing Twitter/X links, runs each URL through
# save_x_content.sh, drops a Hermes inbox job for further processing, and moves
# the originating note into a "Processed X Links" folder for bulk cleanup.
#
# Usage: ./notes-x-links-to-hermes.sh [--dry-run]
#
# Requirements:
#   - macOS Notes.app (AppleScript access)
#   - /Users/robley/projects/youtube-transcript-archiver/save_x_content.sh
#   - Hermes Exchange inbox mounted at /Users/robley/Documents/Hermes Exchange/inbox/

set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

SAVE_X=/Users/robley/projects/youtube-transcript-archiver/save_x_content.sh
INBOX="/Users/robley/Documents/Hermes Exchange/inbox"
PROCESSED_FOLDER="Processed X Links"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="$HOME/.pai/logs"
LOG="$LOG_DIR/notes-x-links-${TIMESTAMP}.log"
mkdir -p "$LOG_DIR"

log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG"; }

if [[ ! -x "$SAVE_X" ]]; then
  echo "ERROR: save_x_content.sh not found or not executable at $SAVE_X" >&2
  exit 1
fi

if [[ ! -d "$INBOX" ]]; then
  echo "ERROR: Hermes Exchange inbox not found at $INBOX" >&2
  exit 1
fi

log "Starting Notes X-link scan"
$DRY_RUN && log "DRY RUN — no changes will be made"

# --- Step 1: Export all note titles+bodies via AppleScript ---
log "Querying Mac Notes (this may take a moment)..."

NOTES_JSON=$(osascript <<'APPLESCRIPT'
set output to "["
set firstItem to true
tell application "Notes"
    repeat with n in every note
        set noteTitle to name of n
        set noteBody to plaintext of n
        set noteID to id of n
        if noteBody contains "twitter.com/" or noteBody contains "x.com/" then
            if not firstItem then
                set output to output & ","
            end if
            set safeTitle to do shell script "echo " & quoted form of noteTitle & " | sed 's/\"/\\\\\"/g'"
            set safeBody to do shell script "echo " & quoted form of noteBody & " | sed 's/\"/\\\\\"/g'"
            set safeID to do shell script "echo " & quoted form of noteID & " | sed 's/\"/\\\\\"/g'"
            set output to output & "{\"id\":\"" & safeID & "\",\"title\":\"" & safeTitle & "\",\"body\":\"" & safeBody & "\"}"
            set firstItem to false
        end if
    end repeat
end tell
return output & "]"
APPLESCRIPT
)

NOTE_COUNT=$(echo "$NOTES_JSON" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d))" 2>/dev/null || echo "0")
log "Found $NOTE_COUNT note(s) containing Twitter/X links"

if [[ "$NOTE_COUNT" -eq 0 ]]; then
  log "Nothing to process. Exiting."
  exit 0
fi

# --- Step 2: Extract URLs, process each, drop Hermes inbox job ---
MANIFEST=$(LOG_DIR="$LOG_DIR" python3 - "$NOTES_JSON" "$INBOX" "$SAVE_X" "$DRY_RUN" "$TIMESTAMP" <<'PY'
import json, re, sys, os, subprocess, shutil
from pathlib import Path
from datetime import datetime, timezone

notes_json, inbox_root, save_x, dry_run_str, ts = sys.argv[1:]
dry_run = dry_run_str == "True"
notes = json.loads(notes_json)

X_URL_RE = re.compile(r'https?://(?:www\.)?(?:twitter\.com|x\.com)/\S+', re.IGNORECASE)

def log(msg):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}", flush=True)

processed_note_ids = []

for note in notes:
    title = note["title"]
    body = note["body"]
    note_id = note["id"]
    urls = list(dict.fromkeys(X_URL_RE.findall(body)))

    if not urls:
        continue

    log(f"Note: '{title}' — {len(urls)} URL(s)")

    for url in urls:
        # Strip trailing punctuation swept up by the regex
        url = re.sub(r'[)\].,;:\'\"]+$', '', url)
        log(f"  URL: {url}")

        if dry_run:
            log("  [dry-run] would run save_x_content.sh and create inbox job")
            continue

        # Run save_x_content.sh to capture content locally
        save_result = subprocess.run(
            [save_x, url, "extract_wisdom"],
            capture_output=True, text=True
        )
        if save_result.returncode != 0:
            log(f"  WARNING: save_x_content.sh exited {save_result.returncode}: {save_result.stderr[:200]}")

        # Extract artifact paths from save_x_content.sh stdout
        content_file = None
        pattern_file = None
        for line in save_result.stdout.splitlines():
            if line.startswith("Content:"):
                content_file = line.split(":", 1)[1].strip()
            elif line.startswith("Pattern:"):
                pattern_file = line.split(":", 1)[1].strip()

        # Create Hermes inbox job directory
        safe_title = re.sub(r'[^\w\-]', '_', title)[:40]
        job_slug = f"x-link_{ts}_{safe_title}"
        job_dir = Path(inbox_root) / job_slug
        job_dir.mkdir(parents=True, exist_ok=True)

        # Write prompt for Hermes worker
        (job_dir / "prompt.md").write_text(f"""# Process X/Twitter post from Mac Notes

Source note: {title}
URL: {url}
Captured at: {datetime.now(timezone.utc).isoformat()}

## Task

1. Review the captured content files below (if present).
2. Create a well-structured PKM note under /workspace/projects/pkm/00_Inbox/
   following the PKM note shape: title, source URL, author/handle, timestamps,
   topic tags, summary, key ideas, source text.
3. Commit the note to the PKM working clone and push to origin.
4. Place the final PKM note path in RESULT.md in /workspace/outbox/dashboard/{job_slug}/.

## Captured artifacts
- Content: {content_file or "not captured — fetch directly from URL"}
- Pattern (extract_wisdom): {pattern_file or "not captured"}
""")

        # Copy artifacts into job dir if they exist
        for artifact in [content_file, pattern_file]:
            if artifact and os.path.isfile(artifact):
                shutil.copy(artifact, job_dir / Path(artifact).name)

        log(f"  Inbox job created: {job_dir.name}")

    processed_note_ids.append(note_id)

# Write manifest of processed note IDs for the AppleScript move step
log_dir = os.environ.get("LOG_DIR", os.path.expanduser("~/.pai/logs"))
manifest = Path(log_dir) / f"processed-note-ids-{ts}.txt"
manifest.write_text("\n".join(processed_note_ids))
print(f"MANIFEST:{manifest}")
PY
)

# Extract manifest path from python output
MANIFEST_PATH=$(echo "$MANIFEST" | grep "^MANIFEST:" | tail -1 | sed 's/^MANIFEST://')
# Also log the python output
echo "$MANIFEST" | grep -v "^MANIFEST:" | tee -a "$LOG"

# --- Step 3: Move processed notes into "Processed X Links" folder ---
if [[ -z "$MANIFEST_PATH" || ! -f "$MANIFEST_PATH" ]]; then
  log "No manifest found — skipping Notes move step"
  exit 0
fi

if $DRY_RUN; then
  log "[dry-run] would move $(wc -l < "$MANIFEST_PATH") note(s) to '$PROCESSED_FOLDER'"
  exit 0
fi

log "Moving processed notes to '$PROCESSED_FOLDER' folder in Notes..."
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
  log "  Moved note: $note_id"
done < "$MANIFEST_PATH"

log "Done. Log: $LOG"
