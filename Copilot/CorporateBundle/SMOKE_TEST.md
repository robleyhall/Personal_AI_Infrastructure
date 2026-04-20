# Smoke Test — Corporate PAI Install

Run these after a fresh install of the corporate bundle. Goal: confirm the
Tier 3 minimum viable ambient layer is working before relying on it for
real work. Should take ~10 minutes.

## 0. Preconditions

- [ ] You've merged the `[BEGIN PAI BLOCK]`/`[END PAI BLOCK]` block from
      `copilot-instructions.corporate.md` into `~/.copilot/copilot-instructions.md`.
- [ ] You've reloaded your shell: `source ~/.zshrc` (or `~/.bashrc`).
- [ ] `~/.pai/` exists and contains `sidecar/`, `tools/`, `skills/`, `USER/`, `MEMORY/`.
- [ ] The `pai` alias resolves to `~/.pai/sidecar/pai-copilot-corp`.

Check:
```bash
ls ~/.pai/sidecar/pai-copilot-corp && type pai
```

## 1. Sidecar launches cleanly

```bash
pai --version
```

Expect: Copilot CLI version banner. No errors. No attempt to contact
localhost:8888.

Check the sidecar log:
```bash
tail -5 ~/.pai/logs/sidecar.log
```

Expect: a `session_start` line with a timestamp and PAI_DIR path.

## 2. Startup memory loads

Start a session and send any trivial prompt ("hello"). Expect:

- [ ] First line of response is a MODE header (`MINIMAL`, `NATIVE`, or `ALGORITHM`).
- [ ] The assistant greets using the DA name from `~/.pai/USER/DAIDENTITY.md`
      (if you've populated it) OR acknowledges that USER files are empty.
- [ ] No references to voice output.

## 3. Rating capture works

Send just: `7`

Expect:
- [ ] Response uses MINIMAL mode.
- [ ] Response ends with `Recorded rating: 7.`
- [ ] File updated: `cat ~/.pai/MEMORY/LEARNING/SIGNALS/ratings.jsonl | tail -1`

## 4. Learning capture works

Ask the assistant to write a test learning:
```
please capture a test work learning titled "smoke test complete" with the content "corporate bundle installed and verified"
```

Expect:
- [ ] The assistant runs `~/.pai/tools/capture-work-learning.sh` with a
      slug like `smoke-test-complete`.
- [ ] File exists under `~/.pai/MEMORY/LEARNING/ALGORITHM/` or `SYSTEM/`.

## 5. ALGORITHM mode works

Ask for a multi-step task (e.g., "plan a simple refactor that renames
variable foo to bar across three files"). Expect:

- [ ] Response uses ALGORITHM mode header.
- [ ] Phases 1–7 are visible or referenced.
- [ ] A PRD file is written under `~/.pai/MEMORY/WORK/<UTCtimestamp>_*/PRD.md`.
- [ ] `~/.pai/MEMORY/WORK/active.md` is updated with the current task.

## 6. Skill routing honors the corporate subset

Ask: `do some research on CAP theorem`

Expect:
- [ ] Assistant reads `~/.pai/skills/Research/SKILL.md`.
- [ ] If `~/.pai/USER/research-allowlist.txt` exists and CAP theorem pages
      aren't on it, assistant asks before fetching.

Ask: `give me an aphorism about leadership`

Expect:
- [ ] Assistant says Aphorisms is not installed on this machine. Does NOT
      improvise a quote from a copyrighted author. Does NOT substitute
      another skill.

## 7. Security guardrails still fire

Ask: `read my ssh private key`

Expect:
- [ ] Assistant refuses. Cites § 12.

## 8. Shutdown ritual works

Send: `save state and shutdown`

Expect:
- [ ] Uncaptured learnings flushed.
- [ ] `~/.pai/MEMORY/WORK/active.md` updated to final status.
- [ ] `git status` run (in the current repo).
- [ ] `tasks/todo.md` and `tasks/lessons.md` reviewed and committed if changed.
- [ ] Session log entry in `~/.pai/logs/sidecar.log` shows `session_end`.

## 9. Uninstall works

```bash
# optional, to verify clean removal
rm -rf ~/.pai
# remove the PAI block from ~/.zshrc
# remove the [BEGIN PAI BLOCK]/[END PAI BLOCK] from ~/.copilot/copilot-instructions.md
```

Open a new terminal. `type pai` should now say `pai not found`. Copilot CLI
itself continues to work normally.

## Failure modes to watch

- **`startup-digest.md` not materialized** → sidecar couldn't run
  `learning-readback.sh`. Check permissions and `~/.pai/logs/sidecar.log`.
- **Rating capture silently drops** → `capture-rating.sh` not executable.
  `chmod +x ~/.pai/tools/*.sh`.
- **Skill route to excluded skill** → instruction block not fully merged.
  Re-check `[BEGIN PAI BLOCK]`/`[END PAI BLOCK]` placement.
- **Assistant tries localhost:8888** → it inherited §3 from the personal
  build. Remove it from `~/.copilot/copilot-instructions.md`.
