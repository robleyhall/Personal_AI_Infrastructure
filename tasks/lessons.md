# Hermes Inbox Automation Lessons

## Storage/Artifact contract hardening (2026-06-17)

**Problem:** Documentation drifted from live behavior, and direct dashboard cards could fail or scatter artifacts due to ambiguous workspace/output assumptions.

**Fixes applied:**
- Created missing Mac/VM-backed `work/` directory at `/media/psf/HermesExchange/work` (Mac: `~/Documents/Hermes Exchange/work`).
- Added Mac/VM-backed projects share for durable repo work:
  - Mac: `~/Documents/Hermes Projects/projects`
  - VM: `/media/psf/HermesProjects/projects`
  - Container: `/workspace/projects`
- Recycled stale Hermes containers so they rehydrate from current `terminal.docker_volumes`.
- Updated watcher contract so workers read from `/workspace/inbox/<job>` and write outputs to `/workspace/outbox/<job>`.
- Kept `processing/` and `completed_jobs/` as input-state management only.
- Added global worker guidance in `/home/parallels/.hermes/AGENTS.md`:
  - direct/dashboard tasks default to `/workspace/outbox/dashboard/<task-id-or-slug>/`
  - repo/code tasks must use `/workspace/projects/<repo-or-experiment>/`
  - no final artifacts in `/tmp`.

**Kanban workspace bug (separate from file bridge):**
- Root cause for dashboard task failures: tasks on `org-roam-pkm` had `workspace_path='managed_id'` (non-absolute).
- Repaired affected tasks to `workspace_kind='scratch'` with `workspace_path=NULL`.
- Added SQLite triggers on board DB(s) to auto-normalize future `managed_id` writes to scratch/null.

**Outcome:** one consistent durable output root for both flows: `outbox/`.
Repo work is now durable under a separate shared root: `projects/`.

## Workflow Design (2026-06-14)

**Correct job lifecycle:**
1. `inbox/job-name/` (prompt.md + inputs) → watcher detects
2. Kanban task created → job folder moved to `processing/job-name/`
3. Task executes and writes outputs to `outbox/job-name/`
4. When outputs appear in outbox, watcher moves INPUT folder from `processing/` to `completed_jobs/job-name/` (archive)

**Folder purposes:**
- **inbox/** = new jobs to process (contains prompt.md + input files)
- **processing/** = jobs currently being executed (temporary, moved to completed or back to inbox if failed)
- **outbox/** = task outputs (results, artifacts, generated files)
- **completed_jobs/** = archive of INPUTS only (for reference/audit trail)

**Key insight:** completed_jobs is an archive of the input specs, NOT the outputs. Outputs stay in outbox.

## Hermes Remote Bridge Cron (2026-06-14)

**Problem:** Obsolete `/home/parallels/.local/bin/hermes_remote_bridge.py` script ran via crontab every 60 seconds, creating stale `inbox/input/` and `inbox/remote/` folders that synced back to Mac.

**Root cause:** Old hermes remote sync workflow using different paths:
- Script configured for `/home/parallels/hermes-inbox`, `/home/parallels/hermes-work`, `/home/parallels/hermes-outbox`
- These paths were never mounted or used after Hermes Exchange centralization

**Solution:** Deleted cron job and script; replaced with local inbox watcher.

**Files removed:**
- `/Users/robley/.local/bin/hermes_remote_bridge.py`
- `/Users/robley/.config/hermes-bridge/` (config directory)
- Crontab entry: `* * * * * /usr/bin/python3 /Users/robley/.local/bin/hermes_remote_bridge.py ...`

## Systemd Service Deployment (2026-06-14)

**Why systemd vs nohup:**
- Auto-restarts on crash (Restart=always, RestartSec=5)
- Survives VM reboots
- Cleaner process lifecycle
- Logs managed by syslog

**Critical permission gotcha:**
- Service must run as `parallels` user (not root)
- If root ever created the log file, parallels user cannot write to it
- Always delete stale log files before starting service

**Working service config:**
```ini
[Service]
User=parallels
WorkingDirectory=/home/parallels/.hermes
ExecStart=/usr/bin/python3 /home/parallels/.hermes/hermes-inbox-monitor.py
Restart=always
RestartSec=5
StartLimitInterval=300
StartLimitBurst=10
```

## Watcher Implementation Details (2026-06-22 update)

**Script:** `/home/parallels/.hermes/hermes-inbox-monitor.py`
**Service:** `hermes-inbox-monitor.service` (systemd, User=parallels)
**Monitor interval:** 5 seconds

**Job folder semantic:**
A folder under `inbox/` is a valid job **only if it contains `prompt.md`**.
Folders without `prompt.md` are silently skipped.

**prompt.md frontmatter (optional):**
Supported YAML frontmatter fields decoded by the watcher and mapped to kanban flags:

| Field | Type | Maps to |
|---|---|---|
| `title` | str (max 200, safe chars only) | task title (overrides `Process: <job>`) |
| `assignee` | str (alphanumeric/hyphens, max 50) | `--assignee` |
| `priority` | int (1–1000) | `--priority` |
| `skill` | str or list of str | `--skill` (repeatable) |
| `max_runtime` | str (e.g. `30m`, `2h`) | `--max-runtime` |
| `max_retries` | int (1–20) | `--max-retries` |
| `goal` | bool | `--goal` |
| `goal_max_turns` | int (1–200) | `--goal-max-turns` |
| `workspace` | str (scratch/worktree/dir:…) | `--workspace` |
| `triage` | bool | `--triage` (suppresses --assignee) |

Unknown or invalid fields are logged with a warning and ignored (no crash, no pass-through).
Frontmatter is stripped before passing the body to the kanban card.

**Idempotency:** Every card is created with `--idempotency-key inbox-<job-name>`,
so watcher restarts do not create duplicate cards.

**Kanban integration:**
- Default: `--assignee default` (goes directly to ready, not triage)
- `triage: true` in frontmatter routes to triage instead

**Folder transitions:**
- `get_new_jobs()`: scans inbox for prompt.md folders not yet in processing/completed
- `stage_to_processing()`: copies input snapshot to processing/ (worker reads from inbox/)
- `has_outbox_output()`: polls outbox for job folder existence
- `finalize_job()`: moves processing/ snapshot to completed_jobs/, removes inbox/ source

**Known limitations:**
- Completion detection is folder-existence only (not Kanban task status)
- No error recovery for failed tasks (stay in processing until manually handled)
- No rate limiting if many jobs arrive simultaneously

## PKMBuildout prior-art document hierarchy (2026-07-01)

- `30_Projects/PKMBuildout/miessler-pai-integration.md` is the conceptual source of truth for PKM_2.0 prior art: gap priority, Phase A/B recommendation, and the original five open questions.
- `30_Projects/PKMBuildout/pai-integration-prd-roadmap.md` supersedes only the roadmap section of the miessler analysis; its header says the earlier analysis sections remain authoritative.
- `30_Projects/PKMBuildout/PKM Buildout Plan.md` is a pre-execution plan, while `30_Projects/PKMBuildout/move-log.md` records what actually happened afterward. Read both together before answering status questions.
