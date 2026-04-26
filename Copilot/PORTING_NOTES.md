# Platform-Level Porting Notes

> Tracks divergences from upstream `danielmiessler/Personal_AI_Infrastructure` at the **platform/SYSTEM** level (docs, agents, state, sidecar, voice). Skill-level ports are documented in [`skills/PORTING_NOTES.md`](skills/PORTING_NOTES.md).

## Upstream baseline
- Source repo: https://github.com/danielmiessler/Personal_AI_Infrastructure
- Pinned release: **v4.0.3** (`Releases/v4.0.3/.claude/`)
- Local branch: `feat/copilot-migration`

## Automated substitutions (applied in bulk ports)
| From (Claude Code) | To (Copilot CLI) |
|---|---|
| `~/.claude/PAI/`, `.claude/PAI/` | `~/.pai/PAI/`, `.pai/PAI/` |
| `~/.claude/agents/`, `.claude/agents/` | `~/.pai/agents/`, `.pai/agents/` |
| `~/.claude/` (generic runtime) | `~/.pai/` |
| Tool names (`Read`/`Write`/`Edit`/`MultiEdit`/`WebFetch`/`WebSearch`/`Bash`/`Glob`/`Grep`/`Task`/`TodoWrite`) | `view`/`create`/`edit`/`edit (repeated)`/`web_fetch`/`web_search`/`bash`/`glob`/`grep`/`task`/`sql` |
| `subagent_type: "<Claude custom type>"` | `agent_type: "general-purpose"` (or `"explore"`) |
| `run_in_background: true` | `mode: "background"` |

Skill-level ports also apply these; see `skills/PORTING_NOTES.md`.

## What is deliberately **not** ported
- **Hooks** (`.claude/hooks/*.hook.ts`, 21 handlers): Copilot CLI has no hook API. Manual script equivalents exist for a subset (`capture-rating.sh`, `capture-work-learning.sh`, `save-research-memory.sh`); sidecar-based equivalents for security validation, PRD sync, tab titles are **Tier 3 backlog**.
- **`statusline-command.sh`** (70KB): Claude Code statusline API only. Tmux-overlay replacement is Tier 3.
- **`settings.json`** hook registrations, permissions, MCP config: Claude-Code-specific format.
- **`PAI-Install/`** and **`lib/migration/`** installer scripts: Copilot port uses `Copilot/install.sh` instead.
- **`.claude/CLAUDE.md` + template**: replaced by `.github/copilot-instructions.md` + `~/.copilot/copilot-instructions.md`.

---

## Tier 1 port — 2026-04-23

**Fallback tag:** `pre-tier1-port-20260423T0127Z`
**Commits:** `134c93c`, `339c29e`, `46178ad` on `feat/copilot-migration`
**Source:** `/tmp/pai-upstream` shallow sparse clone (Releases/v4.0.3/.claude/)

### Copilot/PAI/ — SYSTEM-tier doc port
19 top-level docs + 3 subdir READMEs + 2 Algorithm version breakdowns ported verbatim, with:
- Port banner at top of each file citing upstream v4.0.3 and path rewrites.
- `sed`-based substitutions for `~/.claude/PAI/` → `~/.pai/PAI/` and `~/.claude/agents/` → `~/.pai/agents/`.
- Hook references (`~/.claude/hooks/`) **left intact** — banner warns they're not ported.
- Content otherwise preserved verbatim.

**Files:** ACTIONS.md, AISTEERINGRULES.md, CLI.md, CLIFIRSTARCHITECTURE.md, CONTEXT_ROUTING.md, DOCUMENTATIONINDEX.md, FLOWS.md, MEMORYSYSTEM.md, PAIAGENTSYSTEM.md, PAISYSTEMARCHITECTURE.md, PIPELINES.md, PRDFORMAT.md, SKILLSYSTEM.md, SYSTEM_USER_EXTENDABILITY.md, THEDELEGATIONSYSTEM.md, THEFABRICSYSTEM.md, THEHOOKSYSTEM.md, THENOTIFICATIONSYSTEM.md, TOOLS.md; plus `ACTIONS/README.md`, `FLOWS/README.md`, `PIPELINES/README.md`, `Algorithm/{v3.5.0,v3.7.0}.md`.

**Intentionally NOT ported:**
- `PAI/README.md` — Copilot port keeps its own `Copilot/README.md`
- `PAI/SKILL.md` — the upstream main PAI skill file is redundant with the Copilot `copilot-instructions.md` framework
- `PAI/Tools/` — Claude-Code-specific bun tools (BuildCLAUDE.ts, Inference.ts, etc.); some subsumed by `Copilot/tools/`, others Tier 3 backlog
- `PAI/USER/` — user-tier overrides handled separately under `~/.pai/USER/`

**Design choice:** ported docs live under `Copilot/PAI/` subnamespace (NOT flat at `Copilot/` root) to distinguish upstream-parity content from Copilot-specific docs (`Algorithm.md`, `ContextRouting.md`, `README.md`, `USER_GUIDE.md` remain at repo root). This keeps future upstream diffs clean.

### Copilot/agents/ — Agent profile catalog
14 profiles ported verbatim with the same port banner + path rewrites:
Algorithm, Architect, Artist, BrowserAgent, ClaudeResearcher, CodexResearcher, Designer, Engineer, GeminiResearcher, GrokResearcher, Pentester, PerplexityResearcher, QATester, UIReviewer.

**Effective capability in Copilot:** profiles are **reference material, not invocable subagents**. Copilot CLI's `task` tool collapses model-specific roles to `agent_type: "general-purpose"`. Profiles describe tone, responsibility, and output format — still useful as prompt scaffolding. See also `skills/Delegation/` Copilot Spike Status banner.

### Copilot/state/ — STATE tree skeleton
New. Provides:
- `README.md` — documents `tasks/`, `queue/`, `sessions/` layout and relationship to `~/.pai/MEMORY/WORK/active.md`.
- Empty `tasks/`, `queue/`, `sessions/` dirs (`.gitkeep` sentinels).

**Divergence from upstream:** Copilot port intentionally omits hook-related state (`LastResponseCache`, `PRDSync` locks, `KittyEnvPersist`, integrity caches) — those upstream hooks don't run here.

