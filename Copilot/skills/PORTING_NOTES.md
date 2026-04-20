# Skill Ports — mechanical migration notes

This file documents the batch port of 6 upstream skill packs to the Copilot
CLI spike: **Telos**, **Thinking**, **Investigation**, **ContentAnalysis**,
**USMetrics**, **Security**.

Source: `Releases/v4.0.3/.claude/skills/<Name>/`.

## Automated substitutions applied

Applied across all `.md`, `.yaml`, `.yml`, `.ts`, `.tsx`, `.js`, `.json`,
`.sh` files in each ported tree:

| From (Claude Code) | To (Copilot CLI) |
|---|---|
| `~/.claude/`, `$HOME/.claude/` | `~/.pai/`, `$HOME/.pai/` |
| `.claude/skills/`, `.claude/PAI/` | `.pai/skills/`, `.pai/` |
| `Read tool` / `Write tool` / `Edit tool` | `view tool` / `create tool` / `edit tool` |
| `MultiEdit tool` | `edit tool (called multiple times)` |
| `WebFetch tool` / `WebSearch tool` | `web_fetch tool` / `web_search tool` |
| `Bash tool` / `Glob tool` / `Grep tool` / `Task tool` | `bash tool` / `glob tool` / `grep tool` / `task tool` |
| `TodoWrite tool` | `sql tool (todos table)` |
| `subagent_type: "<Claude custom type>"` | `agent_type: "general-purpose"` (or `"explore"` where appropriate) |
| `subagent_type:` (generic) | `agent_type:` |
| `run_in_background: true` | `mode: "background"` |

## What this port *does not* do

1. **Model diversity is lost.** Any workflow that used
   `GeminiResearcher` / `ClaudeResearcher` / `PerplexityResearcher` /
   `GrokResearcher` / `CodexResearcher` / `Engineer` / `Architect` /
   `Designer` / `Artist` / `QATester` agents now runs under the single
   `general-purpose` agent. Parallelism is preserved; provider diversity
   is not.

2. **External API tools still reference upstream services.**
   - `Security/Recon/Tools/BountyPrograms.ts` and similar TS tools were
     updated for paths but the APIs they call (HackerOne, Bugcrowd, etc.)
     remain unchanged. They run under `bash` via `bun` exactly as before.
   - `Scraping/*` skills (not in this batch) still depend on Apify / BrightData
     API keys.

3. **Voice `voice_id` parameters.** Any lingering ElevenLabs `voice_id`
   fields in curl payloads are ignored by the spike voice server (which
   uses macOS `say`). Harmless dead weight.

4. **`USER/SKILLCUSTOMIZATIONS/<Skill>/` overrides.** Referenced as load-time
   lookups. Directories don't exist yet in the Copilot install; skills fall
   through to defaults.

5. **Telos Dashboard.** `Telos/DashboardTemplate/` is a Next.js app with an
   API route that shells out to `~/.pai/PAI/Tools/Inference.ts`. That file
   doesn't exist in the Copilot runtime — the dashboard's chat feature will
   fail until `gh models` or an equivalent inference shim is wired up.
   Static Telos usage (reading/writing MISSION.md, GOALS.md, etc.) works.

## Known friction (capture in `tasks/lessons.md` after first real use)

- Does any workflow reference a model-specific agent role the AI can't
  compensate for (e.g., a GrokResearcher asked for "raw unfiltered" takes)?
- Do the big ASCII-box output formats render cleanly in Copilot CLI's TUI?
- Security skills expect certain tools on `$PATH` (ffuf, amass, etc.).
  Copilot session will fail fast if missing; that's acceptable for the spike.
- Investigation/PrivateInvestigator may reference paywalled data sources —
  document which fall back gracefully vs which produce empty results.

## Tier-2 30-day eval additions (2026-04-20)

### CreateSkill (`Copilot/skills/CreateSkill/`)
- Mechanical port of `Releases/v4.0.3/.claude/skills/Utilities/CreateSkill/`
  (5 files). Enables the "grow in parallel" strategy — user can scaffold
  and validate new Copilot skills without hand-porting.

