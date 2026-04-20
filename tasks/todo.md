# PAI → Copilot CLI Migration: Evaluation & Plan

## How You Interact With PAI (The User Experience)

### Installation & Setup

You clone the repo, copy the `.claude/` directory to `~/.claude/`, and run `install.sh`. A GUI installer (Bun-powered) walks you through: your name, your AI assistant's name, timezone, temperature units, optional ElevenLabs voice setup. It installs prerequisites (Bun, Git, Claude Code), configures everything, and sets up a `pai` shell alias. After install you run `source ~/.zshrc && pai` to launch.

### Day-to-Day Usage

You open a terminal and type `pai` (which launches Claude Code with the PAI context). From there, it's a conversation — but PAI is **not** a generic chatbot. Here's what happens:

**1. Session Start (automatic, invisible to you):**
- Claude Code loads `CLAUDE.md` (the master instruction file) automatically
- A `SessionStart` hook fires, which:
  - Loads your personal context (ABOUTME.md, DAIDENTITY.md, active projects)
  - Loads relationship memory (how you've interacted recently)
  - Loads recent learnings (what went well/poorly in recent sessions)
  - Sets the terminal tab title
  - Persists environment variables for Kitty terminal
- Your AI assistant greets you **by the name and personality you configured** (e.g., "Hey Daniel, it's Tessa")

**2. You make a request:**

Every request gets classified into one of three modes:

- **MINIMAL** — Greetings, ratings, acknowledgments → short formatted response
- **NATIVE** — Simple, quick tasks → structured but fast execution
- **ALGORITHM** — Anything complex → the full 7-phase Algorithm kicks in

**3. The Algorithm (the core experience for non-trivial work):**

When you ask for something substantial — "research quantum computing trends", "build me a CLI tool", "analyze this company" — PAI enters **Algorithm Mode**. This is the signature experience:

```
Phase 1: OBSERVE  — Reads context, understands current state
Phase 2: THINK    — Analyzes the problem, considers approaches
Phase 3: PLAN     — Creates Ideal State Criteria (ISC) — specific, testable success criteria
Phase 4: BUILD    — Creates artifacts (code, docs, analysis)
Phase 5: EXECUTE  — Runs the artifacts (tests, deploys, etc.)
Phase 6: VERIFY   — Checks each ISC criterion passes
Phase 7: LEARN    — Captures what worked, what didn't, updates memory
```

At **every phase transition**, your AI announces it out loud via ElevenLabs TTS: *"Entering the observe phase."* You hear your AI working.

The Algorithm writes a **PRD (Product Requirements Document)** to `~/.claude/MEMORY/WORK/` as a persistent artifact. ISC criteria are checkboxes that get checked off as they're verified.

**4. Skills get invoked automatically:**

Based on your request, PAI selects from **25 capabilities** across 49 skills:

- Say "research this topic" → triggers the **Research** skill (multi-agent, parallel research with Quick/Standard/Extensive/Deep modes)
- Say "investigate this company" → triggers the **Investigation** skill (OSINT, company intel, domain lookup)
- Say "create an image of..." → triggers the **Media/Art** skill
- Say "what are my goals?" → triggers the **Telos** skill (reads your MISSION.md, GOALS.md, etc.)
- Say "analyze this video" → triggers **ContentAnalysis** (YouTube transcript extraction + wisdom extraction)
- Say "think about this differently" → triggers **FirstPrinciples** or **Council** (multi-agent debate)

Skills are invoked via the `Skill` tool — not slash commands. The AI reads the skill's `SKILL.md`, follows its workflow, and uses its tools.

**5. You can rate responses:**

After any response, you can say "7" or "rate: 8" and PAI captures it. Ratings 1-3 trigger a **failure capture** — full context dump with transcript, sentiment analysis, and tool calls saved to `MEMORY/LEARNING/FAILURES/`. This feeds the learning loop.

**6. Voice notifications throughout:**

- Task completions are spoken aloud
- Long-running tasks announce progress
- The voice server runs at `localhost:8888` and PAI hits it via curl

**7. Terminal integration:**

- Tab titles update dynamically with current task context
- A statusline shows learning signals, context usage, and task state
- Multiple panes for parallel work

### The Autonomous Mode (Algorithm CLI)

Beyond interactive use, you can run PAI autonomously:

```bash
# Give it a PRD and let it loop until all criteria pass
bun ~/.claude/PAI/Tools/algorithm.ts -m loop -p my-prd.md -n 20

# Run with 4 parallel agents
bun ~/.claude/PAI/Tools/algorithm.ts -m loop -p my-prd.md -n 20 -a 4
```

This spawns Claude Code sessions in a loop, each one reading the PRD, working on failing criteria, updating checkboxes, and repeating until done. No human needed.

### The Personal Context Layer

What makes PAI personal is the `USER/` directory:

| File | What It Does |
|---|---|
| `ABOUTME.md` | Who you are, your background, expertise, interests |
| `DAIDENTITY.md` | Your AI's name, personality, voice |
| `WRITINGSTYLE.md` | How you like things written |
| `AISTEERINGRULES.md` | Personal behavior rules for your AI |
| `OPINIONS.md` | Your preferences and opinions |
| `TELOS/` | Your life goals: MISSION.md, GOALS.md, BELIEFS.md, PROJECTS.md, etc. |
| `PROJECTS/` | Active project registry |
| `BUSINESS/` | Business context, media kits, templates |
| `SKILLCUSTOMIZATIONS/` | Per-skill preference overrides |

All of this loads at session start or on-demand via the context routing table. Your AI knows you.

### The Memory Loop

Every interaction generates signals that feed back:
- **Ratings** → `MEMORY/LEARNING/SIGNALS/ratings.jsonl`
- **Work artifacts** → `MEMORY/WORK/{timestamp}_{slug}/PRD.md`
- **Learnings** → `MEMORY/LEARNING/SYSTEM/` and `ALGORITHM/`
- **Failures** → `MEMORY/LEARNING/FAILURES/` (full context dumps)
- **Reflections** → `MEMORY/LEARNING/REFLECTIONS/`
- **Relationship patterns** → `MEMORY/RELATIONSHIP/`

A periodic harvester extracts patterns from session transcripts. Weekly synthesis aggregates ratings. The system literally gets better at helping *you* over time.

### Packs (Standalone Installation)

Don't want the full system? Install individual packs:

```
"Install the Research pack from PAI/Packs/Research/"
```

Your AI reads the pack's INSTALL.md and walks through a 5-phase wizard. Each pack is self-contained with its own skills, tools, and workflows.

---

## What Cannot Be Migrated Directly

This section catalogs every PAI feature that **does not have a direct Copilot CLI equivalent**, organized by severity.

### 🔴 No Equivalent — Must Be Redesigned or Dropped

#### 1. The Hook System (20 hooks, 6 Claude Code event types)

##### What Is a Hook?

A **hook** is a script that runs automatically when a specific event happens — you don't trigger it, the system does. Think of it like a doorbell camera: you don't press a button to start recording, it triggers *automatically* when someone walks up.

In Claude Code, there are 6 events that can trigger hooks:

| Event | When It Fires | Analogy |
|---|---|---|
| **SessionStart** | You launch `pai` | "The lights turn on when you walk in the door" |
| **UserPromptSubmit** | You press Enter on a message | "A receipt prints every time you place an order" |
| **PreToolUse** | Right before the AI runs a tool (bash, file edit, etc.) | "A security guard checks your badge before you enter a room" |
| **PostToolUse** | Right after a tool finishes | "An audit log entry is written after every transaction" |
| **Stop** | The AI finishes responding | "A summary is read aloud after every meeting ends" |
| **SessionEnd** | You close the session | "Your timesheet auto-submits when you clock out" |

PAI attaches **20 scripts** to these events. They run silently in the background — you never see them, but they're doing critical work. For example:

- **When you launch PAI** → a hook automatically loads your personal context, recent learnings, and active projects into the conversation. That's why the AI "knows you" immediately.
- **When you type "7"** → a hook detects that's a rating, records it to a file, and if it's low, captures the full conversation for analysis.
- **When the AI finishes responding** → a hook extracts the voice line and sends it to the speaker. Another hook extracts relationship notes and writes them to your memory file.
- **When you close the session** → a hook captures what was learned and what files changed.

**Why this is the biggest migration gap:** Copilot CLI has no hook system. There's no way to say "run this script every time the user sends a message" or "run this script when the AI finishes responding." All 20 of these automatic behaviors either need a completely different approach or get dropped.

##### Are We Blocked? No — Here Are the Workarounds

**We are not blocked.** There are three workaround strategies, and most hooks can be handled by one of them:

**Strategy A: "Bake it into the instructions"**

Instead of an automatic script, you tell the AI in copilot-instructions.md: *"Always do X when Y happens."* The AI follows the instruction as part of its normal behavior — no hook needed.

| Hook | Instruction-Based Workaround | Reliability |
|---|---|---|
| **LoadContext** | "At session start, read `~/.pai/USER/ABOUTME.md`, `~/.pai/MEMORY/LEARNING/latest.md`, and `~/.pai/MEMORY/WORK/active.md` before doing anything else." | ⭐⭐⭐⭐ High — this is exactly what your current copilot-instructions.md already does with `tasks/todo.md` and `tasks/lessons.md` |
| **RatingCapture** | "When the user sends a number 1-10, treat it as a satisfaction rating. Run `bun ~/.pai/tools/capture-rating.ts <rating> <session-summary>`." | ⭐⭐⭐ Good — AI reliably recognizes rating patterns |
| **VoiceCompletion** | "At the end of every response, run `curl -s -X POST http://localhost:8888/notify -d '{"message": "<your summary>"}'`" | ⭐⭐⭐ Good — PAI already does this inline in the Algorithm, not just via hooks |
| **RelationshipMemory** | "At the end of significant sessions, append relationship notes to `~/.pai/MEMORY/RELATIONSHIP/today.md`" | ⭐⭐ Moderate — AI may forget on short sessions |
| **SecurityValidator** | "Never modify files in `~/.pai/PAI/`, never run `rm -rf`, never read `~/.ssh/*`" — put the rules in instructions | ⭐⭐⭐⭐ High — Copilot CLI also has its own built-in safety |
| **WorkCompletionLearning** | "Before ending a session, capture what was learned to `~/.pai/MEMORY/LEARNING/`" — same as your current "save state and shutdown" ritual | ⭐⭐⭐⭐ High — you already do this pattern |

**Key insight:** Your current `copilot-instructions.md` already uses this pattern successfully. The "Session Startup" and "Session Shutdown" sections are instruction-based hooks — they tell the AI "when you start, read these files" and "when told to shut down, commit and push." That's the same concept.

**Strategy B: "Wrapper script"**

A shell script that runs *before* and *after* launching Copilot CLI. This handles things that need to happen outside the AI conversation.

```bash
#!/bin/bash
# pai-copilot wrapper

# === PRE-SESSION (replaces SessionStart hooks) ===
# Set terminal tab title
echo -ne "\033]0;PAI Session\007"
# Start voice server if not running
pgrep -f "voice-server" || bun ~/.pai/VoiceServer/server.ts &
# Export env vars
export PAI_DIR="$HOME/.pai"

# === LAUNCH COPILOT ===
copilot "$@"

# === POST-SESSION (replaces SessionEnd hooks) ===
# Capture session end timestamp
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) session_end" >> ~/.pai/MEMORY/STATE/sessions.log
# Run learning capture
bun ~/.pai/tools/post-session-capture.ts
# Reset tab title
echo -ne "\033]0;Terminal\007"
```

This handles: KittyEnvPersist, voice server startup, session cleanup, and post-session learning capture — all without hooks.

**Strategy C: "Accept the loss"**

Some hooks are nice-to-have and not worth replicating:

- Tab title management (5 hooks) → Drop. Just use a static title from the wrapper.
- SessionAutoName → Drop. Sessions are managed differently in Copilot CLI.
- AgentExecutionGuard → Drop. Behavioral nudge, not critical.
- DocIntegrity → Drop. Run manually when needed.
- UpdateCounts → Drop. Analytics, not user-facing.

##### Workaround Summary

| Critical Hook | Strategy | What Changes for the User |
|---|---|---|
| **LoadContext** | A (instructions) | Nothing — AI still "knows you" at session start |
| **RatingCapture** | A (instructions) | Same behavior — say "7" and it gets captured |
| **VoiceCompletion** | A (instructions) | Same behavior — AI curls the voice server inline |
| **RelationshipMemory** | A (instructions) + B (wrapper post-script) | Slightly less reliable — AI may miss some sessions |
| **WorkCompletionLearning** | A (instructions) + B (wrapper post-script) | Works via "save state" ritual you already use |
| **SecurityValidator** | A (instructions) + Copilot built-in safety | Slightly less granular, but functional |
| 14 other hooks | C (drop) | Lose tab titles, analytics, auto-naming. Cosmetic only. |

**Bottom line:** The 6 critical hooks all have viable workarounds. The user experience is ~90% preserved. The main trade-off is that instruction-based "hooks" depend on the AI following rules rather than deterministic scripts — so occasionally it might forget to capture a rating or relationship note. But the core experience of "an AI that knows you, learns, and speaks" survives.

**Hooks by event type and what they do:**

| Event | Hook | What It Does | Impact of Losing It |
|---|---|---|---|
| **SessionStart** | `LoadContext.hook.ts` | Force-loads personal context, relationship memory, learning readback, active work summary into every session | **CRITICAL** — Without this, PAI doesn't "know you" at session start. Your AI starts cold every time. |
| **SessionStart** | `KittyEnvPersist.hook.ts` | Persists env vars for Kitty terminal | Low — terminal cosmetic |
| **UserPromptSubmit** | `RatingCapture.hook.ts` | Detects "7" or sentiment in your prompt, runs Haiku inference for implicit sentiment, writes to ratings.jsonl, captures full failure dumps for ratings ≤3 | **HIGH** — The learning loop depends on this. Without it, PAI can't learn from your satisfaction signals. |
| **UserPromptSubmit** | `SessionAutoName.hook.ts` | Generates 4-word session name from first prompt, upgrades via inference | Medium — session identification |
| **UserPromptSubmit** | `UpdateTabTitle.hook.ts` | Sets terminal tab title with gerund-form task description, announces via voice | Medium — terminal cosmetic + voice |
| **UserPromptSubmit** | `UpdateCounts.hook.ts` | Tracks prompt/response counts | Low — analytics |
| **PreToolUse** | `SecurityValidator.hook.ts` | Validates bash commands and file paths against security patterns before execution, blocks dangerous operations | **HIGH** — Copilot CLI has its own safety, but PAI's custom patterns (protected files, confirm-writes) are lost |
| **PreToolUse** | `SkillGuard.hook.ts` | Blocks false-positive skill invocations (position-bias bug workaround) | N/A — Copilot has different skill system |
| **PreToolUse** | `AgentExecutionGuard.hook.ts` | Warns when Task tool is called without background flag | Low — behavioral nudge |
| **PostToolUse** | `PRDSync.hook.ts` | Syncs PRD frontmatter + criteria to work.json after every Write/Edit of PRD.md | Medium — dashboard data pipeline |
| **Stop** | `VoiceCompletion.hook.ts` | Extracts 🗣️ voice line from response, sends to ElevenLabs TTS server | **HIGH** — Signature UX feature. PAI "speaks" to you. |
| **Stop** | `LastResponseCache.hook.ts` | Caches last response text for RatingCapture to reference | Medium — supports rating system |
| **Stop** | `RelationshipMemory.hook.ts` | AI inference extracts relationship notes (World/Biographical/Opinion) from transcript, writes to daily log | **HIGH** — The "PAI knows you" experience depends on this compounding over time |
| **Stop** | `DocIntegrity.hook.ts` | Checks doc cross-references if system files were modified | Low — maintenance |
| **Stop** | `ResponseTabReset.hook.ts` | Resets tab to neutral state after response | Low — terminal cosmetic |
| **Stop** | `SetQuestionTab.hook.ts` | Sets tab title when AI asks a question | Low — terminal cosmetic |
| **SessionEnd** | `WorkCompletionLearning.hook.ts` | Captures files changed, tools used, ISC criteria into learning files | **HIGH** — Cross-session knowledge compound |
| **SessionEnd** | `SessionCleanup.hook.ts` | Cleans up session state files | Low — housekeeping |
| **SessionEnd** | `IntegrityCheck.hook.ts` | Detects PAI system file changes, spawns maintenance | Low — self-maintenance |
| **SessionEnd** | `QuestionAnswered.hook.ts` | Tracks whether AI questions were answered | Low — analytics |

**Summary:** 6 hooks are CRITICAL/HIGH — they power the core PAI differentiators (knowing you, learning, speaking). The other 14 are cosmetic, maintenance, or analytics.

#### 2. Inference.ts (AI-in-hooks via Claude CLI subprocess)

Several hooks call `Inference.ts`, which spawns a `claude -p "prompt"` subprocess for AI reasoning (e.g., sentiment analysis, session naming, relationship extraction). This uses **Claude's own CLI** as an inference engine.

**Why it can't migrate directly:** Copilot CLI doesn't expose a `copilot -p "prompt"` subprocess for scripted AI calls. Hooks that need AI reasoning (RatingCapture, SessionAutoName, RelationshipMemory, UpdateTabTitle) would need an alternative inference backend.

**Workaround: Replace with direct API calls or drop.**

Only 4 hooks actually use `Inference.ts`:
- `RatingCapture.hook.ts` — implicit sentiment detection (AI classifies "ugh, not what I wanted" as a low rating)
- `SessionAutoName.hook.ts` — generates a 4-word session name
- `UpdateTabTitle.hook.ts` — generates a gerund-form task description
- `DocCrossRefIntegrity.ts` — checks doc cross-references

Since we're moving hooks to instruction-based rules (Strategy A), **most of these don't need a subprocess at all:**

| Hook | With Inference.ts | Without (Copilot workaround) |
|---|---|---|
| **RatingCapture** | AI detects implicit sentiment ("ugh" → low rating) | Only capture **explicit** ratings (user says "7"). Drop implicit sentiment. ~80% of value preserved. |
| **SessionAutoName** | AI generates clever 4-word title | Drop entirely — Copilot CLI manages sessions differently |
| **UpdateTabTitle** | AI generates gerund task description | Set a static title from the wrapper script, or drop |
| **DocIntegrity** | AI checks doc cross-refs | Run manually with `bun` when needed |

**If you want implicit sentiment back later**, you could replace `Inference.ts` with a direct Anthropic API call (`curl` to `api.anthropic.com`) using an API key. But it's not essential — explicit ratings ("7") capture 80%+ of the signal.

**Verdict: Not blocked.** Drop implicit sentiment, keep explicit ratings via instruction-based rule.

#### 3. The `Skill` Tool (Claude Code built-in)

Claude Code has a native `Skill` tool that routes to skill definitions. PAI uses it extensively — "Skill('Research')", "Skill('FirstPrinciples')", etc. The AI is instructed to invoke skills via this tool.

**Copilot CLI equivalent:** There is a `skill` tool, but it's limited to a predefined set of available skills (currently only `customize-cloud-agent`). There's no way to register custom skills that the AI can invoke via tool call. PAI's 49 skills would need to be invoked through natural language instructions ("read the skill file at this path and follow its workflow") rather than a tool call.

**Workaround: Instruction-based skill routing.**

PAI skills are ultimately just **markdown files** (`SKILL.md`) that tell the AI what to do. The `Skill` tool is a convenient trigger, but the actual work is: (1) read the SKILL.md, (2) follow its workflow. The AI can do this without a special tool.

**In the instruction file, replace:**
```
When user says "research X" → invoke Skill('Research')
```

**With:**
```
When user says "research X" → read ~/.pai/skills/Research/SKILL.md and follow its workflow
```

The AI already does this naturally — when it reads a SKILL.md, it understands the instructions and executes them. The `Skill` tool was just a routing shortcut.

**What's lost:**
- The **formal tool call** that makes skill invocation visible and trackable in transcripts
- The **SkillGuard hook** that blocks false-positive invocations (but that's solving a Claude Code-specific bug)
- **Skill discovery** — Claude Code lists available skills in the system prompt. In Copilot, the instruction file would need a skill index.

**What's preserved:**
- All 49 skill workflows (they're markdown — fully portable)
- All skill tools (TypeScript, run via `bun` in bash)
- Trigger-based routing (instruction file says "when X, use skill Y")

**Verdict: Not blocked.** Skills work via instructions. Slightly less elegant, but functionally equivalent.

#### 4. Claude Code `settings.json` (Unified Configuration)

PAI's `settings.json` is a single file that controls:
- Environment variables (`env` block)
- Tool permissions (`allow`/`deny`/`ask` with granular patterns)
- Hook registration (which hooks fire on which events)
- `loadAtStartup` files
- `dynamicContext` toggles
- Identity configuration
- Spinner verbs, counts, status line config

**Copilot CLI equivalent:** None of this has a single-file equivalent. Each piece needs a different solution.

**Workaround: Spread across multiple mechanisms.**

| settings.json feature | Copilot workaround |
|---|---|
| **Environment variables** | Shell profile (`~/.zshrc` or `~/.bashrc`) or the wrapper script |
| **Tool permissions** | Copilot CLI has its own built-in safety. Custom rules go in copilot-instructions.md |
| **Hook registration** | N/A — hooks replaced by instruction rules + wrapper script |
| **loadAtStartup files** | Instruction rule: "At session start, read these files" |
| **dynamicContext toggles** | Config file that the AI reads: `~/.pai/config.yaml` |
| **Identity (DA name, user name)** | In copilot-instructions.md or a `~/.pai/identity.yaml` the AI reads at start |
| **Spinner verbs, counts, statusline** | Drop — Copilot CLI has its own UI |

**Verdict: Not blocked.** More spread out but fully functional. A `~/.pai/config.yaml` could serve as a simpler unified config.

#### 5. `projects/` Transcript Access

Claude Code stores session transcripts in `~/.claude/projects/` with 30-day retention. PAI's `SessionHarvester.ts` and `TranscriptParser.ts` read these to extract learnings, relationship notes, and work artifacts.

**Copilot CLI equivalent:** `session_store_sql` provides queryable session history with a different data model (turns, events, checkpoints vs. raw JSONL transcripts).

**Workaround: Use `session_store_sql` instead.**

Copilot CLI actually has a **richer** queryable interface than Claude Code's raw transcript files:

```sql
-- Find recent sessions
SELECT id, summary, created_at FROM sessions ORDER BY created_at DESC LIMIT 10;

-- Search past conversations
SELECT user_message, assistant_response FROM turns 
WHERE user_message ILIKE '%research%' ORDER BY timestamp DESC;

-- Find files changed
SELECT file_path, tool_name FROM session_files WHERE session_id = 'abc';
```

The `SessionHarvester.ts` would need rewriting, but the data it needs is available — just in a different format. The harvester currently:
1. Finds recent transcripts in `~/.claude/projects/` → **Replace with:** `session_store_sql` query
2. Parses JSONL for corrections, errors, insights → **Replace with:** query `turns` table for user messages matching correction/error patterns
3. Writes learnings to `MEMORY/LEARNING/` → **Keep as-is**

**Verdict: Not blocked.** Actually potentially easier — SQL queries vs. JSONL parsing.

#### 6. Custom Slash Commands

PAI registers slash commands (e.g., `/context-search`, `/cs`, `/skill`, `/rename`). These are quick triggers for common actions.

**Copilot CLI equivalent:** No custom slash command registration. Users must use natural language instead.

**Workaround: Natural language triggers in the instruction file.**

Slash commands are just shortcuts. Replace:
```
/context-search "auth module"    →    "context search for auth module"
/skill Research                  →    "use the Research skill"
/rename "Building Auth"          →    "rename this session to Building Auth"
```

The instruction file defines trigger phrases:
```markdown
## Quick Commands
When the user says "context search" or "cs" followed by a query → read and follow ~/.pai/skills/ContextSearch/SKILL.md
When the user says "use skill X" or "skill X" → read ~/.pai/skills/X/SKILL.md
```

**What's lost:**
- Tab-completion for slash commands
- The `/` visual affordance that signals "this is a command"
- Exact-match routing (natural language is fuzzier)

**What's preserved:**
- All the underlying functionality (skills, search, rename)
- Quick invocation via short phrases

**Verdict: Not blocked.** Slightly less discoverable, but functionally identical.

### 🟡 Partial Equivalent — Works Differently

#### 7. CLAUDE.md Auto-Loading

Claude Code automatically loads `CLAUDE.md` from the project root (or `~/.claude/CLAUDE.md` globally) into every session as system instructions.

**Copilot CLI equivalent:** `.github/copilot-instructions.md` serves a similar purpose, but:
- It's repo-scoped, not global (`~/.claude/CLAUDE.md` is global)
- Size/complexity limits may differ
- PAI's CLAUDE.md is 66 lines that reference other files; the actual system prompt is assembled dynamically by hooks

#### 8. Tool Name Differences

| Claude Code | Copilot CLI | Notes |
|---|---|---|
| `Read` | `view` | Different name, similar function |
| `Write` | `create` | Copilot's `create` refuses if file exists; Claude's `Write` overwrites |
| `Edit` | `edit` | Similar (string replacement) |
| `MultiEdit` | Multiple `edit` calls | No batched edit tool |
| `LS` | `view` (on directory) | Same result, different tool |
| `Glob` | `glob` | ✅ Same |
| `Grep` | `grep` | ✅ Same (both use ripgrep) |
| `WebFetch` | `web_fetch` | ✅ Same |
| `WebSearch` | `web_search` | ✅ Same |
| `Task` | `task` | Similar but different agent types and parameters |
| `Bash` | `bash` | Similar but different timeout/mode model |
| `TodoWrite` | `sql` (todos table) | Different mechanism |
| `ExitPlanMode` | `exit_plan_mode` | ✅ Same concept |
| `NotebookRead/Edit` | Not available | Jupyter notebook tools missing |

#### 9. Task/Agent System Differences

| Claude Code | Copilot CLI |
|---|---|
| `subagent_type: Algorithm` | No equivalent (custom agent type) |
| `subagent_type: Engineer` | `agent_type: general-purpose` (closest) |
| `subagent_type: Architect` | `agent_type: general-purpose` (closest) |
| `subagent_type: Explore` | `agent_type: explore` ✅ |
| `model: haiku` | `model: claude-haiku-4.5` (different naming) |
| `model: sonnet` | `model: claude-sonnet-4.6` (different naming) |
| `model: opus` | `model: claude-opus-4.6` (different naming) |
| `run_in_background: true` | `mode: "background"` |

#### 10. The Algorithm CLI (`algorithm.ts`)

The autonomous loop mode (`-m loop`) spawns `claude -p "prompt"` subprocesses in a loop. This would need to be rewritten to spawn `copilot` CLI sessions instead — if Copilot CLI even supports non-interactive scripted invocation.

### 🟢 Migrates Cleanly

These work without changes or with trivial adaptation:

- **All markdown content** — SKILL.md, Algorithm prompt, USER/ files, CONTEXT_ROUTING.md
- **Memory directory structure** — `MEMORY/WORK/`, `MEMORY/LEARNING/`, etc. (just files)
- **Voice server** — Standalone Bun HTTP server at localhost:8888, invoked via curl
- **Notification system** — curl to ntfy/Discord endpoints
- **TypeScript tools** — Run via `bun` in bash, most are tool-agnostic
- **Actions/Pipelines/Flows** — Cloudflare Workers architecture, completely independent
- **Packs** — Markdown install guides + skill files, mostly portable
- **Personal context** — ABOUTME.md, TELOS/, PROJECTS/, etc. (just files the AI reads)

---

## The CLI Wrapper Approach (Full Parity)

### The Idea

Instead of the user interacting directly with Copilot CLI, they interact with a **PAI shell** — a custom CLI that wraps Copilot CLI. The PAI shell intercepts input and output, running hooks at the right moments. The user never knows they're not talking directly to Copilot.

```
What you type into          What actually happens
─────────────────          ────────────────────

 ┌──────────────┐          ┌──────────────────────────────────────┐
 │   You type   │          │           PAI Shell (Bun)            │
 │   "pai"      │          │                                      │
 │              │          │  1. SESSION START                     │
 │              │          │     → Run LoadContext                 │
 │              │          │     → Load identity, memory, context  │
 │              │          │     → Set terminal tab title          │
 │              │          │     → Start voice server              │
 │              │          │                                      │
 │  You type:   │─────────►│  2. USER INPUT                       │
 │  "research   │          │     → Detect ratings ("7" → capture) │
 │   quantum    │          │     → Detect slash commands           │
 │   computing" │          │     → Inject context if needed        │
 │              │          │     → Pass to Copilot CLI ────────┐  │
 │              │          │                                    │  │
 │              │          │  3. COPILOT CLI (subprocess)       │  │
 │              │          │     ← streams response back ──────┘  │
 │              │          │                                      │
 │  You see     │◄─────────│  4. RESPONSE COMPLETE                │
 │  the AI's    │          │     → Extract voice line → TTS       │
 │  response    │          │     → Capture relationship notes      │
 │              │          │     → Sync PRD if applicable         │
 │              │          │     → Update tab title               │
 │              │          │                                      │
 │  You close   │          │  5. SESSION END                      │
 │  the shell   │          │     → Capture learnings              │
 │              │          │     → Clean up state                 │
 │              │          │     → Reset tab title                │
 └──────────────┘          └──────────────────────────────────────┘
```

### How It Works Technically

The PAI shell is a **PTY (pseudo-terminal) wrapper**. It creates a fake terminal, runs Copilot CLI inside it, and sits between you and Copilot — forwarding everything transparently while intercepting at hook points.

```typescript
// Simplified architecture (Bun + node-pty)
import { spawn } from 'node-pty';

// Create a pseudo-terminal running Copilot CLI
const pty = spawn('copilot', [], { 
  cols: process.stdout.columns, 
  rows: process.stdout.rows 
});

// === PRE-HOOK: Intercept user input ===
process.stdin.on('data', (data) => {
  const input = data.toString();
  
  // Rating detection (replaces RatingCapture.hook.ts)
  if (/^\d{1,2}$/.test(input.trim())) {
    captureRating(parseInt(input.trim()));
  }
  
  // Slash command routing (replaces custom slash commands)
  if (input.startsWith('/cs ')) {
    // Transform to natural language before passing through
    pty.write(`context search for ${input.slice(4)}\n`);
    return;
  }
  
  // Pass everything else through to Copilot
  pty.write(data);
});

// === POST-HOOK: Intercept Copilot output ===
pty.onData((data) => {
  // Display to user (transparent pass-through)
  process.stdout.write(data);
  
  // Buffer output for post-processing
  outputBuffer += data;
});

// === RESPONSE COMPLETE detection ===
// When Copilot shows the input prompt again, the response is done
pty.onData((data) => {
  if (detectResponseComplete(data)) {
    // Voice (replaces VoiceCompletion.hook.ts)
    extractAndSpeak(outputBuffer);
    
    // Relationship memory (replaces RelationshipMemory.hook.ts)  
    captureRelationshipNotes(outputBuffer);
    
    // Tab title (replaces UpdateTabTitle.hook.ts)
    updateTabTitle(outputBuffer);
    
    outputBuffer = '';
  }
});
```

### What This Gets You

| Claude Code Hook | PAI Shell Equivalent | Parity |
|---|---|---|
| **SessionStart** → LoadContext | Shell startup phase — runs before Copilot launches | ✅ 100% |
| **UserPromptSubmit** → RatingCapture | Input interception — detects ratings before passing to Copilot | ✅ 100% (even implicit sentiment via API call) |
| **UserPromptSubmit** → SessionAutoName | Input interception — generates name from first prompt | ✅ 100% |
| **PreToolUse** → SecurityValidator | ❌ Can't intercept tool calls — they happen inside Copilot | 🟡 ~60% — instruction-based rules only |
| **PostToolUse** → PRDSync | ❌ Can't intercept tool calls | 🟡 ~60% — instruction-based rules only |
| **Stop** → VoiceCompletion | Output interception — detects response end, extracts voice line | ✅ 100% |
| **Stop** → RelationshipMemory | Output interception — parses response for relationship notes | ✅ 100% |
| **Stop** → LastResponseCache | Output interception — caches last response | ✅ 100% |
| **SessionEnd** → WorkCompletionLearning | Shell exit handler — runs after Copilot closes | ✅ 100% |
| **SessionEnd** → SessionCleanup | Shell exit handler | ✅ 100% |
| Custom slash commands | Input interception — `/cs query` → transformed before Copilot sees it | ✅ 100% |
| Inference.ts (AI subprocess) | Direct Anthropic API call from shell, or pipe to Copilot | ✅ 100% |

**Parity: ~90% of hooks at full fidelity.** The only gap is PreToolUse/PostToolUse — you can't intercept *which tool* Copilot is about to run from outside. But those hooks (SecurityValidator, PRDSync) can be handled by instruction-based rules at ~60% fidelity, which is acceptable.

### Challenges

1. **Response boundary detection** — How does the shell know when Copilot finishes a response? It needs to detect the input prompt reappearing in the output stream. This is doable but requires parsing Copilot CLI's terminal output (ANSI codes and all).

2. **PTY complexity** — `node-pty` (or Bun equivalent) handles pseudo-terminal creation. It's a well-solved problem but adds a native dependency.

3. **Streaming fidelity** — The wrapper must pass through Copilot's streaming output character-by-character with zero visible lag. Buffering for post-processing happens in parallel.

4. **Window resize** — Terminal resize events (`SIGWINCH`) must be forwarded to the inner PTY so Copilot CLI reformats correctly.

### Alternative: Sidecar Process (Simpler, Less Parity)

Instead of wrapping Copilot CLI, run a **sidecar** process alongside it. The instruction file tells the AI to write signals to a known location, and the sidecar watches for them:

```
┌─────────────┐     ┌──────────────────┐
│  Copilot CLI │     │  PAI Sidecar     │
│  (normal)    │     │  (watches files) │
│              │     │                  │
│  AI writes:  │────►│  Detects:        │
│  ~/.pai/     │     │  - new rating    │
│  signals/    │     │  - voice line    │
│  voice.json  │     │  - learning      │
│              │     │  Then runs:      │
│              │     │  - TTS curl      │
│              │     │  - memory write  │
└─────────────┘     └──────────────────┘
```

**Pros:** Simpler — no PTY, no output parsing. Copilot CLI runs normally.
**Cons:** Depends on the AI remembering to write signal files. Less reliable than interception.

### Recommendation

**The PTY wrapper is the right approach for full parity.** It's a proven pattern (tools like `tmux`, `screen`, `expect` all do this). The implementation is a Bun/TypeScript process (~300-500 lines) using `node-pty`. It gives you:

- All 6 Claude Code event types (SessionStart, UserInput, Stop, SessionEnd fully; PreToolUse/PostToolUse partially)
- Custom slash commands
- Rating interception
- Voice extraction
- Full session lifecycle management

And the user experience is identical — they type `pai`, they talk to their AI, they never know there's a wrapper.

---
PAI (Personal AI Infrastructure) v4.0.3 is a comprehensive personal AI platform built **natively on Claude Code**. It installs into `~/.claude/` and layers on top of Claude Code to provide:

- **CLAUDE.md** — The master instruction file that controls AI behavior (modes, output format, routing)
- **Algorithm System** — A multi-step reasoning framework (v3.7.0) for complex tasks
- **Skill System** — 12 skill packs (Research, Security, Agents, Telos, etc.) with structured YAML/MD workflows
- **Hook System** — 20+ TypeScript hooks tied to Claude Code lifecycle events (SessionStart, response completion, etc.)
- **Memory System** — Three-tier (hot/warm/cold) persistent memory with ratings, learnings, reflections
- **Voice System** — ElevenLabs TTS notifications via a local Bun server
- **Security System** — Command validation hooks, protected file lists
- **Notification System** — ntfy push + Discord integration
- **Terminal UI** — Kitty terminal tab titles, statusline, pane management

### Claude Code Dependencies — The Hard Part

PAI is deeply coupled to Claude Code in these specific ways:

| Dependency | Claude Code Feature | Copilot CLI Equivalent | Gap |
|---|---|---|---|
| **CLAUDE.md** | Auto-loaded instruction file | `.github/copilot-instructions.md` or custom instructions | ✅ Direct equivalent exists |
| **settings.json** | Permissions, env vars, tool config | No direct equivalent; handled differently | 🟡 Partial — env vars via shell, permissions N/A |
| **Hook System** | `SessionStart`, `PostToolUse`, `PreToolUse`, `Stop`, `NotificationSend` events | No hook system in Copilot CLI | ❌ No equivalent — must redesign |
| **Subagent Spawning** | `Task` tool with agent types | `task` tool with agent types | ✅ Very similar |
| **Slash Commands** | `/skill`, `/context-search`, custom commands | No custom slash commands | ❌ Must use natural language |
| **Tool Permissions** | `allow`/`deny`/`ask` per tool | Built-in tool permissions (different model) | 🟡 Different approach |
| **File Read/Write/Edit** | Named tools (Read, Write, Edit, MultiEdit) | Named tools (view, create, edit) | ✅ Close equivalents |
| **Bash** | Bash tool with timeout config | Bash tool (sync/async modes) | ✅ Direct equivalent |
| **WebFetch/WebSearch** | Built-in tools | `web_fetch`/`web_search` tools | ✅ Direct equivalents |
| **Glob/Grep** | Built-in tools | `grep`/`glob` tools | ✅ Direct equivalents |
| **MCP Servers** | `mcp__*` tool access | MCP tools available (GitHub, DEVONthink, etc.) | ✅ Available |
| **projects/ transcripts** | Native session storage (30-day) | `session_store_sql` for history | 🟡 Different mechanism |
| **Environment Variables** | `settings.json` env block | Shell env or `.env` file | 🟡 Manual setup |

### Assessment Summary

**What translates cleanly (~60% of PAI):**
- The instruction system (CLAUDE.md → copilot-instructions.md)
- Skill workflows (markdown-based, tool-agnostic)
- The Algorithm (a prompt-based reasoning framework)
- Memory directory structure and file conventions
- Voice server (standalone Bun process, tool-agnostic)
- Notification system (curl-based, tool-agnostic)
- Most TypeScript tools (Bun scripts invoked via bash)

**What requires redesign (~30% of PAI):**
- Hook system (20 hooks with no Copilot CLI event model)
- Session management (auto-load context, auto-name sessions)
- Terminal UI integration (tab titles, statusline)
- Security validation (pre-execution hooks)
- Rating/learning capture (post-response hooks)

**What cannot be replicated (~10% of PAI):**
- Claude Code-specific permissions model
- Custom slash commands (must use natural language triggers)
- `projects/` native transcript access for harvesting
- Some experimental features (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`)

---

## Migration Plan

### Phase 1: Foundation — Instruction System
**Goal:** Get a working Copilot CLI instruction file equivalent to CLAUDE.md

- Port CLAUDE.md.template → `.github/copilot-instructions.md`
- Port the mode system (NATIVE/ALGORITHM/MINIMAL) to Copilot-compatible format
- Port Context Routing to use Copilot CLI file-reading patterns
- Port the Algorithm (v3.7.0) prompt — this is pure markdown, mostly tool-agnostic
- Adapt tool references (Read→view, Write→create, Edit→edit, etc.)
- Set up environment variables via shell profile instead of settings.json

**Status (2026-04-20):** Done for the spike. `.github/copilot-instructions.md`
now uses Copilot-compatible tool names, points at repo-local
`Copilot/Algorithm.md` and `Copilot/ContextRouting.md`, and `Copilot/install.sh`
copies those docs into `~/.pai/` while exporting `PAI_DIR` and
`PAI_VOICE_URL`.

### Phase 2: Skill System Port
**Goal:** Make skill packs work with Copilot CLI

- Audit each skill pack's Claude Code dependencies
- Port skill YAML/MD workflows — update tool references
- Port TypeScript tools — these run via `bun` in bash, mostly agnostic
- Replace any `Read`/`Write`/`Edit` references in workflow instructions
- Test each skill pack individually: Research, Security, Telos, ContentAnalysis, etc.
- Document skills that require Claude Code-specific features and can't be ported

**Status (2026-04-20):** Initial spike implementation is in place. The
installed Copilot skill set now includes `Research`, `FirstPrinciples`, and
`CreateCLI`. `CreateCLI` now targets `~/.pai/Bin/` for generated personal CLIs,
and the installer creates that directory. Remaining packs are still deferred.

### Phase 3: Memory System Adaptation
**Goal:** Preserve learning and memory capabilities

- Keep the `~/.pai/MEMORY/` directory structure (it's just files)
- Replace hook-based capture with manual/scripted alternatives:
  - Rating capture → bash script or prompt-based ("rate this interaction")
  - Work completion learning → prompt-based capture at session end
  - Session harvesting → adapt `SessionHarvester.ts` to read Copilot session store
- Port `session_store_sql` queries to replace `projects/` transcript access
- Adapt learning synthesis tools

**Status (2026-04-20):** Core spike implementation is in place. Three new bash
tools under `Copilot/tools/`:
- `capture-rating.sh` — explicit ratings → `ratings.jsonl` + failure capture for ≤ 3
- `capture-work-learning.sh` — auto-categorised ALGORITHM/SYSTEM learning files
- `learning-readback.sh` — compact startup digest from recent learnings + failures

The sidecar now materialises `startup-digest.md` before Copilot starts, so
learning readback is deterministic (not instruction-only). Instructions updated
to invoke tools at rating events, ALGORITHM Phase 7, and session shutdown.

Deferred for later phases: SessionHarvester (needs transcript format),
RelationshipMemory (complex inference), LearningPatternSynthesis (batch
analysis), implicit sentiment detection (needs API key setup).

### Phase 4: Hook System Replacement
**Goal:** Replace event-driven hooks with alternative patterns

Since Copilot CLI has no hook system, each hook needs a different strategy:

| Hook | Replacement Strategy |
|---|---|
| `LoadContext.hook.ts` | Include context loading in instruction file or session startup prompt |
| `VoiceCompletion.hook.ts` | Manual curl at end of tasks, or a wrapper script |
| `RatingCapture.hook.ts` | Prompt-based: ask for rating in closing flow |
| `SessionAutoName.hook.ts` | Not needed — Copilot manages sessions differently |
| `SecurityValidator.hook.ts` | Rely on Copilot CLI's built-in safety; add rules to instructions |
| `WorkCompletionLearning.hook.ts` | Prompt-based: capture learnings in closing flow |
| `UpdateTabTitle.hook.ts` | Wrapper script that sets tab title before launching |
| `KittyEnvPersist.hook.ts` | Shell profile setup |
| `SessionCleanup.hook.ts` | Manual or cron-based cleanup |
| Others | Case-by-case — most are nice-to-have, not critical |

### Phase 5: Installer & Onboarding
**Goal:** Create a Copilot-compatible installation flow

- Fork or adapt install.sh to detect Copilot CLI instead of Claude Code
- Create setup script that:
  - Installs Bun (unchanged)
  - Sets up environment variables
  - Creates `.github/copilot-instructions.md`
  - Sets up MEMORY directory
  - Configures voice server (unchanged)
  - Creates shell alias for launching with context
- Write a wrapper script (`pai-copilot`) that:
  - Loads context before launching Copilot CLI
  - Sets environment variables
  - Optionally starts voice server

### Phase 6: GitHub Actions Workflows
**Goal:** Replace Claude Code Actions with Copilot equivalents

- Replace `claude.yml` workflow with Copilot equivalent (if available)
- Replace `claude-code-review.yml` with Copilot-based review
- These are nice-to-have, not critical for personal use

---

## Key Decisions Needed

1. **Installation location**: Keep `~/.claude/` (confusing) or move to `~/.pai/`?
2. **Scope**: Full port of all 12 packs, or start with core + selected packs?
3. **Hook replacement priority**: Which hooks are essential vs. nice-to-have?
4. **Dual support**: Maintain compatibility with both Claude Code and Copilot, or Copilot-only fork?
5. **GitHub Actions**: Needed for your workflow, or personal-use only?

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Hook system gaps cause degraded experience | High | Medium | Prioritize LoadContext + VoiceCompletion; accept manual alternatives for others |
| Instruction file size limits | Medium | High | Copilot CLI may have different context limits; test early |
| Skill workflows break due to tool differences | Medium | Medium | Audit and test each pack; maintain a compatibility layer doc |
| Memory capture is inconsistent without hooks | High | Medium | Build session-end ritual into instruction file |
| Voice server works fine | Low | Low | It's a standalone Bun server, fully agnostic |

---

## Recommended Approach

**Start with Phase 1 (instruction system) and test immediately.** The instruction file is the backbone — if that works well, everything else is incremental. Skip Phase 6 (GitHub Actions) initially. Focus on personal-use flow first.

---

## Pending: README.md Copilot Port Documentation

**Goal:** Add a prominent notice and architectural-differences section to the root
`README.md` so readers know this fork includes a Copilot CLI port. All changes are
additive — existing Claude Code content stays intact.

### Tasks

- [ ] **1. Add Copilot port banner** (`readme-banner`)
  Insert a `> [!NOTE]` callout immediately after the v4.0.3 `> [!IMPORTANT]` block
  (after line 67). Text: this fork includes an experimental Copilot CLI port, links
  to the new section below, sets expectations (spike, not production).

- [ ] **2. Add "🔀 Copilot CLI Port" section** (`readme-copilot-section`)
  *Depends on: readme-banner*
  Insert a new `## 🔀 Copilot CLI Port` section after the banner, before the
  "AI should magnify everyone" heading. Contents:
  - **Status**: Experimental spike — proves migration shape, not production-ready
  - **Quick start**: 3-line install (`./Copilot/install.sh`, source, `pai`)
  - **Architectural differences table**:
    | Area | Claude Code (upstream) | Copilot CLI (this fork) |
    |---|---|---|
    | Hook system | 20 hooks across 6 event types | Instruction rules + sidecar wrapper |
    | Voice | ElevenLabs TTS | macOS `say` via local HTTP server |
    | Skills | 25 capabilities, 49 skills, custom sub-agents | 3 ported skills (Research, FirstPrinciples, CreateCLI), generic agent types |
    | Memory tools | Bun/TS scripts + hooks | Shell scripts (capture-rating, capture-work-learning, learning-readback, save-research-memory) |
    | Install path | `~/.claude/` | `~/.pai/` |
    | Installer | GUI wizard (Bun) | Shell script |
    | Sub-agents | Custom types (GeminiResearcher, etc.) | Fixed types (general-purpose, explore, task, rubber-duck, code-review) |
    | Autonomous loop | `algorithm.ts` CLI | Deferred |
    | Packs | 12 standalone packs | Not yet ported |
  - **What's preserved**: Algorithm 7-phase loop, personal context layer, memory
    loop, rating capture, voice notifications, 3 core skills
  - **Link**: See `Copilot/README.md` for full spike details

- [ ] **3. Update nav links** (`readme-nav-update`)
  *Depends on: readme-copilot-section*
  Add a "Copilot Port" entry to the top navigation line (around line 48–52) so
  readers can jump directly to the new section.

- [ ] **4. Update FAQ entry** (`readme-faq-update`)
  Update the "Is PAI only for Claude Code?" FAQ answer (around line 445) to cite
  the Copilot CLI port as a concrete example of platform adaptation, rather than
  just saying "community members are welcome to adapt it."

### Notes

- Keep existing content intact — additive only
- Match existing markdown style (centered headers, badges, table formatting)
- Architectural differences table should be scannable, not prose-heavy
- Reference `Copilot/README.md` and `tasks/todo.md` for detailed spike status
- Don't update badges or shields (they point to upstream danielmiessler repo)
