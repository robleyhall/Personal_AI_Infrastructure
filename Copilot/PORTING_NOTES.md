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

## Cross-reference
- Skill-level mechanical ports: [`skills/PORTING_NOTES.md`](skills/PORTING_NOTES.md)
- Research skill specifics: [`skills/Research/PORTING_NOTES.md`](skills/Research/PORTING_NOTES.md)
- Remaining divergences / backlog: `~/.pai/MEMORY/WORK/active.md` (Queued sections), Copilot Environment Security & Efficiency Audit Phase 2 scope.