### Media + Media/Art (`Copilot/skills/Media/`)
- Ported the full `Media/Art/` tree but scoped routing to **Mermaid only**.
- Parent `Copilot/skills/Media/SKILL.md` carries a prominent Copilot Spike
  Status banner explaining that image-gen workflows (Midjourney, OpenAI,
  `ComposeThumbnail.ts`) require API keys and Remotion is not ported.
- All 13 Workflows are preserved for reference; only `Workflows/Mermaid.md`
  is advertised as executable in the routing table.
- TS tools (`Generate.ts`, `GenerateMidjourneyImage.ts`, `ComposeThumbnail.ts`,
  `GeneratePrompt.ts`) remain in place — they will fail fast without the
  required environment, which is acceptable for the spike.

### Delegation (`Copilot/skills/Delegation/`)
- Ported with an explicit **degraded-form** Copilot Spike Status banner at
  the top of `SKILL.md`. The banner maps Claude-Code-only constructs onto
  Copilot equivalents:
  - Specialized agent types (Engineer, Architect, Algorithm, …) →
    `task` with `agent_type: "general-purpose"` + prompt flavoring
  - `model="haiku"/"sonnet"/"opus"` → ignored
  - `TeamCreate` / `TaskCreate` / `SendMessage` → **not available**; fall
    back to parallel `task` calls coordinated via shared files or the SQL
    `todos` table
  - `run_in_background: true` → `mode: "background"`
- The rest of the SKILL.md is preserved as reference material. AIs reading
  it must apply the mapping table, not follow the prose literally.
- Second substitution pass was needed for Delegation: the initial regex
  only matched `subagent_type:` (colon form); function-call form
  `subagent_type="..."` was rewritten in a dedicated pass.
## Tier-1 30-day eval additions (2026-04-20)

Three additions from the 30-day eval plan (session folder `plan.md`):

### Parser (`Copilot/skills/Parser/`)
- Mechanical port of `Releases/v4.0.3/.claude/skills/Utilities/Parser/`.
- All 30 files substituted with the standard table above.
- Known issue (upstream, pre-existing): `Lib/parser.ts` imports
  `../schema/schema.ts` but the dir is `Schema/` — would fail on
  case-sensitive filesystems. Not fixed by this port; flag if encountered.
- Dep: `uuid` (bun-installable).

### Documents/Pdf (`Copilot/skills/Documents/Pdf/`)
- Only the **PDF sub-skill** is ported. Parent `SKILL.md` now carries a
  "Copilot Spike Status" note and routes DOCX/XLSX/PPTX to "Not ported".
- `Workflows/ConsultingReport.md` and `Workflows/ProcessLargePdfGemini3.md`
  are ported alongside PDF (they are PDF-adjacent).
- Python scripts depend on `pypdf`, `pdf2image`, `Pillow` — user must
  `pip install` them on first use.

### harvest-session.sh (`Copilot/tools/harvest-session.sh`)
- Replaces the upstream `SessionHarvester.ts` (which parsed Claude
  `projects/` transcripts). This version reads
  `~/.copilot/session-state/*/events.jsonl` directly.
- Extracts `session.task_complete` events (they already contain
  self-generated markdown summaries) and pipes each session's summary
  through `capture-work-learning.sh`.
- Idempotent via a `.harvested` sentinel per session directory.
- First smoke run on this host captured 18 historic sessions into
  `MEMORY/LEARNING/SYSTEM/2026-04/`.
- Limitation: auto-categorisation skews SYSTEM because the infra keyword
  list hits most engineering summaries. User may manually move ALGORITHM
  items if the imbalance becomes a problem.

## Tier-3 30-day eval additions (2026-04-20)

Milestone 3 of the eval plan. User expanded the default T3 scope
(LearningPatternSynthesis only) to include **all five opportunistic
Utilities skills** in one batch. Standard `PORTING_NOTES.md` substitution
table applied via `_port-skill.sh` (helper removed after use).

### synthesize-learnings (`Copilot/tools/synthesize-learnings.{ts,sh}`)
- Port of `Releases/v4.0.3/.claude/PAI/Tools/LearningPatternSynthesis.ts`.
  TS tool renamed for clarity; `.sh` wrapper forwards all flags through
  `bun run`.
