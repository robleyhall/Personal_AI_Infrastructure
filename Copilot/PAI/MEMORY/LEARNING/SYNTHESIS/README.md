> **Ported from upstream [danielmiessler/Personal_AI_Infrastructure](https://github.com/danielmiessler/Personal_AI_Infrastructure) v4.0.3 — `MEMORYSYSTEM.md` SYNTHESIS spec.** Mechanical port of the intent; Copilot CLI has no hook API, so upstream's `LearningPatternSynthesis.ts` is not ported. Aggregation is currently manual.

---

# MEMORY/LEARNING/SYNTHESIS/

Aggregated pattern analysis — weekly/monthly reports that roll up signals from `MEMORY/LEARNING/SIGNALS/` (rating events) and work learnings from `ALGORITHM/` and `SYSTEM/`.

## Layout

```
SYNTHESIS/
└── YYYY-MM/
    ├── weekly-YYYY-WW.md    # 7-day rollups
    └── monthly-YYYY-MM.md   # Full-month synthesis
```

## Contents (suggested)

- Recurring issues (count + representative examples)
- Rating distribution and trend vs. prior period
- Patterns in SYSTEM failures (env, tooling, CI)
- Patterns in ALGORITHM learnings (what worked, what didn't)
- Action items for AISTEERINGRULES.md or skill updates

## Writing synthesis

Currently manual — run `~/.pai/tools/learning-readback.sh` for a live digest, then distill into a dated synthesis file. Automated aggregation is Tier 3 backlog (sidecar-driven).