### PAIUpgrade phantom-ref banner
`Copilot/skills/PAIUpgrade/Workflows/Upgrade.md` now carries a header banner noting that its recommendations reference upstream skill paths (e.g., `skills/_SYSTEM/Workflows/DocumentSession.md`) that **do not exist** in the Copilot port. Partial resolution of the phantom-PAI-root cleanup task; other ~9 skills with similar refs remain queued.

### Runtime sync
All Tier 1 output `rsync`-ed into `~/.pai/` (not via `install.sh` — that would overwrite in-flight state):
- `Copilot/PAI/` → `~/.pai/PAI/`
- `Copilot/agents/` → `~/.pai/agents/`
- `Copilot/state/README.md` → `~/.pai/state/README.md` (existing `sessions.log` preserved)
- `Copilot/skills/PAIUpgrade/` → `~/.pai/skills/PAIUpgrade/`

---

## Tier 2 port — 2026-04-23

**Fallback tag:** `pre-tier2-port-20260423T1101Z`
**Branch:** `feat/copilot-migration`
**Scope:** USER/ scaffolds, PRD-per-task tooling, LEARNING SYNTHESIS/REFLECTIONS buckets.

### Copilot/PAI/USER/ — USER-tier scaffolds
Ported upstream `PAI/USER/` scaffold buckets (README-only) with the standard banner:
- `ACTIONS/`, `BUSINESS/`, `FLOWS/`, `PIPELINES/`, `PROJECTS/`, `STATUSLINE/`, `TERMINAL/`, `WORK/`, `Workflows/`
- Parent `USER/README.md` — Copilot-authored overview mapping the bucket set to Robley's existing `~/.pai/USER/` layout (ABOUTME / DAIDENTITY / AISTEERINGRULES / TELOS / SKILLCUSTOMIZATIONS already populated).

**Intentionally NOT re-ported:** `TELOS/README.md` and `SKILLCUSTOMIZATIONS/README.md` — upstream copies would clobber live user content. Already-present runtime dirs (`~/.pai/USER/TELOS/`, `~/.pai/USER/SKILLCUSTOMIZATIONS/`) left untouched by rsync.

**STATUSLINE caveat:** bucket references Claude Code's statusline API. Banner flags it as non-functional in Copilot CLI. Real equivalent (tmux overlay) remains Tier 3.

### Copilot/tools/new-prd.sh — PRD scaffolder
New tool. Creates `~/.pai/MEMORY/WORK/<UTC>_<slug>/PRD.md` with upstream PRDFORMAT v2.0 frontmatter (task/slug/effort/phase/progress/mode/started/updated) + ISC scaffold.

**Divergence from upstream:** upstream fires `PRDGenerate.hook.ts` on Algorithm start; Copilot CLI has no hook API. Algorithm-mode invokes `new-prd.sh` explicitly at Phase 3 (PLAN). Existing `~/.pai/MEMORY/WORK/<slug>/` dirs from prior sessions do NOT carry PRD frontmatter — a one-time backfill pass is optional Tier 3 work.

### Copilot/tools/capture-work-learning.sh — `--reflection` flag
Extended. New `--reflection` opt-in also appends a JSONL line to `MEMORY/LEARNING/REFLECTIONS/algorithm-reflections.jsonl`. Backward compatible: default behavior unchanged.

JSONL schema: `{ timestamp, slug, category, session, artifact, content }`. Python3 handles JSON encoding to safely marshal arbitrary markdown content (avoids shell-quoting pitfalls).

