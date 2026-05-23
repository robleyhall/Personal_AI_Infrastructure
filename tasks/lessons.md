# Lessons Learned — PAI Copilot Migration

> **Purpose:** Patterns, rules, and discoveries to prevent repeated mistakes and preserve institutional knowledge. Review at session start.

---

## Session: 2026-05-14 — Active project source check

### Lesson: Active projects live in TELOS, not active.md

**What happened:** A request for active projects showed that `~/.pai/MEMORY/WORK/active.md` only records the current/last PAI work marker, while the durable project registry lives in `~/.pai/USER/TELOS/PROJECTS.md`.

**Rule:** For "what projects are active?" answer from `TELOS/PROJECTS.md`; use `MEMORY/WORK/active.md` only as the current-session work marker.

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

---

## Session: 2026-04-22 — PAI startup indicator

### Lesson: Don't default the PAI status line — actually check the env var

**What happened:** On first turn of a PAI session, emitted `⚪ PAI inactive` even though `PAI_SESSION_ID`, `PAI_DIR`, and `PAI_VOICE_URL` were all set in the environment. User caught it from the screenshot. The instruction in `~/.copilot/copilot-instructions.md` § "PAI startup indicator" is explicit about checking `PAI_SESSION_ID`; the model skipped the check and defaulted to inactive.

**Fix:** On the first response of any session, verify `PAI_SESSION_ID` with a real tool call (`echo "$PAI_SESSION_ID"` via bash, or equivalent) *before* emitting the status line. Do not rely on the `<environment_context>` block or memory — neither surfaces `PAI_SESSION_ID`.

**Rule:** The PAI startup indicator is a verification step, not a vibe check. First turn of every session: run `bash: echo "PAI_SESSION_ID=[${PAI_SESSION_ID}]"` (or fold it into another needed first-turn command), then emit `🧠 PAI active · session <id>` if non-empty, else `⚪ PAI inactive`. Never emit the line before the check.

### Lesson: Instruction-based context loading is insufficient when files live outside cwd

**What happened:** The PAI startup readback routinely came back partial in earlier sessions — `ABOUTME.md`, `DAIDENTITY.md`, `AISTEERINGRULES.md`, `latest.md`, and `active.md` were empty or unreadable even though the sidecar had materialised `startup-digest.md` pre-session. Cause: Copilot CLI's default file-access scope is the cwd (and the session workspace). Anything under `~/.pai/` requires explicit allowlisting, or the AI either silently returns empty content or triggers per-session `/add-dir` prompts. Instruction rules alone ("read these files at startup") could not bridge that gap. Today's session confirmed the fix: launching Copilot as `copilot --add-dir "$PAI_DIR" "$@"` inside `~/.pai/sidecar/pai-copilot` made the full readback work end-to-end for the first time.

**Fix:** The sidecar now unconditionally passes `--add-dir "$PAI_DIR"` to `copilot`. The repo copy (`Copilot/sidecar/pai-copilot`) was updated to match, and `Copilot/README.md` and `Copilot/ContextRouting.md` document why the flag is load-bearing.

**Rule:** For any PAI session-start behavior that depends on reading files outside the cwd (user identity, steering rules, relationship memory, active work, startup digest), the sidecar must add those paths to Copilot's file-access allowlist at process start via `--add-dir`. Do not rely solely on instruction-file rules or pre-session file materialisation — both still require the AI to *read* the file mid-session, and reads outside the allowlist fail quietly. When adding a new PAI directory that the AI must read in-session, either place it under `$PAI_DIR` (already allowlisted) or extend the sidecar's `--add-dir` arguments.

## Session: 2026-04-22 — Lesson 11 cleanup (resolved)

### Lesson: Full `~/.pai/PAI/USER/` cleanup completed

**What happened:** The path bug from Lesson 11 was still live across ~65 files (32 repo source + 33 installed tree) and had misplaced the entire TELOS directory. Robley spotted both `~/.pai/USER/` and `~/.pai/PAI/USER/` coexisting during a Tier 2 TELOS session.

**Fix:** Moved `~/.pai/PAI/USER/TELOS` → `~/.pai/USER/TELOS`, removed empty `~/.pai/PAI/`, and ran a plain-string sed replacing `~/.pai/PAI/USER/` with `~/.pai/USER/` across every non-memory file in both the repo (`Copilot/skills/`) and the installed tree (`~/.pai/skills/` + `~/.pai/USER/ABOUTME.md`). Memory files (MEMORY/LEARNING, RELATIONSHIP, WORK/GAPS) intentionally left alone — they record the bug as history.

**Rule:** Lesson 11 is closed for the `PAI/USER/` collapse. Remaining lesson-11-adjacent issues — phantom root-level paths like `~/.pai/PAI/SKILL.md`, `~/.pai/PAI/Tools/...`, `~/.pai/PAI/Prompting.md` — are a *different* bug and tracked in `~/.pai/MEMORY/WORK/active.md` under "Phantom-PAI-root cleanup."

