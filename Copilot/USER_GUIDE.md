# PAI User Guide (Copilot CLI edition)

A practical guide to using PAI day-to-day with GitHub Copilot CLI. For the
technical port details and spike status, see [`README.md`](README.md).

---

## Table of contents

1. [What PAI gives you](#what-pai-gives-you)
2. [Installation](#installation)
3. [Starting a session](#starting-a-session)
4. [How it responds — the three modes](#how-it-responds--the-three-modes)
5. [The Algorithm (for complex tasks)](#the-algorithm-for-complex-tasks)
6. [Built-in skills](#built-in-skills)
7. [Rating responses](#rating-responses)
8. [Voice notifications](#voice-notifications)
9. [Personal context — making PAI know you](#personal-context--making-pai-know-you)
10. [Ending a session](#ending-a-session)
11. [Memory system — what gets saved and where](#memory-system--what-gets-saved-and-where)
12. [Troubleshooting](#troubleshooting)
13. [Common workflows](#common-workflows)

---

## What PAI gives you

PAI turns Copilot CLI into a personal assistant that:

- **Knows you** — loads your background, preferences, and active work at session start
- **Thinks systematically** — uses a 7-phase Algorithm for complex tasks
- **Remembers** — captures ratings, learnings, and discoveries across sessions
- **Speaks** — announces progress and completions via your laptop's TTS
- **Has skills** — structured workflows for research, reasoning, and building CLIs

You interact with a normal Copilot CLI session; PAI layers on top.

---

## Installation

```bash
# From the repo root
./Copilot/install.sh

# Reload your shell (or open a new terminal)
source ~/.zshrc        # or ~/.bashrc
```

The installer:

- Creates `~/.pai/` with all runtime files (skills, tools, memory directories)
- Adds `PAI_DIR` and `PAI_VOICE_URL` exports to your shell RC
- Adds a `pai` alias that launches the sidecar wrapper
- Warns (but doesn't fail) if `bun`, `copilot`, or macOS `say` are missing

**Prerequisites:** `bash`, `curl`, `git` (required); `copilot`, `bun`, `say` (recommended).

Re-running `install.sh` is safe — it's idempotent.

---

## Starting a session

```bash
pai
```

That's it. Behind the scenes, the sidecar wrapper:

1. Exports PAI environment variables
2. Starts the voice server on `localhost:8888` (if not already running)
3. Materializes your learning digest from recent sessions
4. Sets the terminal tab title to "PAI"
5. Launches `copilot` with your context loaded

On first message, PAI will greet you and reference recent work or learnings.

---

## How it responds — the three modes

Every response starts with a mode header so you can see how PAI classified your request:

| Mode | When | What you see |
|---|---|---|
| **MINIMAL** | Greetings, acknowledgments, ratings | One-line reply with `═══ PAI ═══` header |
| **NATIVE** | Single-step tasks (<2 min of work) | Structured `NATIVE MODE` block with task, changes, verification |
| **ALGORITHM** | Multi-file or investigative work | Full 7-phase Algorithm (see below) |

You don't have to pick the mode — PAI classifies automatically. If it picks wrong, just say "do this as ALGORITHM" or similar.

---

## The Algorithm (for complex tasks)

For anything non-trivial, PAI enters **Algorithm Mode** — 7 phases announced as it works:

| Phase | What happens |
|---|---|
| 1. **OBSERVE** | Reads relevant files; understands current state |
| 2. **THINK** | Analyzes the problem; compares approaches |
| 3. **PLAN** | Writes Ideal State Criteria (ISC) — testable success checkboxes |
| 4. **BUILD** | Creates or modifies artifacts |
| 5. **EXECUTE** | Runs tests, builds, or demos |
| 6. **VERIFY** | Checks each ISC checkbox with evidence |
| 7. **LEARN** | Captures discoveries to `tasks/lessons.md` and memory |

At each phase transition, PAI speaks: *"Entering the observe phase."*

A **PRD** (prompt + ISC + notes) is written to `~/.pai/MEMORY/WORK/<timestamp>_<slug>/PRD.md` as a persistent artifact you can re-read later.

**Example trigger:** "Refactor the auth module to use JWT instead of sessions."

---

## Built-in skills

Nine skills ship with the spike. Trigger them with natural language:

### Research
Multi-agent research with verified sources.

| Say | Mode |
|---|---|
| *"quick research on X"* | Quick (1 agent, fast) |
| *"research X"* | Standard (2 agents: Claude + Gemini) |
| *"extensive research on X"* | Extensive (multi-agent, deeper) |
| *"deep investigation into X"* | DeepInvestigation workflow |

Results are saved to `~/.pai/MEMORY/RESEARCH/` with a compact digest promoted to startup memory.

### FirstPrinciples
Reasoning from fundamentals.

| Say | What it does |
|---|---|
| *"think about X from first principles"* | Decomposes the problem |
| *"decompose this"* | Breaks into atomic components |
| *"challenge my assumptions about X"* | Challenges premises |

### CreateCLI
Builds personal CLIs to `~/.pai/Bin/`.

| Say | What it does |
|---|---|
| *"create a CLI for X"* | Scaffolds a new CLI |
| *"add command Y to this CLI"* | Extends an existing CLI |
| *"upgrade this CLI to tier 2"* | Adds structure (config, tests, etc.) |

### Telos
Personal mission, goals, beliefs, and projects tracking.

| Say | What it does |
|---|---|
| *"what are my goals?"* | Reads your `USER/TELOS/GOALS.md` |
| *"update my mission"* | Edits `USER/TELOS/MISSION.md` |
| *"what am I working on?"* | Lists active projects |

### Thinking
Seven reasoning frames for different problem types.

| Say | Sub-skill |
|---|---|
| *"be creative about X"* / *"brainstorm X"* | BeCreative |
| *"convene a council on X"* / *"debate X"* | Council (multi-role debate) |
| *"think iteratively on X"* / *"go deeper on X"* | IterativeDepth |
| *"red team this"* / *"attack this idea"* | RedTeam |
| *"apply science to X"* / *"test this hypothesis"* | Science |
| *"world threat model"* | WorldThreatModelHarness |
| *"first principles …"* | FirstPrinciples (also exposed as top-level) |

### Investigation
OSINT and private-investigator workflows for people and companies.

| Say | Sub-skill |
|---|---|
| *"investigate <person/company>"* / *"OSINT on X"* | OSINT |
| *"background check on X"* | PrivateInvestigator |

### ContentAnalysis
Extract wisdom and structured insights from long-form content.

| Say | What it does |
|---|---|
| *"extract wisdom from <URL>"* | Pulls key ideas, quotes, references |
| *"analyze this video/article"* | YouTube transcript + wisdom extraction |

### USMetrics
Analyze US data (economic, demographic, public-sector metrics).

### Security
Multi-tool security workflows.

| Say | Sub-skill |
|---|---|
| *"recon on <target>"* | Recon |
| *"web assessment of <URL>"* | WebAssessment (ffuf, OSINT, testing guides) |
| *"prompt injection test"* | PromptInjection |
| *"SEC updates"* / *"annual report for X"* | SECUpdates / AnnualReports |

> **Note:** The 6 newly batch-ported skills (Telos, Thinking, Investigation,
> ContentAnalysis, USMetrics, Security) are mechanical ports from the upstream
> Claude Code skill packs. They lose multi-model agent diversity (all agents
> run under `general-purpose`) and some tools expect system binaries like
> `ffuf` or `amass` to be on your `$PATH`. See
> [`skills/PORTING_NOTES.md`](skills/PORTING_NOTES.md) for known gaps.

---

## Rating responses

Send a bare number **1–10** as your next message to rate PAI's last response:

```
7
```

Or explicitly:

```
rate: 8
```

```
3 — the answer missed the actual question
```

What happens:

- **All ratings** → appended to `~/.pai/MEMORY/LEARNING/SIGNALS/ratings.jsonl`
- **Ratings ≤ 3** → trigger a **failure capture** with full context to `MEMORY/LEARNING/FAILURES/`, so the system can learn from low-scoring interactions

PAI replies in MINIMAL mode: `Recorded rating: 7.`

**Don't** send numbers inside substantive prompts — PAI only treats bare numbers as ratings.

---

## Voice notifications

At the end of every non-MINIMAL response, PAI speaks an 8–16 word summary via the local voice server (macOS `say`).

**Control voice output:**

```bash
# Stop the voice server
pkill -f "voice-server" || lsof -ti:8888 | xargs kill

# Restart manually
~/.pai/VoiceServer/start.sh

# Test it
curl -sS -X POST http://localhost:8888/notify \
  -H 'content-type: application/json' \
  -d '{"message":"PAI voice is working"}'
```

If the voice server isn't running, PAI continues silently — no errors.

---

## Personal context — making PAI know you

Populate these optional files to customize how PAI treats you:

| File | Purpose |
|---|---|
| `~/.pai/USER/ABOUTME.md` | Who you are — background, expertise, interests |
| `~/.pai/USER/DAIDENTITY.md` | Your AI's name and personality (e.g., "Tessa, warm and concise") |
| `~/.pai/USER/AISTEERINGRULES.md` | Personal behavior rules PAI must follow |
| `~/.pai/USER/SKILLCUSTOMIZATIONS/<skill>.md` | Per-skill preference overrides |

PAI reads these at session start. Any file you don't create is silently skipped.

**Minimal example — `~/.pai/USER/DAIDENTITY.md`:**

```markdown
# DA Identity
Name: Tessa
Tone: warm, direct, no hedging
Greeting style: "Hey <first name>, it's Tessa. <one-sentence context>"
```

---

## Ending a session

When you're done, say:

```
save state and shutdown
```

PAI will:

1. Capture any uncaptured work learnings
2. Capture relationship notes (if any user-stated durable facts emerged)
3. Update `~/.pai/MEMORY/WORK/active.md` with final status
4. Run `git status`
5. Commit uncommitted work with an appropriate message
6. Update `tasks/todo.md` and `tasks/lessons.md` if you're in a repo
7. Push the current branch to origin
8. Report branch name, commits ahead of main, and open items

Then just close the terminal. The sidecar runs cleanup on exit (stale temp files, empty work dirs).

---

## Memory system — what gets saved and where

```
~/.pai/MEMORY/
├── LEARNING/
│   ├── startup-digest.md           # Materialized at session start
│   ├── latest.md                   # Promoted research takeaways
│   ├── SIGNALS/ratings.jsonl       # Every rating
│   ├── FAILURES/                   # Full context for ratings ≤ 3
│   ├── ALGORITHM/                  # Task-execution learnings
│   └── SYSTEM/                     # Tooling/infra learnings
├── WORK/
│   ├── active.md                   # Current-work block (overwritten)
│   └── <timestamp>_<slug>/PRD.md   # Per-task PRDs with ISC checkboxes
├── RESEARCH/                       # Full research artifacts
└── RELATIONSHIP/<date>.md          # User-stated facts captured at shutdown
```

**What you can safely delete:**

- Old PRD directories under `MEMORY/WORK/` (keep recent ones for reference)
- Old failure captures (but keep them if you want to learn from them)

**What you shouldn't delete:**

- `latest.md` and `startup-digest.md` — they're regenerated but hold durable takeaways
- `ratings.jsonl` — the full history of your ratings

---

## Troubleshooting

### `pai: command not found`

Run `source ~/.zshrc` (or `~/.bashrc`), or open a new terminal. If still missing, re-run `./Copilot/install.sh`.

### No voice output

Check the voice server:
```bash
curl -sf http://localhost:8888/health
```
If it fails, start it manually: `~/.pai/VoiceServer/start.sh`. On non-macOS, voice is a silent no-op (the server only wraps macOS `say`).

### PAI didn't greet me / didn't reference recent work

Either the USER/ files are missing (populate them — see above) or the startup digest is empty (do some work so there's something to digest). Check `~/.pai/MEMORY/LEARNING/startup-digest.md`.

### Rating wasn't captured

The AI only recognizes **bare** numbers 1–10 or `rate: N` as ratings. If your message had other content, PAI treated it as a regular prompt.

### Response didn't start with a mode header

That's a behavioral miss — Copilot CLI is instruction-driven, not hook-enforced. Just say *"use the proper mode header next time"* and it'll self-correct.

### Sidecar log

```bash
tail -f ~/.pai/logs/sidecar.log
```

---

## Common workflows

### Daily standup

```
pai
# PAI greets you, mentions active work
what did we work on yesterday and what's open?
```

### Research then act

```
pai
quick research on rate-limiting strategies for REST APIs
# Review the findings
now implement the token-bucket approach in src/middleware/
```

### Build a personal CLI

```
pai
create a CLI called "tix" that lists my Jira tickets and creates branches
# CreateCLI skill scaffolds to ~/.pai/Bin/tix
```

### Rate and learn

```
pai
explain how OAuth PKCE works
# ...PAI explains...
8
# Rating captured
```

### Shutdown

```
save state and shutdown
# PAI commits, pushes, reports status
# Close terminal
```

---

## Further reading

- [`README.md`](README.md) — spike status and technical port details
- [`Algorithm.md`](Algorithm.md) — full 7-phase Algorithm reference
- [`ContextRouting.md`](ContextRouting.md) — which files PAI reads for which tasks
- [`skills/*/SKILL.md`](skills/) — individual skill workflows
- [`../tasks/lessons.md`](../tasks/lessons.md) — lessons learned building the port
