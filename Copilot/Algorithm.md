# PAI Algorithm (Copilot edition)

Copilot-adapted reference for ALGORITHM mode. This replaces the old Claude-only
Algorithm dependency with a repo-local guide that matches the tools and files
available in this spike.

## Core loop

```text
Observe → Think → Plan → Build → Execute → Verify → Learn
```

The job is to move from the current state to the ideal state with explicit,
verifiable criteria.

## Ideal State Criteria (ISC)

ISC are the contract for the work. Each criterion must be:

- **Atomic** — one fact per line
- **Binary** — clearly yes or no
- **Observable** — tied to a file, command, behavior, or output
- **Current** — updated when the work changes

Examples:

| Weak | Strong |
|---|---|
| Feature implemented correctly | Button renders on settings page |
| Docs updated | Installer README mentions new support docs |
| Migration done | `.github/copilot-instructions.md` uses `view` and `rg` |

Anti-criteria matter too. Capture what must **not** happen when it affects the
shape of the solution.

## Phase guide

### 1. Observe

- Read the relevant files before making assumptions.
- Load `tasks/todo.md` and `tasks/lessons.md` first for repo context.
- If the task touches PAI migration internals, read `Copilot/ContextRouting.md`
  and follow the routing table.

Deliverable: current-state notes and an initial ISC list.

### 2. Think

- Compare plausible approaches.
- Prefer the smallest approach that satisfies the full ask.
- Reuse existing patterns before inventing new structure.

Deliverable: a chosen approach and any important tradeoffs.

### 3. Plan

- Write the PRD to `~/.pai/MEMORY/WORK/<UTCtimestamp>_<slug>/PRD.md`.
- Keep ISC as checkboxes.
- Mirror executable work items into SQL todos when the task spans multiple
  steps or files.

Deliverable: a plan with testable criteria.

### 4. Build

- Change only the files required for the task.
- Keep migrations self-consistent: if instructions point at a file, create or
  update that file in the same pass.
- Translate Claude-only tool references to Copilot equivalents while editing.

Deliverable: the code, docs, or scripts that satisfy the criteria.

### 5. Execute

- Run the existing checks, tests, builds, or demos already present in the repo.
- For documentation-heavy work, run targeted commands that prove the workflow
  still makes sense.

Deliverable: command output or observable behavior tied to ISC items.

### 6. Verify

- Check every ISC item explicitly.
- If a criterion cannot be proven, it is not done.
- Search for stale references after mechanical migrations.

Deliverable: updated PRD with verified checkboxes.

### 7. Learn

- Append non-obvious constraints, gotchas, or migration rules to
  `tasks/lessons.md`.
- Only record durable lessons that will matter in future sessions.

Deliverable: one or more reusable lessons, or an explicit decision that no new
lesson was needed.

## Copilot-era tool mapping

| Old instruction | Copilot edition |
|---|---|
| Read | `view` |
| Write / Edit / MultiEdit | `apply_patch` or another appropriate edit tool |
| Grep | `rg` |
| LS | `view` on a directory |
| Skill | read the skill markdown and execute it |
| TodoWrite | `sql` |

## Practical rules

1. Read enough context before editing.
2. Batch independent reads together.
3. Keep repo-local migration docs under `Copilot/`.
4. Use `~/.pai/` for installed runtime state, memory, and skills.
5. Do not leave the instruction system pointing at nonexistent `.claude`
   runtime files.
