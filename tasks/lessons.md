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
