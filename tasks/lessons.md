# Hermes Inbox Automation Lessons

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

## Watcher Implementation Details (2026-06-14)

**Monitor interval:** 5 seconds (balance between responsiveness and CPU)

**Folder transitions:**
- `get_new_jobs()`: scans inbox for folders not yet in processing
- `move_to_processing()`: atomically moves from inbox to processing
- `check_task_completion()`: polls outbox for job folder existence
- `move_to_completed()`: moves input folder from processing to completed_jobs (archive)

**Kanban integration:**
- Creates task with `--assignee default` (goes directly to ready, not triage)
- Passes job folder path in task body for reference
- Returns task ID for logging/tracking

**Known limitations:**
- Simplistic completion detection (just checks folder existence, not task status)
- No error recovery (failed tasks stay in processing until manually handled)
- No rate limiting if many jobs arrive at once
