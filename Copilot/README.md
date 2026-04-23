# Copilot (Phase 0 Spike) — Overview

Minimal end-to-end port of PAI onto GitHub Copilot CLI. The goal is to prove
the shape of the migration, not to ship a full product. See `tasks/todo.md`
for the full plan and `tasks/lessons.md` for what we learned building this.

> **Using PAI day-to-day?** See [`USER_GUIDE.md`](USER_GUIDE.md) for end-user
> installation, session usage, skills, rating, voice, and shutdown workflow.
> This file focuses on spike architecture and status.

## Layout

```text
Copilot/
├── install.sh              # Installer: copies tree to ~/.pai/, adds shell alias
├── README.md               # (this file)
├── Algorithm.md            # Copilot-adapted 7-phase reference
├── ContextRouting.md       # Repo-local routing for migration tasks
├── PAI/                    # SYSTEM-tier upstream-parity docs (v4.0.3 port)
│   ├── AISTEERINGRULES.md, CLIFIRSTARCHITECTURE.md, CONTEXT_ROUTING.md,
│   │   DOCUMENTATIONINDEX.md, FLOWS.md, MEMORYSYSTEM.md, PAIAGENTSYSTEM.md,
│   │   PAISYSTEMARCHITECTURE.md, PIPELINES.md, PRDFORMAT.md, SKILLSYSTEM.md,
│   │   SYSTEM_USER_EXTENDABILITY.md, THEDELEGATIONSYSTEM.md, THEFABRICSYSTEM.md,
│   │   THEHOOKSYSTEM.md, THENOTIFICATIONSYSTEM.md, TOOLS.md, ACTIONS.md, CLI.md
│   ├── ACTIONS/, FLOWS/, PIPELINES/   # subdir READMEs
│   └── Algorithm/          # historical algorithm breakdowns (v3.5, v3.7)
├── agents/                 # Agent profile catalog (14 profiles)
│   └── Algorithm.md, Architect.md, Artist.md, BrowserAgent.md,
│       ClaudeResearcher.md, CodexResearcher.md, Designer.md, Engineer.md,
│       GeminiResearcher.md, GrokResearcher.md, Pentester.md,
│       PerplexityResearcher.md, QATester.md, UIReviewer.md
├── state/                  # Runtime state skeleton (tasks/, queue/, sessions/)
│   └── README.md           # Layout + divergence from upstream
├── VoiceServer/            # Local TTS via macOS `say` (replaces ElevenLabs)
│   ├── server.ts
│   ├── start.sh
│   └── README.md
├── sidecar/
│   └── pai-copilot         # Shell wrapper around `copilot` (replaces hooks)
├── tools/
│   ├── capture-rating.sh       # Explicit rating → ratings.jsonl + failure capture
│   ├── capture-work-learning.sh # Session learning → ALGORITHM/ or SYSTEM/
│   ├── engagement-distill.sh   # Cross-session project engagement → per-project .md
│   ├── harvest-session.sh      # Backfill learnings from past session events
│   ├── learning-readback.sh    # Compact startup digest from recent learnings
│   └── save-research-memory.sh # Research artifact + promotion to startup memory
└── skills/
    ├── Research/           # Ported research workflows
    ├── FirstPrinciples/    # Reasoning from fundamentals
    ├── CreateCLI/          # CLI generation workflows
    ├── Telos/              # Personal mission/goals tracking
    ├── Thinking/           # BeCreative, Council, FirstPrinciples, IterativeDepth, RedTeam, Science, WorldThreatModelHarness
    ├── Investigation/      # OSINT, PrivateInvestigator
    ├── ContentAnalysis/    # ExtractWisdom (YouTube/article analysis)
    ├── USMetrics/          # US data analysis workflows
    ├── Security/           # AnnualReports, PromptInjection, Recon, SECUpdates, WebAssessment
    └── PORTING_NOTES.md    # Batch-port substitution log
```

## Upstream parity status

Tier 1 port (SYSTEM docs + agents + STATE tree) complete as of tag
`pre-tier1-port-20260423T0127Z` + successor. Tier 2 (PRD per-task dirs, USER
subdirs, FAILURES/SYNTHESIS/REFLECTIONS) and Tier 3 (hook-equivalents,
statusline overlay, tab titles) pending. See `~/.pai/MEMORY/WORK/active.md`
for status.

## What's in the spike

