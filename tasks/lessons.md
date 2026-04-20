# Lessons Learned — PAI Copilot Migration

> **Purpose:** Patterns, rules, and discoveries to prevent repeated mistakes and preserve institutional knowledge. Review at session start.

---

## Session: 2026-04-19 — Phase 0 spike setup

### Lesson 1: Research skill has hardcoded custom sub-agent names

**What happened:** The Research skill's workflows spawn agents with custom types like `ClaudeResearcher`, `GeminiResearcher`, `PerplexityResearcher`, `GrokResearcher`. These are Claude Code custom sub-agents — Copilot CLI has no equivalent; its `task` tool exposes only a fixed set (`general-purpose` / `explore` / `task` / `rubber-duck` / `code-review`).

**Fix:** Mechanical substitution to `agent_type: "general-purpose"` during port. Parallelism and workflow shape preserved; *model diversity* is lost.

**Rule:** When porting a skill, grep for `subagent_type:` before assuming the port is mechanical. Any skill that relied on model diversity across agents needs either (a) an external provider shim (call `gh models` / OpenAI / Gemini from a bash tool script) or (b) explicit acknowledgement that this diversity is gone for the spike.

### Lesson 2: Voice server has ~700 lines of ElevenLabs-specific code

**What happened:** `Releases/v4.0.3/.claude/VoiceServer/server.ts` is 716 lines covering pronunciations, multi-voice config, rate limiting, personality modes, AppleScript escaping, and emotional-marker parsing — all tied to ElevenLabs's API surface.

**Fix:** Wrote an 80-line drop-in replacement (`Copilot/VoiceServer/server.ts`) that exposes the same `POST /notify` shape but speaks via macOS `say`. Existing callers work unchanged; `voice_id` fields are accepted and ignored.

**Rule:** Don't "port" a 700-line provider-specific file. Re-implement the *interface* with the simplest backend that satisfies the spike goal, and restore the fancy features later only if a real use case needs them.

### Lesson 3: Copilot CLI cannot register hooks or custom slash commands

**What happened:** Plan assumed we could preserve the 20-hook PAI system. Confirmed we cannot — only two viable strategies exist: (a) bake hook behavior into `copilot-instructions.md` rules the AI follows, (b) put shell-level behavior in a sidecar wrapper that runs pre/post `copilot`.

**Fix:** Split the 20 hooks as: LoadContext / VoiceCompletion / RatingCapture / SecurityValidator / WorkCompletionLearning / RelationshipMemory → instructions. KittyEnvPersist / SessionCleanup / UpdateTabTitle → sidecar. The remaining 14 are cosmetic and dropped.

**Rule:** In-session behavior (things that happen during a prompt/response cycle) can only live in `copilot-instructions.md`. Out-of-session behavior (setup, teardown, process management) goes in the sidecar. Anything that needs *deterministic* mid-tool-call interception (e.g. "block this bash command before it runs") cannot be replicated without a PTY wrapper — defer and live with instruction-based approximations.

### Lesson 4: Mechanical find-and-replace misses mid-sentence tool names

**What happened:** Initial `sed` pass replaced `\bRead tool\b` but missed `using the Read tool` mid-sentence prose, and missed `subagent_type="GeminiResearcher"` (attribute, not YAML key). Took a second pass to catch both.

**Fix:** Added explicit patterns for prose and attribute-style variants.

**Rule:** After any automated migration pass, grep the whole tree for the original tokens (`subagent_type`, `Read tool`, `\.claude/`, `run_in_background`) and fix every remaining hit. Don't trust the first pass — count zero matches before calling it done.

### Lesson 5: GitHub Copilot plan comparison data is partly hidden in dynamic page data

**What happened:** While researching current Copilot usage limits, the public Docs markdown rendered the narrative text but not the full comparison-table values for Business and Enterprise allowances. The github.com pricing page did contain the values, but only inside embedded JSON rather than visible markdown.

**Fix:** Verified docs URLs with `curl`, then extracted the pricing page's embedded JSON to confirm `customTextForBusiness = 300 per user per month` and `customTextForEnterprise = 1,000 per user per month`.

