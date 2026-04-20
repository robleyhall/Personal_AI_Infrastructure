# PAI Voice Server (spike edition)

Minimal local TTS server for the Copilot CLI port of PAI. Uses macOS built-in
`say` — no API key, no network, no cost.

## Run

```bash
bun server.ts
# or, idempotent background start:
./start.sh
```

## Use

```bash
curl -s -X POST http://localhost:8888/notify \
  -H 'content-type: application/json' \
  -d '{"message": "Entering the observe phase"}'
```

## Config

| Env var       | Default      | Notes                                  |
|---------------|--------------|----------------------------------------|
| `PORT`        | `8888`       | Same default as the ElevenLabs server  |
| `PAI_VOICE`   | `Samantha`   | Any macOS voice (`say -v '?'` to list) |
| `PAI_RATE`    | `190`        | Words per minute (100–400)             |

## Why not the ElevenLabs server?

For the spike we're optimising for "works offline, zero setup." If you decide
later that voice quality matters, swap the `spawn('/usr/bin/say', …)` call for
an ElevenLabs fetch and re-introduce the API key requirement. The HTTP
interface is intentionally the same so callers don't need to change.
