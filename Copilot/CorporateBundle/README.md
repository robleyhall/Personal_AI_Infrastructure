# Personal AI Infrastructure — Corporate Bundle

**Target environment:** GitHub Copilot CLI on a corporate-managed macOS laptop (e.g. Microsoft CSA workstation).

**What this is:** A trimmed, security-reviewable subset of the [PAI (Personal AI Infrastructure)](https://github.com/danielmiessler/Personal_AI_Infrastructure) project, adapted for corporate use. PAI is an ambient layer on top of an LLM CLI — it gives the AI a memory of *you*, your work, and your learnings that persists across every session, every repo, every project.

**What this is not:** A replacement for Copilot CLI. PAI sits *on top* of Copilot CLI. Copilot CLI stays the foundation; PAI adds identity, memory, and a structured way of working.

---

## Why bother?

Default Copilot CLI has no memory between sessions. Every conversation starts from zero. PAI's core observation is that **the assistant should be the constant and the project should be the variable**. One persistent AI collaborator that knows your role, your lessons learned, and how you like to work — whether you're in a client codebase, writing an internal doc, or planning a presentation.

The corporate bundle delivers that with zero external network egress, no API keys, no telemetry, and no binaries beyond what macOS ships by default.

---

## What's in the bundle

### Instruction layer (pure prompting)

- Ambient behavior rules merged into `~/.copilot/copilot-instructions.md`
- Three response modes (MINIMAL / NATIVE / ALGORITHM)
- Startup context loading from `~/.pai/USER/` and `~/.pai/MEMORY/`
- Rating and learning capture rituals
- Security guardrails (refusal to read `~/.ssh`, credentials, corp sandbox data)

### Runtime (bash + markdown only)

```
~/.pai/
├── USER/                   # user-authored identity, steering rules, TELOS (CSA-framed)
├── MEMORY/
│   ├── LEARNING/           # task and system learnings (markdown)
│   ├── WORK/active.md      # current-task tracking
│   └── RELATIONSHIP/       # user-stated durable facts
├── skills/                 # 12 corp-safe skills (see INCLUDES.txt)
├── tools/                  # 5 bash scripts (no network, no secrets)
└── sidecar/
    └── pai-copilot-corp    # slim wrapper around `copilot`
```

### What's included (12 skills)

**🟢 Green — ship as-is:**
- FirstPrinciples — decompose problems, challenge assumptions
- Thinking — BeCreative, Council, RedTeam, IterativeDepth, Science, WorldThreatModelHarness
- ContentAnalysis/ExtractWisdom — extract insights from articles/videos
- Documents/Pdf — local PDF parsing and summarization
- Telos — CSA-role-framed goal/mission scaffold (customer outcomes, solution patterns, platform breadth, stakeholder posture, technical depth)

**🟡 Yellow — ship with modifications:**
- Fabric — ~30 generic prompt patterns (summarize, extract_wisdom, improve_writing, create_threat_model, etc.); branded patterns excluded
- Research — restricted to a user-maintained domain allowlist
- Prompting — markdown templates only; TypeScript rendering deferred
- CreateSkill — author corp-specific skills in-house

### What's excluded (and why)

See `EXCLUDES.txt` for the full list. Highlights:

- **Aphorisms** — DB contains copyrighted quotes; IP concern
- **Security / Investigation / Parser** — active external scanning; incompatible with corp security policy
- **PAIUpgrade / Evals** — require API keys or heavy TypeScript; deferred to a future tier
- **Voice server / voice rules** — unnecessary for corp use; skipped
- **CreateCLI** — writes executables to `~/.pai/Bin/`; needs separate review
- **USMetrics** — irrelevant to corp work

---

## Prerequisites

- macOS 13+ (corporate-managed Mac)
- GitHub Copilot CLI installed and working
- `bash` 4+ (macOS default), `python3` (macOS default), `rsync` (macOS default)
- Nothing else — no `bun`, no `node`, no external package installs

---

## Installation

```bash
cd Personal_AI_Infrastructure
./Copilot/install-corporate.sh
```

The installer will:

1. Display a pre-flight summary (what will be written, where)
2. Prompt for confirmation
3. Create `~/.pai/` tree (or the location specified by `PAI_USER_DIR`)
4. Copy the allowlisted skills and tools
5. Install `~/.pai/sidecar/pai-copilot-corp`
6. Add a `pai` alias to your shell rc
7. Print a diff patch for `~/.copilot/copilot-instructions.md`

**Optional environment variables:**

- `PAI_USER_DIR` — relocate `~/.pai/USER/` elsewhere (e.g. `~/Documents/pai/USER/`) if corp policy requires
- `PAI_DIR` — override the entire `~/.pai/` root location

**Dry-run mode:** `./Copilot/install-corporate.sh --dry-run` prints what would happen without writing anything.

**Uninstall:** `rm -rf ~/.pai/` — that's it. Remove the `pai` alias and the instruction block from `~/.copilot/copilot-instructions.md`.

---

## Security review

Before deploying to a corp environment, read `SECURITY_REVIEW.md`. It covers:

- Threat model (what this bundle can and cannot do)
- Network footprint (zero new endpoints beyond Copilot CLI itself)
- Filesystem footprint (all under `~/.pai/` or user-chosen `PAI_USER_DIR`)
- Process footprint (no daemons, no cron, no background processes)
- Attribution and licensing (MIT upstream; see `ATTRIBUTION.md`)
- Dependencies (bash, python3, rsync — all OS-default)

For Info Sec submissions, `SECURITY_REVIEW.md` is written as a standalone artifact.

---

## Attribution

See `ATTRIBUTION.md`. Upstream: [Daniel Miessler — Personal AI Infrastructure](https://github.com/danielmiessler/Personal_AI_Infrastructure) (MIT). Fabric patterns: [danielmiessler/fabric](https://github.com/danielmiessler/fabric) (MIT).

This corporate bundle is a derivative work; original copyright notices are preserved.

---

## Limitations

- **Memory is local to this laptop.** No cloud sync. If you want continuity across machines, export `~/.pai/` before migration (respecting corp data policy).
- **Learnings accumulate corp IP** once you start using it at work. `~/.pai/MEMORY/LEARNING/*.md` is corp-owned data; treat it accordingly.
- **Skill drift risk.** The installer validates installed skills against `INCLUDES.txt`. Manually dropping a red skill into `~/.pai/skills/` bypasses that check.
- **No voice output.** Intentional; voice server is Tier 4 and out of scope for the corporate bundle.
- **No automatic upgrades.** Upgrades are manual (rerun installer on a new bundle version).

---

## Roadmap

- **Tier 4 (future):** Evaluate adding the voice server, TypeScript skill tools (Prompting `RenderTemplate.ts`, Evals suite), and additional skills after initial corp adoption + separate security review.
- **Corp-specific skills:** Use the included `CreateSkill` skill to author skills for your own workflow (customer-engagement templates, internal-tool wrappers, etc.). These stay on your laptop unless you explicitly promote them to a shared location.

---

## Questions / issues

File issues in the main repo or contact the author. This bundle is provided as-is under MIT.