**Rule:** When GitHub Docs pages omit comparison-table values in fetched markdown, inspect the corresponding github.com pricing page's embedded JSON before concluding the data is unavailable. For Copilot plan limits, treat the docs prose as policy/source-of-truth for semantics and the pricing page JSON as the reliable source for the hidden per-plan comparison values.


## Session: 2026-04-20 — Docs research workflow

### Lesson 5: GitHub Docs API may omit populated comparison-table rows

**What happened:** During Copilot usage-limit research, `docs.github.com/api/article` returned markdown bodies for the relevant pages, but several comparison tables (especially model tables) arrived with blank row cells even though the rendered docs page clearly has data.

**Fix:** Verify the core claims from multiple official docs pages instead of trusting a single table export, and explicitly call out any gaps the fetched docs do not expose.

**Rule:** When researching GitHub Docs programmatically, treat `api/article` as helpful but incomplete for dynamic tables. Cross-check with the human docs page and avoid claiming exact table contents you could not directly fetch.


### Lesson 5: Research skill docs disagree on standard mode agent count

**What happened:** `~/.pai/skills/Research/SKILL.md` and `QuickReference.md` describe Standard research as a 3-agent workflow, but `Workflows/StandardResearch.md` now specifies 2 agents (Claude + Gemini). That mismatch makes it easy to follow the wrong workflow or overstate expected behavior.

**Fix:** For Copilot CLI sessions, treat `Workflows/StandardResearch.md` as the operational source of truth and call out the discrepancy when maintaining the port.

**Rule:** When a skill has both a routing doc and per-workflow docs, compare both before execution. If counts, steps, or tools differ, follow the workflow file and record the mismatch in `tasks/lessons.md`.


### Lesson 6: Startup memory must stay distilled or it burns usage

**What happened:** Research artifacts can be large, but the Copilot startup flow reads `~/.pai/MEMORY/LEARNING/latest.md` and `~/.pai/MEMORY/WORK/active.md` every session. Dumping full research output there would force repeated token spend for low-value detail.

**Fix:** Added a promotion step that stores the full research artifact under `MEMORY/RESEARCH`, then writes only a compact "what matters" digest into `latest.md` and `active.md`.

**Rule:** Persist the full artifact for retrieval, but only promote distilled, durable takeaways into startup memory. Treat startup-loaded files as a cache of what matters, not a log of everything that happened.


### Lesson 7: Migration status docs drift unless support files land together

**What happened:** The spike README still implied the Algorithm port was deferred even after the instruction system started depending on Copilot-specific support docs. That made the migration state look less complete than the actual implementation and invited the next session to plan from stale status.

**Fix:** Landed `.github/copilot-instructions.md`, `Copilot/Algorithm.md`, `Copilot/ContextRouting.md`, `Copilot/install.sh`, and `Copilot/README.md` as one coordinated Phase 1 change, and updated `tasks/todo.md` with an explicit Phase 1 status note.

**Rule:** When a migration milestone depends on support docs, installer behavior, and status docs, update all three in the same change. Do not mark a phase complete in README or todo tracking until the support files exist and the installer actually ships them.


### Lesson 8: Skills that generate runtime artifacts need installer-backed destinations

**What happened:** Porting `CreateCLI` mechanically rewrote `~/.claude/Bin/...` to `~/.pai/Bin/...`, but that new runtime destination only becomes real if the installer creates it. Without that, the skill would advertise a path that doesn't exist in fresh installs.

**Fix:** Updated `Copilot/install.sh` to create `~/.pai/Bin/` and `~/.pai/USER/SKILLCUSTOMIZATIONS/`, and updated the migration status docs to reflect the new runtime layout.

**Rule:** When porting a skill that writes files to a runtime path, create that path in the installer during the same change. Do not rely on documentation-only path rewrites for generated artifacts.


## Session: 2026-04-20 — Phase 3 memory system adaptation

### Lesson 9: Startup readback must be deterministic, not instruction-only

