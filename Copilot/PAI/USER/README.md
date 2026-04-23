> **Ported from upstream [danielmiessler/Personal_AI_Infrastructure](https://github.com/danielmiessler/Personal_AI_Infrastructure) v4.0.3.** Mechanical path rewrite: `~/.claude/PAI/` → `~/.pai/PAI/`. These scaffolds describe the canonical USER/ buckets; Copilot CLI users populate them the same way upstream does. Note: `STATUSLINE/` references Claude Code's status line API — **not available in Copilot CLI**. Kept for upstream parity; real statusline-equivalents land in Tier 3 (tmux overlay).

---

# USER Context Directory

`~/.pai/USER/` is where your personal context lives — the content PAI uses to tailor its outputs to you. Upstream ships these as scaffolds; populate them over time.

## Buckets

| Dir | Purpose |
|-----|---------|
| `ABOUTME.md` | Startup-loaded biographical snapshot |
| `DAIDENTITY.md` | How your DA shows up (tone, pushback, verbosity) |
| `AISTEERINGRULES.md` | Accumulated behavioral corrections |
| `TELOS/` | Mission, goals, strategies, projects, beliefs |
| `PROJECTS/` | Project registry and routing |
| `BUSINESS/` | Company / brand / media kit |
| `WORK/` | Professional work tracking, client context |
| `ACTIONS/` | Reusable automation actions |
| `FLOWS/` | Workflow orchestration JSON |
| `PIPELINES/` | Data pipeline YAML |
| `Workflows/` | Custom skill-extending workflows |
| `STATUSLINE/` | Status line customization (Copilot: not active) |
| `TERMINAL/` | Terminal config (kitty, iterm, tmux) |
| `SKILLCUSTOMIZATIONS/` | Per-skill overrides |

## Convention

Each bucket has its own `README.md` describing expected contents. Create files inside buckets as you accumulate context. PAI reads from these at startup (`ABOUTME.md`, `DAIDENTITY.md`, `AISTEERINGRULES.md`) or on demand.