---

## Session: 2026-04-22 — Copilot Audit Phase 1 research

### Lesson 16: Research memory protocol had a duplicate-artifact trap

**What happened:** Ran Phase 1 of the Copilot Environment Audit. Followed § 9 of the global instructions literally — "save the full artifact under `~/.pai/MEMORY/RESEARCH/...`" — and wrote a 22KB REPORT.md into a `<UTCtimestamp>_<slug>/` dir. Then ran `save-research-memory.sh` as the same § 9 prescribes, which created its **own** `YYYY-MM/YYYY-MM-DD_slug/` dir with SUMMARY.md + WHAT_MATTERS.md. Result: two directories for one research run, with `latest.md` pointing only at the script's dir — the 22KB report was orphaned and invisible. The script also silently appended a "Research Snapshot" block to `active.md`, duplicating the curated queued entry and violating the § 14 single-block rule.

**Fix:**
- Canonical layout is *one dir per research run*, created by the script: `~/.pai/MEMORY/RESEARCH/YYYY-MM/YYYY-MM-DD_slug/` containing `REPORT.md` (full), `SUMMARY.md`, `WHAT_MATTERS.md`.
- Added `--artifact <path>` flag to `save-research-memory.sh` so the full report is copied into the canonical dir as `REPORT.md` in one call.
- Removed the script's append-to-`active.md` behavior — `active.md` is hand-curated, not machine-appended.
- `latest.md` now surfaces `Full report`, `What matters`, and `Summary` paths.
- Rewrote § 9 in `.github/copilot-instructions.md` to reflect reality: compose the full artifact to a tempfile, then invoke the script once with `--artifact`; the script is the single writer for the research dir.

**Rule:** There is exactly one writer for `~/.pai/MEMORY/RESEARCH/` — `save-research-memory.sh`. Never hand-write a sibling directory next to it. For any research of meaningful size, pass `--artifact <tempfile>` so the full report lives in the same dir as the digest. Never append to `active.md` from a script — that file is curated by hand per § 14.

**Commit:** (pending)

---

## Session: 2026-04-22 PM — Cross-session engagement tracking

### Lesson 17: `grep -c` with `|| echo 0` produces `0\n0` on no-match

**What happened:** In `capture_engagement()` I wrote `c="$(grep -cE '...' file 2>/dev/null || echo 0)"`, then `open_todos=$((open_todos + c))`. When the file existed but had zero matches, `grep -c` exited 1 (per spec) *and* printed "0"; the fallback `echo 0` then printed another "0", leaving `c="0\n0"`. Arithmetic expansion on that failed and aborted the capture function under `set -u` in the subshell test harness.

**Fix:** `c="$(grep -cE '...' file 2>/dev/null)" || c=0` plus a regex guard `[[ "$c" =~ ^[0-9]+$ ]] || c=0`. `grep -c` already emits the count on stdout; the fallback is only needed when the command itself errors (e.g. missing file).

**Rule:** Never use `|| echo <value>` as an exit-code fallback for a command that already prints to stdout. Use `|| VAR=<value>` to set the variable *after* the failed assignment, and validate the captured value before arithmetic.

**Commit:** (pending)

### Lesson 18: `install.sh --delete` is unsafe during in-flight state changes

