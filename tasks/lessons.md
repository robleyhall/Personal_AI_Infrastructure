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
