#!/usr/bin/env bash
# with-pai-lock.sh — sourceable advisory file lock for PAI multi-line writers.
#
# Why this exists:
#   Multiple Copilot CLI sessions can run concurrently. Several PAI tools
#   (append-pointer.sh, append-daily.sh, monthly rollup, etc.) write multi-line
#   records. Without locking, two writers can interleave bytes and corrupt
#   files in ways grep/parsers will misread.
#
# Why python3 fcntl, not flock(1):
#   macOS does not ship GNU `flock`. Homebrew has `util-linux`, but we cannot
#   require it. python3 ships with macOS and supports fcntl.flock advisory
#   locks portably.
#
# Usage:
#   source "$(dirname "$0")/lib/with-pai-lock.sh"   # or absolute path
#   with_pai_lock <lock-name> <command...>
#
#   # Or with a function:
#   write_block() { printf 'foo\n'; printf 'bar\n'; }
#   with_pai_lock pointers.aaak write_block >> "$TARGET"
#
# Lock files live in $PAI_LOCK_DIR (default: ~/.pai/state/locks/).
# Locks are advisory (cooperative). All PAI writers must use this helper.
#
# The locked block:
#   - inherits stdin/stdout/stderr from the caller (use redirects normally),
#   - times out after PAI_LOCK_TIMEOUT seconds (default 10),
#   - returns the locked command's exit code on success,
#   - returns 75 (EX_TEMPFAIL) on lock acquisition timeout.

set -uo pipefail

: "${PAI_LOCK_DIR:=$HOME/.pai/state/locks}"
: "${PAI_LOCK_TIMEOUT:=10}"

with_pai_lock() {
  local lock_name="$1"
  shift
  if [[ -z "${lock_name:-}" || $# -eq 0 ]]; then
    printf 'with_pai_lock: usage: with_pai_lock <name> <cmd...>\n' >&2
    return 64
  fi

  mkdir -p "$PAI_LOCK_DIR"
  # Sanitize lock name: keep alnum, dash, underscore, dot.
  local safe_name
  safe_name=$(printf '%s' "$lock_name" | tr -c 'A-Za-z0-9._-' '_')
  local lock_file="$PAI_LOCK_DIR/$safe_name.lock"

  # Acquire lock via python3 fcntl.flock with timeout, then exec the command
  # while still holding the lock. We hold the lock by keeping fd 9 open in a
  # subshell; release happens automatically when the subshell exits.
  PAI_LOCK_FILE="$lock_file" PAI_LOCK_TIMEOUT="$PAI_LOCK_TIMEOUT" \
    python3 - "$@" <<'PY' || return $?
import fcntl
import os
import subprocess
import sys
import time

lock_file = os.environ['PAI_LOCK_FILE']
timeout = float(os.environ.get('PAI_LOCK_TIMEOUT', '10'))

fd = os.open(lock_file, os.O_CREAT | os.O_RDWR, 0o644)
deadline = time.monotonic() + timeout
acquired = False
while True:
    try:
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        acquired = True
        break
    except BlockingIOError:
        if time.monotonic() >= deadline:
            break
        time.sleep(0.05)

if not acquired:
    sys.stderr.write(
        f'with_pai_lock: timeout after {timeout}s waiting for {lock_file}\n'
    )
    sys.exit(75)

try:
    # sys.argv[1:] is the command to run.
    rc = subprocess.call(sys.argv[1:])
finally:
    fcntl.flock(fd, fcntl.LOCK_UN)
    os.close(fd)

sys.exit(rc)
PY
}

# Convenience: wrap a block of stdin (a string of bash code) under the lock.
# Usage:
#   with_pai_lock_block <name> <<'BLOCK'
#   printf 'line1\n' >> "$TARGET"
#   printf 'line2\n' >> "$TARGET"
#   BLOCK
with_pai_lock_block() {
  local lock_name="$1"
  local script
  script=$(cat)
  with_pai_lock "$lock_name" bash -c "$script"
}
