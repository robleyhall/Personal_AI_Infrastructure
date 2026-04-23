# STATE — Runtime State Tree

> Per-task, per-session, and queue state for the PAI Copilot port. Not synced to git except for this README and the directory skeleton.

## Layout

```
state/
├── README.md          # This file
├── sessions.log       # Append-only session log (sidecar-written)
├── sessions/          # Per-session state (future — currently flat sessions.log)
├── tasks/             # Per-task working state
│   └── <task-slug>/
│       ├── PRD.md           # Prompt + Ideal State Criteria (mirror of ~/.pai/MEMORY/WORK/<ts>_<slug>/PRD.md for active tasks)
│       ├── status.json      # {status, started_at, updated_at, isc_passing, isc_total}
│       └── notes.md         # Scratchpad for the task
└── queue/             # Queued but not started work
    └── <task-slug>.md
```

## Relationship to MEMORY/WORK/

- `~/.pai/MEMORY/WORK/active.md` — single-block current-work tracker (hand-curated). Source of truth for "what am I doing now."
- `~/.pai/MEMORY/WORK/<timestamp>_<slug>/PRD.md` — per-task PRD directory. Created at ALGORITHM mode Phase 3 (PLAN).
- `~/.pai/state/tasks/<slug>/` — runtime mirror for active tasks. Lets scripts query status without parsing active.md.

## Write rules

- **Append-only:** `sessions.log`, `queue/*.md`
- **Overwrite:** `tasks/<slug>/status.json` (atomic write)
- **Hand-edit:** `tasks/<slug>/notes.md`
- **Do NOT edit:** PRD.md once Phase 3 commits it — mutate via ISC checkbox updates only

## Divergence from upstream

Upstream PAI v4.0.3 has a more developed STATE tree including per-agent state, hook lock-files, and integrity check caches. The Copilot port only needs:

- Task state (for the queue discipline already documented in `active.md`)
- Session log (for the engagement tracker)
- Queue directory (for "Queued — …" items currently listed in `active.md`)

Hook-related state (`LastResponseCache`, `PRDSync` locks, `KittyEnvPersist`, integrity caches) is **not needed** — those upstream hooks don't run in the Copilot port.
