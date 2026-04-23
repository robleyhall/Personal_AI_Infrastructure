#!/usr/bin/env bash
# engagement-distill.sh — Roll per-launch engagement JSONL into per-project
# markdown files and emit a compact digest (active + stale) on stdout.
#
# Reads:   $PAI_DIR/MEMORY/WORK/projects/engagement.jsonl
# Writes:  $PAI_DIR/MEMORY/WORK/projects/<slug>.md (one per distinct repo)
# Stdout:  "### Active Projects" + "### Stale Projects" sections (markdown)
#
# Idempotent — rebuilds each per-project file from the full JSONL history.

set -euo pipefail

PAI_DIR="${PAI_DIR:-$HOME/.pai}"
PROJECTS_DIR="$PAI_DIR/MEMORY/WORK/projects"
JSONL="$PROJECTS_DIR/engagement.jsonl"

[[ -f "$JSONL" ]] || { echo ""; exit 0; }

python3 - "$JSONL" "$PROJECTS_DIR" <<'PYEOF'
import json, os, sys, re
from datetime import datetime, timezone
from collections import defaultdict

jsonl_path, projects_dir = sys.argv[1], sys.argv[2]

now = datetime.now(timezone.utc)
by_repo = defaultdict(list)

with open(jsonl_path, "r", encoding="utf-8") as fh:
    for raw in fh:
        raw = raw.strip()
        if not raw:
            continue
        try:
            rec = json.loads(raw)
        except json.JSONDecodeError:
            continue
        slug = rec.get("repo_slug")
        if not slug:
            continue
        by_repo[slug].append(rec)


def parse_ts(s):
    # "2026-04-23T00:12:34Z"
    return datetime.fromisoformat(s.replace("Z", "+00:00"))


def rel(delta_seconds):
    s = int(delta_seconds)
    if s < 60:
        return f"{s}s ago"
    m = s // 60
    if m < 60:
        return f"{m}m ago"
    h = m // 60
    if h < 48:
        return f"{h}h ago"
    d = h // 24
    return f"{d}d ago"


summaries = []  # (slug, last_dt, age_days, sessions, open_todos, repo_root)

for slug, rows in by_repo.items():
    rows.sort(key=lambda r: r["ts"])
    last = rows[-1]
    first = rows[0]
    last_dt = parse_ts(last["ts"])
    first_dt = parse_ts(first["ts"])
    sessions = len({r.get("session_id", "") for r in rows})
    open_todos = last.get("open_todos", 0)
    repo_root = last.get("repo_root", "")
    age_days = (now - last_dt).total_seconds() / 86400.0

    md = []
    md.append(f"# {slug}\n")
    md.append(f"- **Path:** {repo_root}")
    md.append(
        f"- **Last touched:** {last_dt.strftime('%Y-%m-%dT%H:%M:%SZ')} "
        f"({rel((now - last_dt).total_seconds())})"
    )
    md.append(f"- **First touched:** {first_dt.strftime('%Y-%m-%dT%H:%M:%SZ')}")
    md.append(f"- **Sessions:** {sessions}")
    md.append(f"- **Open todos (tracked files):** {open_todos}")
    md.append("")
    md.append("## Recent launches")
    for r in rows[-5:][::-1]:
        md.append(f"- {r['ts']} · session `{r.get('session_id','')}` · cwd `{r.get('cwd','')}`")
    md.append("")

    out_path = os.path.join(projects_dir, f"{slug}.md")
    with open(out_path, "w", encoding="utf-8") as fh:
        fh.write("\n".join(md))

    summaries.append((slug, last_dt, age_days, sessions, open_todos, repo_root))

# ── Digest sections ──────────────────────────────────────────────
summaries.sort(key=lambda t: t[1], reverse=True)

active = [s for s in summaries if s[2] <= 7.0]
stale = [s for s in summaries if s[2] > 14.0 and s[4] > 0]

lines = []
if active:
    lines.append("### Active Projects")
    lines.append("")
    for slug, last_dt, age, sessions, open_todos, _ in active[:10]:
        delta = (now - last_dt).total_seconds()
        todos_str = f", {open_todos} open todos" if open_todos else ""
        lines.append(f"- **{slug}** — touched {rel(delta)}, {sessions} session(s){todos_str}")
    lines.append("")

if stale:
    lines.append("### Stale Projects (>14d with open todos)")
    lines.append("")
    for slug, last_dt, age, sessions, open_todos, _ in stale[:10]:
        delta = (now - last_dt).total_seconds()
        lines.append(f"- **{slug}** — last touched {rel(delta)}, {open_todos} open todos")
    lines.append("")

sys.stdout.write("\n".join(lines))
PYEOF