| Piece | Status | Notes |
|---|---|---|
| Install path `~/.pai/` | ✅ | Decided; mechanical `sed` applied |
| Copilot-only fork | ✅ | No dual support; Claude Code refs removed |
| `copilot-instructions.md` | ✅ | Modes, routing, Algorithm, voice, ratings, memory |
| `ContextRouting.md` | ✅ | Repo-local + installed-runtime path map |
| `Algorithm.md` | ✅ | Copilot-adapted ISC and 7-phase reference |
| Sidecar wrapper | ✅ | Pre-session digest materialisation + voice startup + `--add-dir $PAI_DIR` for context access |
| Voice server (`say`) | ✅ | Drop-in `POST /notify`, no API key |
| Research skill | ✅ | Mechanical port; see `PORTING_NOTES.md` |
| FirstPrinciples skill | ✅ | Ported with Copilot-safe runtime paths |
| CreateCLI skill | ✅ | Ported to `~/.pai/Bin` and shipped in spike |
| Telos / Thinking / Investigation / ContentAnalysis / USMetrics / Security | ✅ | Batch port; see `skills/PORTING_NOTES.md` |
| Research memory promotion | ✅ | Saves artifacts + compact `what matters` digest |
| Rating capture | ✅ | `capture-rating.sh` — explicit ratings → `ratings.jsonl` |
| Work learning capture | ✅ | `capture-work-learning.sh` — auto-categorised ALGORITHM/SYSTEM |
| Startup learning readback | ✅ | `learning-readback.sh` — sidecar materialises `startup-digest.md` |
| `gh models` for inference | ⏭️ | Deferred until we have a real rating-volume signal |
| Session harvester | ⏭️ | Needs transcript format; deferred |
| Relationship memory | ⏭️ | Complex inference; deferred |
| Pattern synthesis | ⏭️ | Batch analysis of ratings; deferred |
| **Other skill packs** | ⏭️ | Agents (needs multi-model redesign), Media, Scraping, Utilities — deferred |
| GitHub Actions | ⏭️ | Deferred |
| PTY wrapper | ⏭️ | Sidecar first; revisit only if fidelity gaps hurt |

## Install and run

```bash
./Copilot/install.sh
source ~/.zshrc       # (or restart shell)
pai                   # launches copilot via the sidecar
```

The installer now also copies `Algorithm.md` and `ContextRouting.md` into
`~/.pai/`, creates `~/.pai/Bin/` for generated personal CLIs, and adds
`PAI_DIR` plus `PAI_VOICE_URL` exports to the shell profile.

### Sidecar file-access allowlist

The sidecar launches Copilot as:

```bash
copilot --add-dir "$PAI_DIR" "$@"
```

This is architecturally load-bearing: Copilot's default file-access scope is
the current working directory, so without `--add-dir $PAI_DIR` the AI cannot
read `~/.pai/USER/`, `~/.pai/MEMORY/`, `~/.pai/skills/`, or `~/.pai/tools/`
without per-session `/add-dir` prompts. Pre-session materialisation of
`startup-digest.md` is not enough on its own — the in-session instruction
file also needs to read `ABOUTME.md`, `DAIDENTITY.md`, `AISTEERINGRULES.md`,
`latest.md`, and `active.md` for every prompt. `--add-dir` closes that gap
and makes the full startup readback reliable.

## Verify

```bash
# 1. Voice server
curl -sS -X POST http://localhost:8888/notify \
  -H 'content-type: application/json' \
  -d '{"message":"PAI spike is alive"}'

# 2. Sidecar health
~/.pai/sidecar/pai-copilot --version    # should pass through to copilot --version

# 3. Instructions loaded
# In a `pai` session, the first response should start with a mode header
# (MINIMAL / NATIVE / ALGORITHM) per .github/copilot-instructions.md §2.

# 4. Research memory promotion
cat <<'EOF' | ~/.pai/tools/save-research-memory.sh --topic "test topic" --mode "quick"
- One durable insight
- One useful follow-up
EOF

# 5. Rating capture
~/.pai/tools/capture-rating.sh --rating 8 --summary "test rating"
cat ~/.pai/MEMORY/LEARNING/SIGNALS/ratings.jsonl

# 6. Work learning capture
echo "Test learning" | ~/.pai/tools/capture-work-learning.sh --slug "test"
find ~/.pai/MEMORY/LEARNING/ -name '*.md' -type f

# 7. Learning readback
~/.pai/tools/learning-readback.sh

# 8. New skills loaded
# In a `pai` session, try:
# "Think about this from first principles: should this be a microservice?"
# "Create a CLI for the GitHub API that lists my repos"
```

## Known friction

See `tasks/lessons.md` and `skills/Research/PORTING_NOTES.md`.
