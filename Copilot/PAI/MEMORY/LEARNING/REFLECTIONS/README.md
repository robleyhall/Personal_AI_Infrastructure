> **Ported from upstream [danielmiessler/Personal_AI_Infrastructure](https://github.com/danielmiessler/Personal_AI_Infrastructure) v4.0.3 — `MEMORYSYSTEM.md` REFLECTIONS spec.** Mechanical port.

---

# MEMORY/LEARNING/REFLECTIONS/

Per-session Algorithm performance reflections. Written at the end of Algorithm Phase 7 (LEARN) — what worked, what didn't, what to try differently.

## Primary artifact

```
REFLECTIONS/
└── algorithm-reflections.jsonl    # Append-only, one JSON object per line
```

## JSONL schema

```json
{
  "timestamp": "2026-04-23T11:03:39Z",
  "slug": "tier2-upstream-pai-port",
  "category": "SYSTEM",
  "session": "20260423T105651Z-41679",
  "artifact": "/Users/robley/.pai/MEMORY/LEARNING/SYSTEM/2026-04/...md",
  "content": "markdown body of the learning"
}
```

## Writing reflections

Invoke `capture-work-learning.sh --reflection` during Phase 7:

```bash
echo "<markdown summary of what was learned>" | \
  ~/.pai/tools/capture-work-learning.sh --slug "<task-slug>" --reflection
```

The `--reflection` flag writes both the standard ALGORITHM/SYSTEM markdown file **and** appends a JSONL line here. Without `--reflection`, only the markdown file is written (backward compatible).

## Querying reflections

```bash
# Last 10 reflections
tail -10 ~/.pai/MEMORY/LEARNING/REFLECTIONS/algorithm-reflections.jsonl | jq .

# Filter by slug
jq 'select(.slug | contains("port"))' ~/.pai/MEMORY/LEARNING/REFLECTIONS/algorithm-reflections.jsonl
```
