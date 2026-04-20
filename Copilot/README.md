# Copilot (Phase 0 Spike) — Overview

Minimal end-to-end port of PAI onto GitHub Copilot CLI. The goal is to prove
the shape of the migration, not to ship a full product. See
`tasks/todo.md` for the full plan and `tasks/lessons.md` for what we learned
building this.

## Layout

```
Copilot/
├── install.sh              # Installer: copies tree to ~/.pai/, adds shell alias
├── README.md               # (this file)
├── VoiceServer/            # Local TTS via macOS `say` (replaces ElevenLabs)
│   ├── server.ts
│   ├── start.sh
│   └── README.md
├── sidecar/
│   └── pai-copilot         # Shell wrapper around `copilot` (replaces hooks)
└── skills/
    └── Research/           # Ported Research skill (only skill in the spike)
        └── PORTING_NOTES.md
```

## What's in the spike

| Piece                      | Status | Notes                                      |
|----------------------------|--------|--------------------------------------------|
| Install path `~/.pai/`     | ✅     | Decided; mechanical `sed` applied          |
| Copilot-only fork          | ✅     | No dual support; Claude Code refs removed  |
| `copilot-instructions.md`  | ✅     | LoadContext + 3 modes + voice + ratings    |
| Sidecar wrapper            | ✅     | ~80 lines bash, no PTY                     |
| Voice server (`say`)       | ✅     | Drop-in `POST /notify`, no API key         |
| Research skill             | ✅     | Mechanical port; see `PORTING_NOTES.md`    |
| Research memory promotion  | ✅     | Saves artifacts + compact `what matters` digest |
| `gh models` for inference  | ⏭️     | Deferred until we have a real rating-volume signal |
| Other 11 skill packs       | ⏭️     | Out of scope for spike                     |
| `Algorithm v3.7.0` port    | ⏭️     | Referenced from instructions, not yet ported |
| GitHub Actions             | ⏭️     | Deferred                                   |
| PTY wrapper                | ⏭️     | Sidecar first; revisit only if fidelity gaps hurt |

## Install and run

```bash
./Copilot/install.sh
source ~/.zshrc       # (or restart shell)
pai                    # launches copilot via the sidecar
```

## Verify

```bash
# 1. Voice server
curl -sS -X POST http://localhost:8888/notify \
  -H 'content-type: application/json' \
  -d '{"message":"PAI spike is alive"}'

# 2. Sidecar health
~/.pai/sidecar/pai-copilot --version    # should pass through to copilot --version

# 3. Instructions loaded
# In a `pai` session, first response should start with a mode header
# (MINIMAL / NATIVE / ALGORITHM) per copilot-instructions.md §2.

# 4. Research memory promotion
cat <<'EOF' | ~/.pai/tools/save-research-memory.sh --topic "test topic" --mode "quick"
- One durable insight
- One useful follow-up
EOF
```

## Known friction

See `tasks/lessons.md` and `skills/Research/PORTING_NOTES.md`.