- Path substitution: `CLAUDE_DIR` → `PAI_DIR`, `~/.claude/` → `~/.pai/`.
- **Schema bridge added:** upstream TS expected
  `{timestamp, session_id, sentiment_summary, confidence}` but
  `capture-rating.sh` writes `{ts, session, summary}`. Port normalizes
  both schemas at parse time (`raw.timestamp ?? raw.ts`, etc.). Without
  this shim every rating was filtered out as "Invalid Date".
- Smoke test: `./Copilot/tools/synthesize-learnings.sh --dry-run --all`
  correctly loads and analyses existing `ratings.jsonl` entries.
- **Signal note:** the plan calls for ≥ 3 weeks of accumulated ratings
  before outputs are meaningful. Shipping the port now; first useful run
  is around eval week 3.

### Aphorisms (`Copilot/skills/Aphorisms/`)
- Mechanical port (6 files, all markdown). Database + 4 workflows + SKILL.md.
- No code dependencies.
- `Database/aphorisms.md` is plain text and carries no Claude-era tool references.

### PAIUpgrade (`Copilot/skills/PAIUpgrade/`)
- Mechanical port (11 files). Includes `Tools/Anthropic.ts` changelog
  fetcher and YouTube monitoring workflow.
- Fixed one residual path the sed pass missed:
  `join(HOME, '.claude', 'skills', 'PAIUpgrade')` → `join(HOME, '.pai', 'skills', 'PAIUpgrade')`
  (comma-separated form, not caught by `~/.claude` / `$HOME/.claude` regexes).
- External URL references to `docs.claude.com`, `support.claude.com`,
  `platform.claude.com` are **intentionally preserved** — those are real
  public documentation endpoints, not filesystem paths.
- Dep: `ANTHROPIC_API_KEY` for `Tools/Anthropic.ts`. Fails fast without it.

### Prompting (`Copilot/skills/Prompting/`)
- Mechanical port (28 files). Handlebars template system with
  `RenderTemplate.ts` / `ValidateTemplate.ts` and a `Templates/` tree
  (Primitives, Evals, Data).
- Self-contained bun project under `Templates/Tools/` with its own
  `package.json` / `bun.lock`; user runs `bun install` there on first
  use.
- One residual rollback doc rewrote `cd ~/.claude` → `cd ~/.pai` manually
  (outside the standard substitution set).
- External URL references to `platform.claude.com` docs preserved.

### Evals (`Copilot/skills/Evals/`)
- Mechanical port (38 files). TS grader framework (`Graders/Base.ts`,
  `Graders/CodeBased/*`, `Graders/ModelBased/*`), workflow docs, regression
  suite, and `Tools/*.ts` (TrialRunner, TranscriptCapture, SuiteManager,
  FailureToTask, AlgorithmBridge).
- **Degraded form — same class as Delegation.** `Graders/ModelBased/*.ts`
  (`LLMRubric`, `PairwiseComparison`, `NaturalLanguageAssert`) were
  designed for model-diverse sub-agents via Claude Code's custom
  `subagent_type`. Under Copilot they all collapse to
  `agent_type: "general-purpose"`. Pairwise comparison between providers
  is **not possible** in the spike — it compares a single model against
  itself. Useful for regression / rubric grading; not for model bake-offs.
- No special deps; runs under bun.

### Fabric (`Copilot/skills/Fabric/`)
- Mechanical port (318 files). Overwhelmingly `Patterns/*/system.md` and
  `Patterns/*/user.md` prompt files originally designed for the
  upstream [Fabric CLI](https://github.com/danielmiessler/fabric).
- **No Fabric CLI is bundled with the Copilot spike.** Patterns are
  reference prompt templates — use by either (a) reading the relevant
  `system.md` and pasting its content into a `task` prompt, or (b)
  installing the upstream Fabric CLI separately and pointing it at this
  directory.
- The substitution pass only touched a handful of files (the SKILL.md
  and a couple of meta-patterns that referenced Claude-era tool names).
  The 318 pattern files themselves are pure LLM system prompts.
