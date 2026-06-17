# Hermes Storage + Artifact Runbook

This is the source-of-truth mapping for where Hermes inputs, working state, and outputs live across Mac, Ubuntu VM, and Docker tool containers.

## Canonical mapping

| Semantics | Mac | Ubuntu VM | Container |
|---|---|---|---|
| Inbox jobs (input) | `/Users/robley/Documents/Hermes Exchange/inbox/` | `/media/psf/HermesExchange/inbox/` | `/workspace/inbox/` |
| Processing snapshots (input state) | `/Users/robley/Documents/Hermes Exchange/processing/` | `/media/psf/HermesExchange/processing/` | `/workspace/processing/` |
| Durable output artifacts | `/Users/robley/Documents/Hermes Exchange/outbox/` | `/media/psf/HermesExchange/outbox/` | `/workspace/outbox/` |
| Durable repo projects/worktrees | `/Users/robley/Documents/Hermes Projects/projects/` | `/media/psf/HermesProjects/projects/` | `/workspace/projects/` |
| Archived input snapshots | `/Users/robley/Documents/Hermes Exchange/completed_jobs/` | `/media/psf/HermesExchange/completed_jobs/` | `/workspace/completed_jobs/` |
| Optional scratch | `/Users/robley/Documents/Hermes Exchange/work/` | `/media/psf/HermesExchange/work/` | `/workspace/work/` |
| Full exchange root | `/Users/robley/Documents/Hermes Exchange/` | `/media/psf/HermesExchange/` | `/workspace/exchange/` |

## Two execution flows, one output location

### File-bridge flow (drop folder in inbox)

1. User drops `inbox/<job>/prompt.md` (+ optional payload files).
2. `hermes-inbox-monitor` copies the input to `processing/<job>/` (snapshot).
3. Card is created for worker with:
   - read path: `/workspace/inbox/<job>/`
   - write path: `/workspace/outbox/<job>/`
4. Once outbox output appears, monitor moves `processing/<job>/` to `completed_jobs/<job>/` and removes `inbox/<job>/`.

### Direct dashboard / direct kanban cards

- Cards should write durable outputs to:
  - `/workspace/outbox/dashboard/<task-id-or-slug>/`
- If the task is repo/code work, create/use the repository at:
  - `/workspace/projects/<repo-or-experiment>/`
- Include `RESULT.md` in that folder listing generated artifacts.

**Rule:** final artifacts do not live in `/tmp`.  
Use `/workspace/outbox/...` for artifacts and `/workspace/projects/...` for durable git repos/worktrees.

## Why this contract exists

- Workers have historically shown inconsistent access to `/workspace/processing`.
- `/workspace/inbox` and `/workspace/outbox` are the stable mounted paths used by both file-bridge and direct-card workflows.
- Keeping all outputs under outbox gives one Mac-visible retrieval root for every interaction mode.

## Config and control points

- Hermes config: `/home/parallels/.hermes/config.yaml`
  - section: `terminal.docker_volumes`
- Monitor script: `/home/parallels/.hermes/hermes-inbox-monitor.py`
- Monitor service: `/etc/systemd/system/hermes-inbox-monitor.service`
- Global output policy for workers: `/home/parallels/.hermes/AGENTS.md`

## Quick validation

```bash
# monitor health
prlctl exec "Ubuntu 24.04.3 ARM64" sudo systemctl status hermes-inbox-monitor

# monitor events
prlctl exec "Ubuntu 24.04.3 ARM64" tail -f /tmp/hermes-inbox-monitor.log

# verify outputs are on Mac
ls -la "/Users/robley/Documents/Hermes Exchange/outbox/"
```