### MEMORY/LEARNING/SYNTHESIS/ + REFLECTIONS/
New buckets alongside existing `FAILURES/` and `SIGNALS/`. README stubs document:
- **SYNTHESIS/** — weekly/monthly rollups of ratings + learnings. Manual for now; upstream's `LearningPatternSynthesis.ts` aggregation is Tier 3.
- **REFLECTIONS/** — append-only `algorithm-reflections.jsonl` for Phase-7 LEARN captures.

Runtime dirs created under `~/.pai/MEMORY/LEARNING/` (previously missing).

### Runtime sync (Tier 2)
- `Copilot/PAI/USER/` → `~/.pai/PAI/USER/`
- `Copilot/PAI/MEMORY/LEARNING/` → `~/.pai/PAI/MEMORY/LEARNING/`
- `Copilot/tools/new-prd.sh` → `~/.pai/tools/new-prd.sh` (+x)
- `Copilot/tools/capture-work-learning.sh` → `~/.pai/tools/capture-work-learning.sh` (+x)
- `mkdir -p ~/.pai/MEMORY/LEARNING/{SYNTHESIS,REFLECTIONS}` + `touch REFLECTIONS/algorithm-reflections.jsonl`

### Tier 3 backlog (deferred, not blocked by Tier 2)
- Hook-equivalents via sidecar: SecurityValidator, PRDSync (auto-bump `updated:` + `phase:`), RatingCapture auto-fire, `LearningPatternSynthesis` aggregation
- Tmux statusline overlay, tab titles
- Phantom-PAI-root cleanup remaining ~9 files (tracked in `active.md`)
- Optional: backfill PRD frontmatter onto existing `MEMORY/WORK/<slug>/` dirs

---

## Cross-reference
- Skill-level mechanical ports: [`skills/PORTING_NOTES.md`](skills/PORTING_NOTES.md)
- Research skill specifics: [`skills/Research/PORTING_NOTES.md`](skills/Research/PORTING_NOTES.md)
- Remaining divergences / backlog: `~/.pai/MEMORY/WORK/active.md` (Queued sections), Copilot Environment Security & Efficiency Audit Phase 2 scope.

---

## Tier 3 port — 2026-04-23

**Fallback tag:** `pre-tier3-port-20260423T1119Z`
**Branch:** `feat/copilot-migration`
**Scope:** runtime glue (sidecar POST), phantom-PAI-root cleanup,
PRD backfill utility, comprehensive inventory below.
**Superseded in part by Tier 3+ (same session, below):** `bun` was
unexpectedly available; Tier 3's shell-ports of upstream bun tools were
reverted in favor of running the upstream `.ts` directly.

### Copilot/sidecar/pai-copilot — POST-session additions
Added three non-fatal post-session functions:
- `weekly_synthesis()` — ISO-week-gated `bun ~/.pai/PAI/Tools/LearningPatternSynthesis.ts --week`. Stamp file at `~/.pai/state/last-synthesis.stamp`. Output to `~/.pai/logs/synthesis.log`. Replaces upstream `LearningPatternSynthesis.hook.ts` (cron-style, SessionEnd) since Copilot has no hook API.
- `integrity_scan()` — regression guard. Greps `~/.pai/skills/` for phantom `~/.pai/PAI/{SKILL.md,Tools/,Prompting.md}` refs and logs the count to `~/.pai/logs/integrity.log`.
- `prd_sync()` — approximates upstream `PRDSync.hook.ts` (PostToolUse/Write+Edit). At session end, bumps `updated:` frontmatter on every `MEMORY/WORK/**/*.md` touched since session start (tracked via `session-<id>.started` touch file). Only touches PRDFORMAT v2.0 files (has both `task:` and `updated:` in first 12 lines).

### Copilot/tools/backfill-prd-frontmatter.sh — New
Idempotent backfill of PRDFORMAT v2.0 frontmatter onto `MEMORY/WORK/<slug>/*.md` that predate the scaffolder. Skips files already containing `task:` in first 10 lines. Derives `started:` from the slug's `YYYYMMDDTHHMMSSZ` prefix, falls back to file mtime. Sets `phase: complete`, `progress: 1/1`, `backfilled: true`. Dry-run by default; `--apply` to write. **Applied once** against 6 pre-existing WORK dirs.

### Copilot/tools/capture-rating.sh — FailureCapture extension
Low-rating (≤3) path now appends a "Recent Session Context" block with the last ~20 events (`user.message`, `assistant.message`, `tool.execution_start`, `tool.execution_complete`) parsed from the active Copilot session's `~/.copilot/session-state/<uuid>/events.jsonl`. Approximates upstream `FailureCapture.ts` context dump. Events file located by scanning most-recently-modified session dirs; uses Python for JSON parsing.

### Phantom-PAI-root cleanup
14 skill files rewritten:
- `~/.pai/PAI/SKILL.md` → `~/.copilot/copilot-instructions.md`
- `~/.pai/PAI/Prompting.md` → `~/.pai/skills/Prompting/README.md`
- `bun ~/.pai/PAI/Tools/<X>.ts` — originally tagged with a "NOT PORTED" inline banner. **Reverted in Tier 3+ once bun availability was confirmed.**

Intentionally **not** rewritten: `skills/PORTING_NOTES.md` line documenting phantom-ref is the doc.

---

## Tier 3+ expansion — 2026-04-23 (same session)

**Discovery:** `bun 1.3.12` was already installed system-wide. Earlier
tiers had assumed it was not available and either deferred bun tools or
reimplemented them in shell. All such ports are now reverted to running
the upstream `.ts` directly.

### What's newly available
- **`Copilot/PAI/Tools/`** — 37 TypeScript tools + 1 Python (`extract-transcript.py`) copied from upstream v4.0.3 `PAI/Tools/`. Paths rewritten `.claude`→`.pai`. Each file prepended with a single-line "Ported from upstream … Run with bun." banner. All 37 pass `bun build --target=bun` (parse check).
- **`Copilot/PAI/ACTIONS/lib/`** — 5 TS files (`runner.ts`, `runner.v2.ts`, `pipeline-runner.ts`, `types.ts`, `types.v2.ts`) ported verbatim. Usage: `bun lib/runner.ts <action.json>`.
- **`Copilot/PAI/ACTIONS/`** example actions, **`Copilot/PAI/PIPELINES/P_EXAMPLE_*.yaml`**.
- **`Copilot/PAI/Tools/pipeline-monitor-ui/`** — React+Vite UI copied as-is.
- **`Copilot/hooks/lib/`** — minimal stubs for `identity.ts`, `learning-utils.ts`, `prd-template.ts`. Upstream v4.0.3 **release tree does not ship** these libs, yet 5 tools (`algorithm.ts`, `pai.ts`, `SessionHarvester.ts`, `TranscriptParser.ts`, `IntegrityMaintenance.ts`) import from `../../hooks/lib/*`. Without stubs the tools fail to resolve at import time. Stubs match the shapes expected at call sites and read from `~/.pai/USER/`.
- **`Copilot/tools/statusline-command.sh`** — upstream's 1390-line statusline script ported with a banner. Copilot CLI has no statusline API; script is usable from tmux `status-right` or manually piping a Claude-Code-shaped session JSON.

### npm dependencies needed
- `Copilot/PAI/Tools/package.json` — `openai`, `yaml` (required by `ExtractTranscript.ts`, `SplitAndTranscribe.ts`, `LoadSkillConfig.ts`, `PipelineOrchestrator.ts`).
- `Copilot/PAI/ACTIONS/package.json` — `glob`, `yaml`, `zod`, `ajv`, `ajv-formats` (required by `runner.v2.ts`, `pipeline-runner.ts`).
- Install: `cd ~/.pai/PAI/Tools && bun install && cd ~/.pai/PAI/ACTIONS && bun install`.
- `node_modules/` and `bun.lock` are gitignored; only `package.json` is committed.

### What was reverted
- **Deleted `Copilot/tools/secret-scan.sh`.** Shell port of upstream `SecretScan.ts`. Direct bun invocation supersedes: `bun ~/.pai/PAI/Tools/SecretScan.ts <path>`.
- **Deleted `Copilot/tools/synthesize-learnings.{sh,ts}`.** Shell wrapper + local `.ts` copy of upstream `LearningPatternSynthesis.ts`. Sidecar `weekly_synthesis()` now calls `bun ~/.pai/PAI/Tools/LearningPatternSynthesis.ts --week`.
- **Deleted `Copilot/tools/new-prd.sh`.** Upstream `algorithm.ts new -t <title>` produces identical PRDFORMAT v2.0 output. Callers: `bun ~/.pai/PAI/Tools/algorithm.ts new -t "..." [-e Extended]`.
- **Reverted phantom-cleanup inline banners** from 4 skill files (PAIUpgrade, Media/Art Essay/Visualize/Mermaid). The `bun ~/.pai/PAI/Tools/<X>.ts` lines are now correct command invocations.

### What's kept as Copilot-native (not reverted)
- `capture-rating.sh` / `capture-work-learning.sh` / `save-research-memory.sh` — AI-invoked; upstream equivalents are **hook-bound** (`RatingCapture.hook.ts`, `WorkCompletionLearning.hook.ts`). Since Copilot has no hook API, the AI-invoked pattern is necessary.
- `harvest-session.sh` — upstream `SessionHarvester.ts` reads Claude transcript format; Copilot session store uses a different JSONL schema (`~/.copilot/session-state/<uuid>/events.jsonl`). Distinct implementation required.
- `backfill-prd-frontmatter.sh`, `engagement-distill.sh`, `learning-readback.sh` — no upstream equivalent.

### Functional gaps closed by Tier 3+
| Previously partial / deferred | Now ported |
|---|---|
| ~25 `PAI/Tools/*.ts` deferred | 37 TS + 1 py runnable via bun |
| ACTIONS/PIPELINES runtime deferred | `runner.ts`, `pipeline-runner.ts` compile |
| `statusline-command.sh` deferred | Ported (for tmux/manual use) |
| PRDSync auto-bump missing | `prd_sync()` in sidecar POST |
| FailureCapture context dump missing | `capture-rating.sh` low-rating path enriched |

### Remaining gaps (still unportable or explicitly skipped)
- **Per-tool-call hooks** — Copilot CLI has no hook API. `SecurityValidator`, `AgentExecutionGuard`, `SkillGuard`, `SetQuestionTab`, `QuestionAnswered`, `UpdateTabTitle` cannot fire mid-session; only AI-discipline approximations exist.
- **Banner/PAILogo/neofetch** TS — cosmetic, skipped by design.
- **`BuildCLAUDE.ts`, `RebuildPAI.ts`** — Claude-Code installer-side, skipped.
- **`Inference.ts`** — **Tier 3+ (2026-04-23) update**: shimmed to `gh models run` via the `github/gh-models` gh extension. Auto-detects: if `claude` is on PATH it still uses Claude; otherwise (or when `PAI_INFERENCE_BACKEND=copilot` is set) it calls `gh models run`. Model mapping is overridable via `PAI_INFERENCE_MODEL_{FAST,STANDARD,SMART}` env vars (defaults: `openai/gpt-4o-mini`, `openai/gpt-4o`, `openai/o1`). Smoke-tested: `PAI_INFERENCE_BACKEND=copilot bun Inference.ts --level fast "…" "…"` returns real model output. This unblocks `FailureCapture.ts`, `IntegrityMaintenance.ts`, and the Wisdom*.ts triad at runtime. Requires `gh extension install github/gh-models` once.

---

## Tier 4 — Memory layer additions — 2026-04-26

**All additive.** No upstream v4.0.3 files modified by this tier. Anchor tag
`pre-memory-tier-a-20260426T2332Z` marks the pre-Tier-4 state on
`feat/copilot-migration`.

**Origin:** YouTube transcript comparison of MemPalace / AAAK / open-claw
memory systems (`tasks/memory-incorporation-plan.md`). Tier B (MemPalace
3D installation) is intentionally deferred. Tier C is skipped. This Tier 4
implements only Tier A (markdown-only, additive) of that plan.

**Boundary doc:** `tasks/memory-boundary-decision.md` records the six
PAI ↔ DEVONthink-PKM ↔ MemPalace boundary decisions accepted before
implementation.

### A0 — File locking primitive
- **`Copilot/tools/lib/with-pai-lock.sh`** — sourceable bash helper providing
  `with_pai_lock <name> <cmd...>` and `with_pai_lock_block <name> <<BLOCK`.
  Implementation uses `python3 -c` + `fcntl.flock` (BSD/macOS portable; no
  GNU `flock(1)`). Lock files live under `~/.pai/state/locks/`. Default
  timeout 10s, exit 75 (`EX_TEMPFAIL`) on timeout. **Foundation for every
  multi-line writer added in Tier 4.**

### A2 — AAAK pointer index
- **`~/.pai/MEMORY/INDEX/pointers.aaak`** — single append-only event log
  pointing to canonical artifacts in PAI, DEVONthink, the filesystem, or
  a future MemPalace. Grammar header is in-band at the top of the file
  (`§ id`, `§ W-…/R-…/D-…`, `@event`, `@t`, `@p @l @e @i`,
  `§ ptr primary|canonical|historical`, `§ end`). Stable IDs of the form
  `P-<UTCstamp>-<wing>-<drawer>` survive promotion / supersession events.
- **`Copilot/tools/append-pointer.sh`** — single writer for the index.
  Validates wing slug, URI scheme, and event verb. Outputs the assigned
  pointer ID on stdout (callers chain into `append-daily.sh --ptr "$ID"`).
- **URI schemes (Tier A: syntax-only):** `pai://MEMORY/...`, `file:///abs`,
  `devonthink://<db-uuid>/<record-uuid>`, `mempalace://D-<id>`
  (forward-looking; no resolver yet).
- **Wing slugs:** `pai`, `microsoft`, `homestead`, `pkm`, `relationship`,
  `research`, `health`, `consulting`.
- **Event verbs:** `created | promoted | superseded | reaffirmed`.
- **Wired (best-effort, never fails parent):**
  `save-research-memory.sh`, `capture-work-learning.sh`,
  `harvest-session.sh`. Failures emit warning to stderr only.
- **Readback:** `learning-readback.sh` gained a "Recent Pointers (last 20)"
  section.

### A1 — DAILY machine ledger
- **`~/.pai/MEMORY/DAILY/`** — daily files `YYYY-MM-DD.md`, machine-written
  only. Format: `- HH:MMZ — <event> — source=<name> session=<id> ptr=<P-...> <detail>`.
  **Strictly non-overlapping** with the human PKM journal at
  `~/Library/CloudStorage/OneDrive-GreatBayLabs/PKM/00_Self/journal/`.
- **`Copilot/tools/append-daily.sh`** — single writer. Idempotent on
  `source + event + session + minute-bucket`. Locked.
- **Sidecar wiring (`Copilot/sidecar/pai-copilot`):**
  - `pre_session()` emits a `session-start` DAILY entry.
  - `post_session()` emits a `session-close` DAILY entry, then calls
    new `monthly_rollup()` (non-destructive, sentinel-gated, locked,
    fires once per UTC month).
- **Capture wiring:** research and work-learning captures emit a DAILY
  entry referencing the pointer ID they just minted.
- **Readback:** `learning-readback.sh` gained a "Today" section showing
  the current day's DAILY entries.

### A3 — TELOS temporal tags
- **Convention:** individual TELOS bullets may carry inline
  `_Verified: YYYY-MM-DD_` and/or `_Superseded by: P-<pointer-id>_` italic
  markers. Bullets without markers = **unknown freshness** (no mass
  backfill).
- **`Copilot/tools/touch-telos-fact.sh`** — exact-match-or-fail tool.
  Required args: `--file`, `--heading`, `--field`. Default dry-run; pass
  `--yes` to apply. Refuses if 0 or >1 bullets match. Locked. Idempotent
  on same UTC day.
- **Runtime-only files** (USER/ is intentionally outside the repo):
  - `~/.pai/USER/TELOS/README.md` — convention doc.
  - File-level note added to `~/.pai/USER/TELOS/PROJECTS.md`,
    `~/.pai/USER/TELOS/GOALS.md`, `~/.pai/USER/ABOUTME.md`.
- **Explicitly NOT done (per rubber-duck critique):** no
  `_Verified: <unknown>_` mass backfill; no `AISTEERINGRULES.md` rule
  instructing every session to scan TELOS.

### Tier 4 file inventory (repo)
| Path | Status |
|---|---|
| `Copilot/tools/lib/with-pai-lock.sh` | new |
| `Copilot/tools/append-pointer.sh` | new |
| `Copilot/tools/append-daily.sh` | new |
| `Copilot/tools/touch-telos-fact.sh` | new |
| `Copilot/tools/save-research-memory.sh` | modified (best-effort pointer + DAILY) |
| `Copilot/tools/capture-work-learning.sh` | modified (wing-slug guess + best-effort pointer + DAILY) |
| `Copilot/tools/harvest-session.sh` | modified (per-session lock + session-close DAILY) |
| `Copilot/tools/learning-readback.sh` | modified (Pointers + Today sections) |
| `Copilot/sidecar/pai-copilot` | modified (`pre_session`, `post_session`, new `monthly_rollup()`) |
| `tasks/memory-incorporation-plan.md` | new |
| `tasks/memory-boundary-decision.md` | new |
| `tasks/lessons.md` | Lesson 21 added |

### Runtime-only artifacts (not in repo)
| Path | Note |
|---|---|
| `~/.pai/MEMORY/INDEX/pointers.aaak` | Live append-only index. Grammar header in-band. |
| `~/.pai/MEMORY/DAILY/YYYY-MM-DD.md` | Machine-written; created on demand. |
| `~/.pai/state/locks/*.lock` | Lock files; touch-only. |
| `~/.pai/USER/TELOS/README.md` | Temporal-tag convention. |

### Divergence summary vs upstream PAI v4.0.3
- **Net change:** entirely additive. Zero upstream files modified.
- **Re-merge cost on next upstream bump:** zero for the Tier 4 surface;
  any merge conflicts in the modified files (capture scripts, harvest,
  sidecar) will be normal-sized and limited to the wiring blocks added
  here. Each modification is bounded by clearly-marked Tier 4 hooks.
- **Cumulative divergence (Tier 1+2+3+3+ + Tier 4):** still well within
  the "fork-from-upstream-but-trackable" window. The Tier 3+ revert of
  shell shims to direct bun invocation actually *reduced* divergence;
  Tier 4 keeps that trend by adding tools alongside, not replacing
  upstream surface.

### Smoke-test status (at commit time)
- A0 lock primitive: 5 concurrent multi-line writers → no interleave ✅
- A2 pointer index: 4 tests (create, bad scheme, unknown wing, promote
  with shared ID) ✅
- A1 DAILY ledger: end-to-end via real research capture ✅; idempotent
  re-run ✅
- A3 touch-telos-fact: 6 tests (dry-run+diff, missing heading, missing
  field, apply, same-day idempotent, multi-match refusal) ✅
- Sidecar session-start/close DAILY entries: untested until next real
  session.
- `monthly_rollup()`: untested until first session of next UTC month.

---

## Complete upstream v4.0.3 inventory (canonical reference)

> **Intent:** a future porter reading only this table should be able to
> reproduce the current port. Columns: upstream path, Copilot status,
> Copilot path, rationale. Status legend:
> ✅ ported | ⚠️ partial | 🕒 deferred (Tier 3b) | ⏭ skipped-by-design.

### Top level `.claude/*`

| Upstream path | Status | Copilot path | Reason |
|---|---|---|---|
| `CLAUDE.md` | ⏭ | — | Replaced by `.github/copilot-instructions.md` + `~/.copilot/copilot-instructions.md`. |
| `CLAUDE.md.template` | ⏭ | — | Same reason. |
| `install.sh` | ⏭ | `Copilot/install.sh` (new) | Copilot port uses its own installer. |
| `settings.json` | ⏭ | — | Claude Code JSON-schema format. Hook registrations, permissions, MCP config don't apply. |
| `statusline-command.sh` (1390 lines) | 🕒 | — | Claude Code statusline API only. Tmux-overlay equivalent is Tier 3b. |
| `agents/` (14 `.md` profiles) | ✅ | `Copilot/agents/` | Ported Tier 1. Reference material only — Copilot `task` tool collapses subagent types to `general-purpose`/`explore`. |
| `PAI/` | mixed | `Copilot/PAI/` (subnamespace) | See sub-rows below. |

### `.claude/PAI/*` documentation + subdirs

| Upstream path | Status | Copilot path | Reason |
|---|---|---|---|
| `PAI/ACTIONS.md` | ✅ | `Copilot/PAI/ACTIONS.md` | Tier 1. |
| `PAI/AISTEERINGRULES.md` | ✅ | `Copilot/PAI/AISTEERINGRULES.md` | Tier 1. |
| `PAI/CLI.md` | ✅ | `Copilot/PAI/CLI.md` | Tier 1. |
| `PAI/CLIFIRSTARCHITECTURE.md` | ✅ | `Copilot/PAI/CLIFIRSTARCHITECTURE.md` | Tier 1. |
| `PAI/CONTEXT_ROUTING.md` | ✅ | `Copilot/PAI/CONTEXT_ROUTING.md` | Tier 1. |
| `PAI/DOCUMENTATIONINDEX.md` | ✅ | `Copilot/PAI/DOCUMENTATIONINDEX.md` | Tier 1. |
| `PAI/doc-dependencies.json` | ⏭ | — | Consumed only by upstream `DocIntegrity.hook.ts`; not actionable without hook API. |
| `PAI/FLOWS.md` | ✅ | `Copilot/PAI/FLOWS.md` | Tier 1. |
| `PAI/MEMORYSYSTEM.md` | ✅ | `Copilot/PAI/MEMORYSYSTEM.md` | Tier 1. |
| `PAI/PAIAGENTSYSTEM.md` | ✅ | `Copilot/PAI/PAIAGENTSYSTEM.md` | Tier 1. |
| `PAI/PAISYSTEMARCHITECTURE.md` | ✅ | `Copilot/PAI/PAISYSTEMARCHITECTURE.md` | Tier 1. |
| `PAI/PIPELINES.md` | ✅ | `Copilot/PAI/PIPELINES.md` | Tier 1. |
| `PAI/PRDFORMAT.md` | ✅ | `Copilot/PAI/PRDFORMAT.md` | Tier 1 (frontmatter spec used by `new-prd.sh`). |
| `PAI/README.md` | ⏭ | — | Copilot has `Copilot/README.md`; upstream version duplicates. |
| `PAI/SKILL.md` | ⏭ | — | Copilot source of truth is `copilot-instructions.md`. |
| `PAI/SKILLSYSTEM.md` | ✅ | `Copilot/PAI/SKILLSYSTEM.md` | Tier 1. |
| `PAI/SYSTEM_USER_EXTENDABILITY.md` | ✅ | `Copilot/PAI/SYSTEM_USER_EXTENDABILITY.md` | Tier 1. |
| `PAI/THEDELEGATIONSYSTEM.md` | ✅ | `Copilot/PAI/THEDELEGATIONSYSTEM.md` | Tier 1. |
| `PAI/THEFABRICSYSTEM.md` | ✅ | `Copilot/PAI/THEFABRICSYSTEM.md` | Tier 1. |
| `PAI/THEHOOKSYSTEM.md` | ✅ | `Copilot/PAI/THEHOOKSYSTEM.md` | Tier 1 (docs only — hook runtime not ported). |
| `PAI/THENOTIFICATIONSYSTEM.md` | ✅ | `Copilot/PAI/THENOTIFICATIONSYSTEM.md` | Tier 1. |
| `PAI/TOOLS.md` | ✅ | `Copilot/PAI/TOOLS.md` | Tier 1. |
| `PAI/ACTIONS/README.md` | ✅ | `Copilot/PAI/ACTIONS/README.md` | Tier 1. |
| `PAI/ACTIONS/A_EXAMPLE_*` (json+ts) | 🕒 | — | Requires bun runtime; ACTIONS execution engine is Tier 3b. |
| `PAI/ACTIONS/lib/*.ts` (runner.ts, pipeline-runner.ts, types.ts) | 🕒 | — | Same. |
| `PAI/FLOWS/README.md` | ✅ | `Copilot/PAI/FLOWS/README.md` | Tier 1. |
| `PAI/PIPELINES/README.md` | ✅ | `Copilot/PAI/PIPELINES/README.md` | Tier 1. |
| `PAI/PIPELINES/P_EXAMPLE_SUMMARIZE_AND_FORMAT.yaml` | 🕒 | — | Requires pipeline runner (Tier 3b). |
| `PAI/Algorithm/v3.5.0.md` | ✅ | `Copilot/PAI/Algorithm/v3.5.0.md` | Tier 1. |
| `PAI/Algorithm/v3.7.0.md` | ✅ | `Copilot/PAI/Algorithm/v3.7.0.md` | Tier 1 (current). |
| `PAI/Algorithm/LATEST` (pointer `v3.7.0`) | ⏭ | — | Trivially reconstructable; not ported. |

### `.claude/PAI/USER/*` scaffolds (Tier 2)

| Upstream path | Status | Copilot path | Reason |
|---|---|---|---|
| `PAI/USER/README.md` | ✅ (replaced) | `Copilot/PAI/USER/README.md` | Copilot-authored overview mapping to actual `~/.pai/USER/` layout. |
| `PAI/USER/ACTIONS/README.md` | ✅ | `Copilot/PAI/USER/ACTIONS/README.md` | Tier 2. |
| `PAI/USER/BUSINESS/README.md` | ✅ | `Copilot/PAI/USER/BUSINESS/README.md` | Tier 2. |
| `PAI/USER/FLOWS/README.md` | ✅ | `Copilot/PAI/USER/FLOWS/README.md` | Tier 2. |
| `PAI/USER/PIPELINES/README.md` | ✅ | `Copilot/PAI/USER/PIPELINES/README.md` | Tier 2. |
| `PAI/USER/PROJECTS/README.md` | ✅ | `Copilot/PAI/USER/PROJECTS/README.md` | Tier 2. |
| `PAI/USER/SKILLCUSTOMIZATIONS/README.md` | ⏭ (live) | `~/.pai/USER/SKILLCUSTOMIZATIONS/` | Already populated at runtime; don't clobber. |
| `PAI/USER/STATUSLINE/README.md` | ⚠️ | `Copilot/PAI/USER/STATUSLINE/README.md` | Ported as scaffold; banner flags Copilot CLI has no statusline API. |
| `PAI/USER/TELOS/README.md` | ⏭ (live) | `~/.pai/USER/TELOS/` | Populated; don't clobber. |
| `PAI/USER/TERMINAL/README.md` | ✅ | `Copilot/PAI/USER/TERMINAL/README.md` | Tier 2. |
| `PAI/USER/WORK/README.md` | ✅ | `Copilot/PAI/USER/WORK/README.md` | Tier 2. |
| `PAI/USER/Workflows/README.md` | ✅ | `Copilot/PAI/USER/Workflows/README.md` | Tier 2. |

### `.claude/PAI/Tools/*.ts` — Bun TypeScript utilities

> **Tier 3+ update (2026-04-23):** All non-cosmetic tools below listed as 🕒 have been ported verbatim to `Copilot/PAI/Tools/` and run under `bun`. Status-column "🕒" annotations predate Tier 3+; treat them as **✅ (bun)** unless the row is marked as skipped (Banner/cosmetic, BuildCLAUDE, RebuildPAI, Inference). Install deps: `cd ~/.pai/PAI/Tools && bun install`.


| Upstream file | Status | Copilot equivalent | Reason |
|---|---|---|---|
| `ActivityParser.ts` | 🕒 | — | Activity-log parser; niche, defer. |
| `AddBg.ts`, `RemoveBg.ts` | 🕒 | — | Image background tools; in-scope under `Media` skill if demand surfaces. |
| `algorithm.ts` | 🕒 | — | Upstream Algorithm runner; Copilot runs Algorithm via `copilot-instructions.md` rules. |
| `AlgorithmPhaseReport.ts` | 🕒 | — | Phase reporter; not wired in Copilot. |
| `Banner.ts`, `BannerMatrix.ts`, `BannerNeofetch.ts`, `BannerPrototypes.ts`, `BannerRetro.ts`, `BannerTokyo.ts`, `NeofetchBanner.ts`, `PAILogo.ts` | ⏭ | — | Terminal ASCII-art cosmetics. Skipped by design. |
| `BuildCLAUDE.ts` | ⏭ | — | Rebuilds `CLAUDE.md` from template; Copilot has its own instructions system. |
| `extract-transcript.py`, `ExtractTranscript.ts`, `GetTranscript.ts`, `TranscriptParser.ts` | 🕒 | — | YouTube/transcript pipeline; in-scope if `Media`/`Research` skills need it. |
| `FailureCapture.ts` | 🕒 | `capture-rating.sh` (partial) | Copilot capture-rating writes a failure shell on ratings ≤3, but doesn't dump tool-call context (needs hook API). |
| `FeatureRegistry.ts` | 🕒 | — | Skill feature enumeration; not wired. |
| `GetCounts.ts`, `UpdateCounts.ts` (hook) | 🕒 | — | Document count maintenance. |
| `Inference.ts` | ✅ | `bun ~/.pai/PAI/Tools/Inference.ts` (Tier 3+ shim) | Auto-routes to `gh models run` via `github/gh-models` extension when `claude` is absent or `PAI_INFERENCE_BACKEND=copilot`. Model map overridable via env. |
| `IntegrityMaintenance.ts` | ⚠️ | `pai-copilot post_session_tier3 > integrity_scan()` (Tier 3) | Sidecar does a lightweight regression scan; full upstream scope (doc-dependencies.json enforcement) is Tier 3b. |
| `LearningPatternSynthesis.ts` | ✅ (bun) | `Copilot/PAI/Tools/LearningPatternSynthesis.ts`; sidecar calls it | Tier 3+ revert. Weekly stamp-gated run from sidecar POST. |
| `LoadSkillConfig.ts` | 🕒 | — | Used by PAIUpgrade workflow; banner-flagged at phantom-cleanup. |
| `OpinionTracker.ts` | 🕒 | — | Niche. |
| `pai.ts`, `PreviewMarkdown.ts`, `pipeline-monitor-ui`, `PipelineMonitor.ts`, `PipelineOrchestrator.ts` | 🕒 | — | Pipeline runtime family; Tier 3b. |
| `RebuildPAI.ts` | ⏭ | — | Claude-Code-specific installer side. |
| `RelationshipReflect.ts` | ⚠️ | `~/.pai/MEMORY/RELATIONSHIP/` append rules in instructions | AI-handled, not a tool. |
| `SecretScan.ts` | ✅ (bun) | `Copilot/PAI/Tools/SecretScan.ts` | Tier 3+ revert to upstream bun tool after discovering bun available. |
| `SessionHarvester.ts` | ✅ (equivalent) | `Copilot/tools/harvest-session.sh` | Session-folder harvester written for Copilot session format. |
| `SessionProgress.ts` | 🕒 | — | Hook-dependent. |
| `SplitAndTranscribe.ts` | 🕒 | — | Audio tooling; niche. |
| `WisdomCrossFrameSynthesizer.ts`, `WisdomDomainClassifier.ts`, `WisdomFrameUpdater.ts` | ✅ | `bun ~/.pai/PAI/Tools/Wisdom*.ts` | Runnable via bun; inference now satisfied by the Tier 3+ `Inference.ts` shim to `gh models run`. |
| `YouTubeApi.ts` | 🕒 | — | Used by YouTube extraction workflow (phantom-cleaned in Tier 3). |

### `.claude/hooks/` — Hook handlers (from `settings.json`)

Upstream registers 22 handlers across 6 groups. Copilot CLI has **no hook API**. Approximations where possible; most are fundamentally unportable per-tool-call.

| Group / matcher | Upstream handler | Copilot equivalent | Rationale |
|---|---|---|---|
| PreToolUse/Bash,Edit,Write,Read | `SecurityValidator.hook.ts` | `copilot-instructions.md § Security Rules` | Instruction-based refusal rules; no runtime filter. |
| PreToolUse/AskUserQuestion | `SetQuestionTab.hook.ts` | — | Tab title is sidecar PRE only. |
| PreToolUse/Task | `AgentExecutionGuard.hook.ts` | — | Unportable without hook API. |
| PreToolUse/Skill | `SkillGuard.hook.ts` | — | Same. |
| PostToolUse/AskUserQuestion | `QuestionAnswered.hook.ts` | — | Same. |
| PostToolUse/Write,Edit | `PRDSync.hook.ts` | Instructions: AI bumps `updated:` when editing PRD | No auto-sync; discipline-based. |
| SessionEnd | `WorkCompletionLearning.hook.ts` | `capture-work-learning.sh` (AI-invoked) | Ported as manual tool. |
| SessionEnd | `SessionCleanup.hook.ts` | `pai-copilot post_session > cleanup_stale_state` | Ported. |
| SessionEnd | `RelationshipMemory.hook.ts` | Instructions: `§ Relationship Memory` (AI-handled) | Best-effort capture at shutdown. |
| SessionEnd | `UpdateCounts.hook.ts` | — | Skipped; cosmetic. |
| SessionEnd | `IntegrityCheck.hook.ts` | `pai-copilot post_session_tier3 > integrity_scan` (Tier 3) | Regression guard only; narrower than upstream. |
| UserPromptSubmit | `RatingCapture.hook.ts` | `capture-rating.sh` + instructions § Rating Capture | AI fires on `\d/10` patterns. |
| UserPromptSubmit | `UpdateTabTitle.hook.ts` | Sidecar PRE sets tab title once | Per-prompt update is unportable. |
| UserPromptSubmit | `SessionAutoName.hook.ts` | — | Skipped. |
| SessionStart | `KittyEnvPersist.hook.ts` | — | Skipped. |
| SessionStart | `LoadContext.hook.ts` | Instructions: § Session Startup | AI loads startup-digest.md + ABOUTME + DAIDENTITY. |
| SessionStart | `bun BuildCLAUDE.ts` | — | Skipped (Copilot instructions system). |
| Stop | `LastResponseCache.hook.ts` | — | Skipped. |
| Stop | `ResponseTabReset.hook.ts` | Sidecar POST resets title | Approximation only. |
| Stop | `VoiceCompletion.hook.ts` | Instructions: voice curl at end of non-MINIMAL responses | AI-fired. |
| Stop | `DocIntegrity.hook.ts` | `pai-copilot integrity_scan` (Tier 3) | Regression guard only. |
| SessionStart | `PRDGenerate.hook.ts` (not in settings above — upstream separately hooks this) | `Copilot/tools/new-prd.sh` (Tier 2) | Tool-based replacement. |

### Runtime state + memory

| Upstream artifact | Status | Copilot artifact |
|---|---|---|
| `~/.claude/MEMORY/` tree | ✅ | `~/.pai/MEMORY/` |
| `MEMORY/LEARNING/ALGORITHM/`, `SYSTEM/` | ✅ | Ported; `capture-work-learning.sh` writes here. |
| `MEMORY/LEARNING/FAILURES/` | ✅ | Present; populated by `capture-rating.sh` on low ratings. |
| `MEMORY/LEARNING/SIGNALS/` | ✅ | Present; `capture-rating.sh` writes jsonl. |
| `MEMORY/LEARNING/SYNTHESIS/` | ✅ | Tier 2 scaffolded; Tier 3 wires weekly run. |
| `MEMORY/LEARNING/REFLECTIONS/algorithm-reflections.jsonl` | ✅ | Tier 2 added; `capture-work-learning.sh --reflection` appends. |
| `MEMORY/RELATIONSHIP/` | ✅ | AI-handled per instructions. |
| `MEMORY/RESEARCH/` | ✅ | `save-research-memory.sh` is the single writer. |
| `MEMORY/WORK/<slug>/PRD.md` | ✅ | `new-prd.sh` scaffolds; `backfill-prd-frontmatter.sh` retrofits. |
| `MEMORY/WORK/active.md` | ✅ | Hand-curated; overwritten on ALGORITHM start and shutdown. |
| `MEMORY/WORK/projects/` engagement | ✅ (Copilot-native) | Sidecar PRE `capture_engagement()`; not upstream. |
| `state/sessions.log` | ✅ | Sidecar writes. |

### Explicitly NOT ported (Tier 3b deferred)

### Explicitly NOT ported (Tier 3b deferred) — outdated, see Tier 3+ section

**Note:** this subsection predates Tier 3+. Most rows here are now closed. Kept for historical trace.

| Item | Reason | Status (2026-04-23) |
|---|---|---|
| Per-tool-call hooks (SecurityValidator live filter, PRDSync auto-bump, AgentExecutionGuard, SkillGuard, SetQuestionTab, QuestionAnswered) | Copilot CLI has no hook API. Approximation via instructions only. | **Still unportable.** |
| `statusline-command.sh` (1390 lines) | Claude Code statusline API. Tmux-overlay equivalent is Tier 3b. | ✅ ported Tier 3+ (tmux/manual). |
| ACTIONS/PIPELINES runtime (`lib/runner.ts`, `pipeline-runner.ts`, example actions/pipelines) | Requires bun. Major new feature; defer until concrete use case. | ✅ ported Tier 3+. |
| `Inference.ts` unified wrapper | Copilot CLI has its own model system. | ✅ shimmed to `gh models run` Tier 3+. |
| Banner/neofetch/PAILogo TS | Cosmetic. | Skipped by design. |
| Wisdom*.ts triad (CrossFrame, Domain, Frame) | Depends on Inference.ts. | ✅ ported Tier 3+ (runs via Inference shim). |
| Pipeline monitor UI | Depends on runtime. | ✅ ported Tier 3+ (React UI copied). |
| Remaining `PAI/Tools/*.ts` not cited above | Port individually if a skill/workflow demands it. | ✅ all 37 tools ported Tier 3+. |

### Procedure to re-run this port from scratch

1. Pin upstream: `git clone --depth 1 https://github.com/danielmiessler/PAI /tmp/pai-upstream` (release folder `Releases/v4.0.3/.claude/`).
2. Cut fallback tag: `git tag pre-port-<UTC> && git push origin --tags`.
3. **Tier 1**: mechanical port of `.claude/PAI/*.md` + `.claude/PAI/{ACTIONS,FLOWS,PIPELINES,Algorithm}/README.md|*.md` + `.claude/agents/*.md` into `Copilot/PAI/` and `Copilot/agents/`. Apply substitution table at top of this file. Add upstream banner to each ported file. Skip: `CLAUDE.md`, `settings.json`, `install.sh`, `statusline-command.sh`, `PAI/README.md`, `PAI/SKILL.md`, `PAI/Tools/`, `PAI/USER/` (defer to Tier 2).
4. **Tier 2**: port `.claude/PAI/USER/*/README.md` to `Copilot/PAI/USER/`. Skip `TELOS/` and `SKILLCUSTOMIZATIONS/` if live content already exists under `~/.pai/USER/`. Add `Copilot/tools/new-prd.sh` implementing upstream PRDFORMAT v2.0 frontmatter. Create `Copilot/PAI/MEMORY/LEARNING/{SYNTHESIS,REFLECTIONS}/README.md`. Extend `capture-work-learning.sh` with `--reflection`.
5. **Tier 3**: extend sidecar POST (weekly synthesis + integrity scan). Port `SecretScan` as shell. Add `backfill-prd-frontmatter.sh`. Rewrite phantom-PAI-root refs using canonical map:
   - `~/.pai/PAI/SKILL.md` → `~/.copilot/copilot-instructions.md`
   - `bun ~/.pai/PAI/Tools/X.ts` → append ` # NOT PORTED in Copilot (upstream bun tool; see Copilot/PORTING_NOTES.md)`
   - `~/.pai/PAI/Prompting.md` → `~/.pai/skills/Prompting/README.md`
6. After each tier: rsync `Copilot/PAI/`, `Copilot/agents/`, `Copilot/skills/` into `~/.pai/*`; copy updated `Copilot/tools/*.sh` into `~/.pai/tools/`; copy `Copilot/sidecar/pai-copilot` into `~/.pai/sidecar/pai-copilot`. Never run upstream's `install.sh` — it clobbers live state.
7. Update this file with any new divergences discovered.