**What happened:** Initial plan had the AI running `learning-readback.sh` at session start via an instruction rule. Rubber-duck critique pointed out that if the AI forgets, the entire memory system feels broken.

**Fix:** Made the sidecar wrapper materialise `startup-digest.md` *before* Copilot starts, so the instruction file just reads a static file. Instruction-based invocation remains as fallback.

**Rule:** For any session-start behavior that is foundational (context loading, memory readback), materialise the result into a file during the sidecar pre-session phase rather than relying solely on AI instruction compliance.

### Lesson 10: Use python3 for JSON serialisation in bash scripts

**What happened:** Rating capture needs to write JSON lines. Shell-only JSON escaping (`printf`, `jq`) is fragile with special characters in user comments and summaries.

**Fix:** Used inline `python3 -c "import json; ..."` for reliable JSON serialisation. Python 3 is ubiquitous on macOS and Linux.

**Rule:** When a bash tool needs to produce structured data (JSON, YAML), delegate serialisation to `python3 -c` rather than hand-rolling escape sequences in shell.


## Session: 2026-04-20 — T3 skills live-test

### Lesson 11: Mechanical skill ports carry stale path references

**What happened:** Live-testing the 5 T3 skills (Aphorisms, PAIUpgrade, Prompting, Evals, Fabric) surfaced 3 systemic path bugs left by the batch substitution port: `~/.pai/PAI/USER/` (31 files, upstream's `.claude/PAI/USER/` collapsed wrong), `~/.pai/skills/Utilities/` (17 files, upstream had a `Utilities/` wrapper that the port flattened), and `~/.pai/skills/aphorisms/` (5 files, lowercase vs capital `A`). Only Aphorisms and Fabric worked out of the box; Prompting, Evals, and PAIUpgrade were non-functional.

**Fix:** Three trivial global seds clear most of the damage; see `~/.pai/MEMORY/WORK/20260420T135254Z_t3-skills-live-test/GAPS.md` for the enumerated fixes.

**Rule:** After any mechanical batch port of skills, grep the ported tree for every installed path token (e.g. `~/.pai/PAI/`, `skills/Utilities/`, lowercase/wrong-case variants of every skill name) and run a live smoke test of at least one workflow per skill before declaring the milestone done. Path-only sed is insufficient — the substitution rules need to know both the *source* layout and the *destination* layout.

### Lesson 12: Workflows that consume hook-generated data break silently when hooks are dropped

**What happened:** PAIUpgrade's `MineReflections` workflow expects `~/.pai/MEMORY/LEARNING/REFLECTIONS/algorithm-reflections.jsonl`. That file was produced by a Claude Code hook in upstream PAI, and the hook was dropped in Phase 4 of this port. The workflow was carried forward verbatim and is now unable to execute — there is no data to mine.

**Fix:** Either extend `capture-work-learning.sh` to emit structured JSONL alongside its markdown output, or rewrite `MineReflections` to consume the markdown files directly under `ALGORITHM/`, `FAILURES/`, `SYSTEM/`.

**Rule:** When dropping a hook in a migration, audit every skill/workflow that references the hook's output path. Either port the hook's data-generation logic (to a script or an instruction) or rewrite the downstream workflow to use the new data shape. Don't carry forward workflows whose inputs no longer exist.

### Lesson 13: TypeScript skill tools need per-skill `package.json` + installer `bun install`

**What happened:** `Prompting/Tools/RenderTemplate.ts` imports `handlebars` and `yaml` but the installed `~/.pai/skills/Prompting/` has no `package.json` and no `node_modules/`. `bun run` fails with a missing-package error. The installer was never extended to set up per-skill npm dependencies.

**Fix:** Add `package.json` to the skill source, and teach `Copilot/install.sh` to run `bun install` inside any `~/.pai/skills/*/` that has a `package.json` (Telos already has two — the pattern exists but isn't automated).

**Rule:** Any TypeScript tool in a skill that imports third-party packages must ship with a `package.json` alongside it, and the installer must run `bun install` in every skill dir that has one. Document this in `Copilot/skills/PORTING_NOTES.md` as a port acceptance criterion.