**What happened:** `Copilot/install.sh` uses `rsync -a --delete` for `sidecar/` and `tools/` to guarantee a clean install. Mid-session, running install.sh would nuke any uncommitted state under `~/.pai/` (e.g., newly-created `MEMORY/WORK/projects/engagement.jsonl` that the repo doesn't track).

**Fix:** For incremental changes during a session, sync only the specific touched files (`rsync -a Copilot/sidecar/pai-copilot ~/.pai/sidecar/pai-copilot`, etc.) rather than running the full installer.

**Rule:** `install.sh` is for a clean install or controlled upgrade — never run it mid-session. When you've edited files in `Copilot/sidecar/` or `Copilot/tools/` and need them active, rsync the specific files. Save the full install for a post-commit verification pass.

**Commit:** (pending)

---

## Session: 2026-04-23 — Tier 1 upstream PAI port

### Lesson 19: Port banners alone do not document divergence — need a PORTING_NOTES ledger

**What happened:** After completing a Tier 1 port of 19 SYSTEM docs + 14 agent profiles + STATE tree from upstream v4.0.3, every ported file had a port banner at top citing upstream + path rewrites. I considered the record complete. It wasn't — `Copilot/skills/PORTING_NOTES.md` only covered skill-level mechanical ports. There was no single place that documented **which upstream files were intentionally NOT ported** (`PAI/README.md`, `PAI/SKILL.md`, `PAI/Tools/`, `PAI/USER/`), or the architectural choice to use the `Copilot/PAI/` subnamespace instead of a flat layout. Future maintainers (including future-me) pulling upstream would have to reverse-engineer those decisions.

**Fix:** Added a repo-root `Copilot/PORTING_NOTES.md` documenting: upstream baseline version, substitution rules, blanket "not ported" list (hooks, statusline, settings.json, installer), and a Tier 1 section enumerating intentional exclusions, design choices, and commit refs. Cross-linked with `Copilot/skills/PORTING_NOTES.md`.

**Rule:** Every mechanical port lands **three things**, not two:
1. Per-file port banner citing upstream version + rewrites
2. Entry in `Copilot/PORTING_NOTES.md` (platform) or `Copilot/skills/PORTING_NOTES.md` (skill), naming **intentional exclusions** and **design divergences**
3. Commit refs in the notes so the port is reconstructable from git history

If something was deliberately skipped from upstream, write it down. Silent omissions become phantom refs later.

**Commit:** `6391184`

### Lesson 20: Use `rsync` of specific files, never `install.sh`, to activate mid-session ports

**What happened:** After porting 19 docs + 14 agent profiles into `Copilot/PAI/` and `Copilot/agents/`, I needed them live under `~/.pai/` so this session (and the next) could actually reach them. Running `install.sh` was tempting — it's the "canonical" installer — but I avoided it.

**Fix:** `rsync -a Copilot/PAI/ ~/.pai/PAI/ && rsync -a Copilot/agents/ ~/.pai/agents/`. Specific dirs, no `--delete`, preserves everything else under `~/.pai/`.

**Rule:** Reinforces Lesson 18. `install.sh --delete` is for clean installs only. Any mid-session activation of newly-ported content = targeted `rsync -a` of just the changed paths. For agent dirs that don't exist yet under `~/.pai/`, `rsync` creates them safely. Never run the full installer to "just pick up" an incremental change.

**Commit:** part of `134c93c` + `339c29e` workflow

## Session: 2026-04-26 — Memory boundary work

### Lesson 21: Verify PKM structure live before quoting plan docs as current state

**What happened:** While drafting `tasks/memory-boundary-decision.md`, I cited `80_Wiki/` as the wiki location based on `~/projects/mini-ak-wiki/integrated-pkm-plan.md` (a 2026-04-22 *proposal*). Reality: the wiki actually lives at `10_Knowledge/wiki/` — already correctly placed inside PARA. Robley caught the error: a top-level `80_Wiki/` would have diluted PARA structure. The proposal had been superseded in practice but the doc still reads as if it's current.

**Fix:** Verified live with `ls`, corrected Decision 5 in the boundary doc, flipped recommendation from "collapse" to "keep workflow in place," updated approval matrix and follow-on steps.

**Rule:** Treat every `~/projects/.../plan.md` or `integrated-*.md` as a *historical proposal* until proven otherwise. Before quoting a path, directory layout, or convention from a plan doc, verify with `ls` against the actual filesystem (or `devonthink-stdio-search` against the actual DT database). Plan docs are not source-of-truth for current state. Source-of-truth is the live system.

**Commit:** to be tagged with the Tier-A memory-incorporation work that follows this lesson.

---

## Session: 2026-05-21 — X post save workflow standardization

### Lesson 22: Standardize X-post PKM saves on `save_x_content.sh`

**What happened:** A request to save an X post initially drifted through public oEmbed, raw X HTML, web search, and ad hoc X API attempts before Robley pointed to the working script in `../youtube-transcript-archiver/save_x_content.sh`. That script successfully handled the X Article redirect, generated source and `extract_wisdom` artifacts, and provided the material for the Career PKM note.

**Fix:** Added `SaveXPostToPKM` to the Parser skill in both repo-local and installed copies. It names `/Users/robley/projects/youtube-transcript-archiver/save_x_content.sh` as the standard tool, documents expected X Article redirect behavior, and records the Careers PKM destination.

**Rule:** For "save this X post" or "save this X post to PKM", use the Parser `SaveXPostToPKM` workflow first. Do not start with oEmbed, raw X HTML, Nitter, web search, or ad hoc GraphQL unless the standard script fails. Treat "xurl" as historical shorthand for the same successful capture path, not as a separate tool to rediscover.

### Lesson 23: `pai` sidecar file access is not instruction loading

**What happened:** `pai` sessions launched outside `Personal_AI_Infrastructure` showed sidecar activity in logs but did not show PAI mode headers. The wrapper was running and passing `--add-dir ~/.pai`, but the PAI instruction contract lived only in the repo-local `.github/copilot-instructions.md`, so other directories did not load it.

**Fix:** The sidecar now exports `COPILOT_CUSTOM_INSTRUCTIONS_DIRS="$PAI_DIR/instructions"` before launching Copilot. The installed runtime contains the full PAI instruction contract at `~/.pai/instructions/AGENTS.md` and `~/.pai/instructions/.github/copilot-instructions.md`; the installer recreates those files from the repo-local PAI instructions.

**Rule:** Do not equate `--add-dir ~/.pai` with PAI being active. `--add-dir` only allows file access. PAI behavior requires a loaded instruction file, either repo-local or through `COPILOT_CUSTOM_INSTRUCTIONS_DIRS`.
