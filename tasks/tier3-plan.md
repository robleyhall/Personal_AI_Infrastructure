# Plan — Tier 3 Upstream PAI Port

## Problem

Tier 1 landed SYSTEM docs + agents. Tier 2 landed USER/ scaffolds, PRD
tooling, and SYNTHESIS/REFLECTIONS buckets. Tier 3 closes the remaining
gap with upstream v4.0.3 **and makes `Copilot/PORTING_NOTES.md` a
self-contained porting guide** — every upstream component mapped to
ported / skipped / deferred with path + reason.

Three buckets of remaining work:

1. **Runtime behaviors** that don't require a per-tool-call hook API:
   - Periodic `LearningPatternSynthesis` (already scripted — needs sidecar
     POST wiring + schedule doc)
   - Session-end integrity check (stub at minimum)
   - `SecretScan` as a shell-invokable utility
   - PRD-frontmatter backfill for 6 existing `MEMORY/WORK/<slug>/` dirs

2. **Phantom-PAI-root cleanup** — 14 files under `~/.pai/skills/` still
   reference upstream-only paths (`PAI/SKILL.md`, `PAI/Tools/*.ts`,
   `PAI/Prompting.md`) that were deliberately skipped in Tier 1.

3. **PORTING_NOTES completeness** — current notes cover decisions but are
   not a full inventory. Add a complete upstream → Copilot mapping table
   so a future porter can reproduce the work from the notes alone.

## Approach

No new architecture — reuse the sidecar (`Copilot/sidecar/pai-copilot`)
and the instruction file for anything that needs per-prompt or
per-tool-call behavior.

### In scope (this autopilot run)

- **Sidecar POST enhancements:** weekly synthesis trigger +
  doc-integrity smoke check. Non-fatal; logs only.
- **SecretScan port:** shell utility wrapping `grep` + common secret
  patterns, usable ad-hoc or via `git pre-commit`.
- **PRD backfill:** `backfill-prd-frontmatter.sh` that adds PRDFORMAT v2.0
  frontmatter to existing `MEMORY/WORK/<slug>/*.md` when missing.
- **Phantom-root cleanup:** rewrite the 14 stale refs. `PAI/SKILL.md` →
  `~/.copilot/copilot-instructions.md`; `PAI/Tools/*.ts` bun refs →
  banner explaining "requires upstream bun runtime, not ported — use
  skill-local equivalents or omit"; `PAI/Prompting.md` →
  `Copilot/skills/Prompting/`.
- **PORTING_NOTES overhaul:** append a full upstream-inventory table
  covering every `.claude/` subtree, every `PAI/Tools/*.ts`, all 6
  upstream hook groups, `statusline-command.sh`, and `settings.json`.
  Each row: component, upstream path, Copilot status (✅ ported /
  ⚠️ partial / ⏭ skipped / 🕒 deferred), Copilot path, reason.

### Out of scope — deferred Tier 3b (explicit, documented)

- **Per-tool-call hooks.** Copilot CLI has no `PreToolUse`/`PostToolUse`
  hook API. Upstream's `SecurityValidator`, `PRDSync`,
  `AgentExecutionGuard`, `SkillGuard`, `SetQuestionTab`,
  `QuestionAnswered` fundamentally cannot port. Approximation via
  `copilot-instructions.md § Security` rules only.
- **ACTIONS/PIPELINES runtime** (bun TypeScript, `A_EXAMPLE_*`,
  `P_EXAMPLE_*`, `lib/runner.ts`, `pipeline-runner.ts`). Major new
  feature; defer until there's a concrete use case.
- **Statusline tmux overlay.** Replaces upstream
  `statusline-command.sh` (1390 lines, Claude Code API). Defer.
- **`Inference.ts` unified wrapper.** Copilot CLI already exposes its
  own model system; upstream's multi-provider wrapper is redundant.
- **Banner/neofetch TS tools** (cosmetic).
- **`PAI/Tools/` bun ports** beyond `SecretScan` + `synthesize-learnings`
  (already done). Individual ports only when triggered by need.

## Todos

Tracked in SQL. Order: sidecar → SecretScan → PRD backfill → phantom
cleanup → PORTING_NOTES overhaul → commit + push.

## Notes

- `synthesize-learnings.sh` + `.ts` already exist in
  `Copilot/tools/` — Tier 3 just wires them into the sidecar POST on a
  weekly cadence (stamp file gate, not cron).
- Integrity check: lightweight — detect phantom path refs that re-appear
  in new skill docs. Full upstream `IntegrityMaintenance.ts` logic is
  much larger; current scope is a regression guard.
- Backfill script must be idempotent — skip files that already have
  YAML frontmatter with `task:` key.
- Phantom cleanup uses sed substitution against a single canonical
  replacement map; commit shows the map for auditability.
- PORTING_NOTES table is the deliverable that makes this plan re-runnable
  by a future AI or human with the same upstream release pinned.

## Safety

- Fallback tag `pre-tier3-port-<UTC>` pushed before first commit.
- Atomic commits per bucket (sidecar / SecretScan / backfill / phantom
  cleanup / docs).
- Rsync into `~/.pai/` after commits land.
