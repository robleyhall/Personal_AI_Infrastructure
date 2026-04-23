# Plan — Tier 2 Upstream PAI Port

## Problem

Tier 1 landed SYSTEM docs, agents, and a STATE tree skeleton. Tier 2 closes the
remaining parity gaps with upstream v4.0.3 that affect day-to-day runtime:

1. **USER/ subdirs** — upstream ships 11 scaffolded `USER/*/README.md` buckets
   (ACTIONS, BUSINESS, FLOWS, PIPELINES, PROJECTS, SKILLCUSTOMIZATIONS,
   STATUSLINE, TELOS, TERMINAL, WORK, Workflows). Robley has TELOS and
   SKILLCUSTOMIZATIONS (empty) only. Missing nine buckets means there's no
   declared home for project/workflow/terminal customizations.
2. **PRD-per-task formalization** — `MEMORY/WORK/<slug>/` dirs exist, but none
   carry the PRDFORMAT v2.0 frontmatter (task/slug/effort/phase/progress/mode
   /started/updated). Algorithm runs currently bypass the spec, which also
   means no phase-state tracking and no sidecar sync hook point.
3. **FAILURES/SYNTHESIS/REFLECTIONS** — `MEMORY/LEARNING/` has FAILURES/ and
   SIGNALS/ but no SYNTHESIS/ or REFLECTIONS/. Upstream's LEARN-phase loop
   writes to both. Without them, rating aggregation and algorithm
   reflections have nowhere to land.

## Approach

Port scaffolding + lightweight tooling. No sidecar/hook changes (that's Tier 3).

- Mechanical port for USER/ subdir READMEs (same banner convention as Tier 1).
- Copilot-native authoring for PRD scaffolding helper (`new-prd.sh`) — upstream
  hook-driven generation doesn't apply here.
- Create SYNTHESIS/REFLECTIONS dirs + README stubs. Hook up
  `capture-work-learning.sh` to also write a REFLECTIONS JSONL line when
  called from Algorithm Phase 7.
- Update `Copilot/PORTING_NOTES.md` and `~/.pai/MEMORY/WORK/active.md` on
  completion.
- Commit atomically per bucket (USER/, PRD tooling, LEARNING/). Fallback tag
  `pre-tier2-port-<UTC>` pushed before first commit.

## Out of scope (stays Tier 3)

- Hook-equivalents via sidecar (SecurityValidator, PRDSync, RatingCapture auto-fire)
- tmux statusline overlay, tab titles
- Phantom-PAI-root cleanup (queued separately in active.md)

## Todos

Tracked in SQL. Dependencies: USER/ port → PRD tooling → LEARNING/ scaffold →
porting notes + active.md update → commit/push.

## Notes

- USER/TELOS/ and USER/SKILLCUSTOMIZATIONS/ already exist — don't clobber.
  TELOS has Robley's real content; only add the upstream README if missing.
- `MEMORY/LEARNING/FAILURES/` already exists — leave alone, only add
  SYNTHESIS/ and REFLECTIONS/ alongside it.
- `new-prd.sh` writes to `~/.pai/MEMORY/WORK/<slug>/PRD.md` with upstream
  frontmatter. Mirrors the naming convention already in use
  (`YYYYMMDDTHHMMSSZ_slug`), but adds the frontmatter block.
- Rsync to `~/.pai/` after commits (same pattern as Tier 1).
- Fallback tag + atomic commits per bucket for clean rollback.
