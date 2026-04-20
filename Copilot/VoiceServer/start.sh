#!/usr/bin/env bash
# Start the PAI voice server in the background.
# Idempotent: if a server is already listening on the port, does nothing.
set -euo pipefail

PORT="${PORT:-8888}"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${PAI_VOICE_LOG:-$HOME/.pai/logs/voice-server.log}"

mkdir -p "$(dirname "$LOG_FILE")"

if curl -sf "http://localhost:${PORT}/health" >/dev/null 2>&1; then
  echo "voice-server: already running on :${PORT}"
  exit 0
fi

if ! command -v bun >/dev/null 2>&1; then
  echo "voice-server: bun not found in PATH" >&2
  exit 1
fi

nohup bun "${DIR}/server.ts" >>"$LOG_FILE" 2>&1 &
disown || true

for _ in 1 2 3 4 5 6 7 8 9 10; do
  sleep 0.2
  if curl -sf "http://localhost:${PORT}/health" >/dev/null 2>&1; then
    echo "voice-server: started on :${PORT}"
    exit 0
  fi
done

echo "voice-server: failed to start (see $LOG_FILE)" >&2
exit 1
