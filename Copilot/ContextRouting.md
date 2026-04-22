# PAI Copilot Context Routing

Load only what the current task needs. For migration work in this repository,
prefer the repo-local paths below. Use `~/.pai/...` only for installed runtime
state and personal memory.

## Repo-local migration and implementation docs

| Topic | Path |
|---|---|
| Copilot instruction system | `.github/copilot-instructions.md` |
| Migration plan and status | `tasks/todo.md` |
| Migration lessons | `tasks/lessons.md` |
| Spike overview | `Copilot/README.md` |
| Copilot Algorithm reference | `Copilot/Algorithm.md` |
| Installer | `Copilot/install.sh` |
| Sidecar wrapper | `Copilot/sidecar/pai-copilot` |
| Voice server overview | `Copilot/VoiceServer/README.md` |
| Voice server implementation | `Copilot/VoiceServer/server.ts` |
| Research skill entrypoint | `Copilot/skills/Research/SKILL.md` |
| Research workflow details | `Copilot/skills/Research/Workflows/` |

## Claude source material being ported

| Topic | Path |
|---|---|
| Source instruction template | `Releases/v4.0.3/.claude/CLAUDE.md.template` |
| Source assembled instructions | `Releases/v4.0.3/.claude/CLAUDE.md` |
| Source context routing | `Releases/v4.0.3/.claude/PAI/CONTEXT_ROUTING.md` |
| Source Algorithm agent | `Releases/v4.0.3/.claude/agents/Algorithm.md` |

## Installed runtime and user context

These paths are reliably readable in any `pai` session because the sidecar
launches Copilot with `--add-dir "$PAI_DIR"`, which adds the entire `~/.pai`
tree to Copilot's file-access allowlist at process start. Without that flag,
reading anything under `~/.pai` outside the cwd would require per-session
`/add-dir` approval. See `Copilot/sidecar/pai-copilot` and
`Copilot/README.md` → "Sidecar file-access allowlist".

| Topic | Path |
|---|---|
| User profile | `~/.pai/USER/ABOUTME.md` |
| Assistant identity | `~/.pai/USER/DAIDENTITY.md` |
| Steering rules | `~/.pai/USER/AISTEERINGRULES.md` |
| Recent learnings | `~/.pai/MEMORY/LEARNING/latest.md` |
| Active work | `~/.pai/MEMORY/WORK/active.md` |
| Research artifacts | `~/.pai/MEMORY/RESEARCH/` |
| Installed skills | `~/.pai/skills/` |
| Installed tools | `~/.pai/tools/` |
| Installed sidecar | `~/.pai/sidecar/pai-copilot` |
| Installed voice server | `~/.pai/VoiceServer/` |

## Routing rules

1. If the task is about the migration itself, start with repo-local files.
2. If the task is about a user-specific session or memory artifact, read the
   relevant `~/.pai/...` files.
3. If repo-local docs and source `.claude` docs disagree, treat repo-local
   Copilot files as the current target and `.claude` files as source material.
