# Research Skill — Port Notes (spike)

This is a mechanical port of `Releases/v4.0.3/.claude/skills/Research/` for
Copilot CLI. The point is to exercise the end-to-end flow, not to re-architect.

## Automated substitutions applied

| From (Claude Code)                    | To (Copilot CLI)                |
|---------------------------------------|---------------------------------|
| `~/.claude/`                          | `~/.pai/`                       |
| `Read tool`, `Write tool`, `Edit tool`| `view`, `create`, `edit` tool   |
| `WebFetch` / `WebSearch` tool         | `web_fetch` / `web_search` tool |
| `Task tool` with custom `subagent_type: "ClaudeResearcher"` etc. | `task` tool with `agent_type: "general-purpose"` |
| `run_in_background: true`             | `mode: "background"`            |

## What this port *does not* do (yet)

1. **Parallel multi-provider research.** Claude Code could spawn named agents
   (`ClaudeResearcher`, `GeminiResearcher`, `PerplexityResearcher`,
   `GrokResearcher`) that each used a different upstream LLM. Copilot CLI's
   `task` tool only exposes `general-purpose` / `explore` / `task` /
   `rubber-duck` / `code-review`, all backed by the same model family. For the
   spike every research angle runs under `general-purpose`; the diversity is
   lost. Re-introducing it means building an external provider shim (e.g. a
   tool script that calls `gh models`, OpenAI, Gemini via `curl`).

2. **Voice `voice_id` parameters.** Curl payloads still include ElevenLabs
   `voice_id` fields. The spike voice server (`Copilot/VoiceServer`) ignores
   them, so nothing breaks — but they're dead weight.

3. **`~/.pai/PAI/USER/SKILLCUSTOMIZATIONS/Research/`.** Referenced as a
   load-time lookup. Directory does not exist yet in the Copilot install.
   Skill gracefully falls through to defaults if it's missing.

## Known friction to capture in `tasks/lessons.md` after first run

- Does Copilot honour the mandatory voice-notification-first rule, or skip it?
- Does the absence of named researcher sub-agents change output quality
  noticeably for a real query?
- Do the existing markdown output formats (the big ASCII boxes) render
  cleanly in Copilot CLI's TUI?
