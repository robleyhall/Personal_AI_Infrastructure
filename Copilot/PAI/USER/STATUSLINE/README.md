> **Ported from upstream [danielmiessler/Personal_AI_Infrastructure](https://github.com/danielmiessler/Personal_AI_Infrastructure) v4.0.3.** Mechanical port. **Caveat:** this bucket describes Claude Code's status line API — **Copilot CLI has no statusline extension point**. A tmux-overlay equivalent is Tier 3 backlog. Kept as a scaffold for upstream parity; do not expect execution here.

---

# Status Line Customization

Configure what appears in your Claude Code status line. PAI uses the status line to show session context, active skill, and system state.

## Configuration

Create a `config.md` or modify the `statusline-command.sh` in the `.claude/` root to customize display elements.
