# Decision Doc — PAI ↔ PKM ↔ MemPalace Boundary

> **Status:** draft for review — no implementation until decisions are signed.
> **Replaces / consolidates:** the "Open Architecture Question — PAI ↔ Wiki Boundary" section of `~/projects/mini-ak-wiki/integrated-pkm-plan.md` (lines 189–257).
> **Forces this decision:** the proposed MemPalace install (Tier B of `tasks/memory-incorporation-plan.md`) would add a third store. Adding it before resolving boundaries is the scope-creep risk we just flagged.
> **Reference:** `~/.pai/MEMORY/RESEARCH/2026-04/2026-04-26_claude-code-memory-systems-vs-pai/REPORT.md`

---

## What changed since 2026-04-22 (when the original boundary doc was written)

1. **PAI ↔ DEVONthink is already federated.** Verified live in this session: DEVONthink running, PKM database open, PAI has 30+ MCP tools (`devonthink-stdio-search`, `create_record`, `ask_ai_about_documents`, `lookup_record`, `classify`, `add_tags`, etc.). PAI can read, write, search, tag, and AI-query DEVONthink without leaving a session. The "two brains" framing from the original doc described a real problem that has now partly resolved itself at the **tool layer** — but the **content layer** (where things live, what's source of truth) is still unresolved.
2. **MemPalace is on the table as a third store.** Verbatim conversation recall over `~/.copilot/session-state/*/events.jsonl`, local Chroma + SQLite, no API keys. Doesn't compete with PKM or PAI MEMORY/ — it occupies a layer neither covers (word-for-word recall of past sessions).
3. **TELOS migration from PKM `30_Projects/` is queued** (Phase 1 of "Consolidate Projects Tracking" in `active.md`). That decision is upstream of this one — once PROJECTS state-of-record is unambiguous, the rest collapses.

---

## Proposed mental model: three layers, one ecosystem

Not three silos. Three **layers of one memory system**, each with a clear role:

| Layer | Owner | Role | Today |
|---|---|---|---|
| **Cortex** — reasoning, current state, working memory, the loop you operate in | PAI (`~/.pai/USER/`, `MEMORY/{LEARNING,WORK,RELATIONSHIP}`) | Fast, session-scoped, in the Copilot lifecycle. Source of truth for *operational* state. | Exists, well-developed |
| **Long-term memory** — reference material, archive, OCR'd inputs, durable corpus, knowledge graph | DEVONthink PKM (OneDrive-synced, PARA + Johnny Decimal) | OCR, mobile, multi-device sync, AI cross-corpus, See Also, classify. Source of truth for *reference* material. | Exists, well-developed; partly federated to PAI via MCP |
| **Episodic memory** — verbatim conversation recall, "what did we actually say about X" | MemPalace (proposed, vendored under `~/.pai/vendor/mempalace/`) | Word-for-word retrieval. Indexed via AAAK pointers. | Not built |

**Key insight:** the friction isn't integration. It's **boundary clarity** — which layer owns what, and how they cross-reference. AAAK pointers (Tier A2 of the memory plan) become the unified spine: a pointer can target a file path, a DEVONthink UUID, or a MemPalace drawer ID.

---

## The decisions to make (each separately answerable)

### Decision 1 — Operational vs reference research

**Question:** Today, both PAI's `MEMORY/RESEARCH/` and DEVONthink hold "research." Which owns what?

**Proposed default:**
- **PAI `MEMORY/RESEARCH/` owns "operational research"** — research artifacts PAI generated that you may act on within the next ~2 weeks. Lifecycle: hot, may be edited, contributes to current work.
- **DEVONthink PKM owns "reference research"** — anything that has cooled into source-of-truth material to consult later. Lifecycle: durable, OCR-able, archive-grade.
- **Promotion path:** when a PAI research artifact stops changing (typically after the related work item closes), `save-research-memory.sh` (or a new `promote-to-pkm.sh`) creates a DEVONthink record in `20_Reference/` (or appropriate group), writes the DT UUID into the AAAK pointer index, and optionally garbage-collects the PAI copy after a retention window.

**Trade-offs:**
- ✅ Single source of truth at any given time (PAI while hot, DT once cold).
- ✅ Mobile access to durable artifacts (DT syncs to iOS/iPad).
- ❌ Adds a promotion step. Risk: artifacts never get promoted, PAI/MEMORY/RESEARCH/ silts up.
- ❌ Two locations during the hot period; risk of editing the wrong one. Mitigation: AAAK pointer always lists the canonical home for the moment.

**Decision needed:** ☐ accept default · ☐ alternative: ____________

---

### Decision 2 — TELOS state-of-record (subsumes the "Consolidate Projects Tracking" task)

**Question:** PAI `USER/TELOS/PROJECTS.md` and PKM `30_Projects/` both describe projects. Which is canonical?

**Three candidates:**

A. **PAI is canonical for TELOS; PKM hosts artifacts.**
- TELOS/PROJECTS.md = single state-of-record per project (status, goals, decisions).
- PKM `30_Projects/<project>/` = artifacts (docs, scans, contracts, deliverables).
- AAAK pointer per project lists both.
- This is what Phase 1 of "Consolidate Projects Tracking" already decided in spirit.

B. **PKM is canonical; PAI is a working cache.**
- All project state lives in `30_Projects/` as markdown.
- PAI's TELOS becomes a small index pointing into PKM via DT UUIDs.
- Closer to the original wiki-unification candidate from the 2026-04-22 doc.

C. **Split: PAI canonical for active, PKM canonical for archived.**
- Active project → PAI TELOS.
- On project close, migrate to PKM `30_Projects/<archived>/` and remove from TELOS.
- Status stamp on each TELOS entry indicates which layer is canonical at that moment.

**Recommended: A.**
- Closest to the existing structure; minimum change.
- TELOS is privacy-sensitive (customer names, financial targets); keeping it in `~/.pai/` (private, never synced) preserves the privacy posture flagged in the original doc (§ "Real reasons the split exists" #2).
- Aligns with the "PAI = cortex" framing — TELOS is *operational* identity, not reference.
- Keeps `_Verified:_ / _Superseded by:_` (Tier A3) usable as designed.

**Decision needed:** ☐ A · ☐ B · ☐ C · ☐ alternative: ____________

---

### Decision 3 — Daily / running log layer

**Question:** Where do daily ambient notes live? PAI `MEMORY/DAILY/` (Tier A1) or PKM `00_Inbox/` or PKM `00_Self/`?

**Proposed default:**
- **PAI `MEMORY/DAILY/YYYY-MM-DD.md`** — session traces, ambient activity log, machine-written by sidecar/harvest.
- **PKM `00_Self/journal/`** — human-written daily journaling, if/when you do that. Untouched by PAI.

These don't overlap. PAI's DAILY/ is a *machine* log; PKM's journal is a *human* log. No competition.

**Decision needed:** ☐ accept default · ☐ alternative: ____________

---

### Decision 4 — Episodic memory layer (MemPalace yes/no)

**Question:** Do we want word-for-word recall across past Copilot sessions, given the cost (~500 MB Python stack, vendored at `~/.pai/vendor/mempalace/`)?

**For:**
- The one capability neither PAI nor DEVONthink provides today.
- Local-first, no API keys, no cloud.
- M5 Max has plenty of headroom for ChromaDB.
- Drives behavior we already do manually ("what did we say about NH 7308 hose two weeks ago" → grep events.jsonl).

**Against:**
- Adds non-trivial Python dependency surface to PAI.
- 1-session lag (Copilot has no `stop`/`precompact` hooks; MemPalace fills via `harvest-session.sh` after the fact).
- Sub-tool of last resort — most queries answer fine from PAI MEMORY/ + DEVONthink today.

**Recommended: defer to Tier B.** Build Tier A first (DAILY/ + AAAK pointers + temporal tags). Re-evaluate MemPalace after 2–4 weeks of Tier A in lived use. If you find yourself wanting verbatim recall more than once a week, install it. If not, skip.

**Decision needed:** ☐ install Tier B now · ☐ defer until Tier A proves out (recommended) · ☐ skip permanently

---

### Decision 5 — Karpathy-style LLM wiki (workflow, not location)

**Correction (2026-04-26):** an earlier draft of this section referenced a `80_Wiki/` location proposed in `~/projects/mini-ak-wiki/integrated-pkm-plan.md`. **Reality:** the wiki already lives at `~/Library/CloudStorage/OneDrive-GreatBayLabs/PKM/10_Knowledge/wiki/` — correctly placed in PARA as a `10_Knowledge` (Areas of Knowledge) subfolder, with `INDEX.md` and ~40 articles. Putting it at top-level `80_Wiki/` would have diluted PARA. The location question is settled.

**The actual question:** does the wiki's manual compile / lint / INDEX-maintenance workflow (mini-ak-wiki `CLAUDE.md`) still earn its keep, given DEVONthink See Also + AI classify now do most of the cross-linking work natively?

**Two candidates:**

A. **Keep the workflow, in place.** Wiki stays at `10_Knowledge/wiki/`. mini-ak-wiki `CLAUDE.md` keeps its compile/lint/INDEX conventions. DT indexes the wiki alongside everything else. AAAK pointers can target wiki articles by file path. Nothing moves.

B. **Retire the workflow, keep the articles.** Wiki articles stay at `10_Knowledge/wiki/` as ordinary markdown. The mini-ak-wiki repo's compile/lint/INDEX-maintenance overhead retires. DT See Also takes over cross-linking. `INDEX.md` stops being hand-maintained.

**Recommended: A — keep the workflow.** With the wiki already correctly placed in PARA, the workflow's cost is one knowledge-area's editorial discipline, not a parallel-system tax. The two-brains framing was about location and conventions, not the wiki itself; both have already been resolved by the `10_Knowledge/wiki/` placement.

**Decision needed:** ☐ A — keep workflow (recommended) · ☐ B — retire workflow, keep articles · ☐ alternative: ____________

---

### Decision 6 — Global Copilot hook (cross-repo PAI awareness)

Carried forward unchanged from the original 2026-04-22 doc. Already implemented as the **guarded global hook** in `~/.copilot/copilot-instructions.md` § "PAI context (conditional)" — fires only when `PAI_SESSION_ID` is set.

**Recommendation: leave as is.** Working as designed. No further decision needed.

**Decision needed:** ☐ confirm "leave as is"

---

## Cross-store conventions (apply once decisions land)

These are mechanical conventions that follow from the above:

1. **AAAK pointer targets are heterogeneous.** A pointer (`§ ptr → ...`) may resolve to a file path, a `devonthink://<db-uuid>/<record-uuid>` URL, or a `mempalace://D-<id>` reference. `append-pointer.sh` validates the scheme; `verify-pointers.sh` lints existence.
2. **Promotion writes both locations into the pointer.** When a PAI artifact promotes to DEVONthink, the existing AAAK pointer gains a second `§ ptr →` line for the DT URL. Old PAI path is *not* removed (so the pointer remains a history). A `canonical:` tag on the pointer header indicates which is currently authoritative.
3. **TELOS facts carry temporal tags** (`_Verified: YYYY-MM-DD_`, `_Superseded by: <pointer>_`). Tier A3.
4. **DAILY/ machine log never journals personal feelings.** Strictly machine events. Privacy-equivalent to events.jsonl.
5. **One CLAUDE.md per surface.** The mini-ak-wiki one collapses if Decision 5 = collapse. PAI's `~/.copilot/copilot-instructions.md` (global) and `tasks/lessons.md` (repo) stay — they cover non-overlapping ground.

---

## What I am NOT proposing

- ❌ Migrating `~/.pai/MEMORY/` into DEVONthink.
- ❌ Moving TELOS into the wiki / OneDrive (the original 2026-04-22 candidate). Privacy posture rules this out.
- ❌ Deleting any existing data. All migrations are copy-then-redirect, with a retention window.
- ❌ Building a new tool or store before the decisions land.

---

## Approval matrix

| # | Decision | Recommended | Your call |
|---|---|---|---|
| 1 | Operational vs reference research | Default (PAI hot → DT cold, with promote step) | ☐ |
| 2 | TELOS state-of-record | A — PAI canonical, PKM hosts artifacts | ☐ |
| 3 | Daily log layer | Default (PAI machine-log, PKM human-journal, no overlap) | ☐ |
| 4 | MemPalace install | Defer to after Tier A in lived use | ☐ |
| 5 | Wiki workflow (already at `10_Knowledge/wiki/`) | A — keep workflow in place | ☐ |
| 6 | Global Copilot hook | Leave as is (already guarded) | ☐ |

Sign here when ready: _________________ Date: __________

---

## Once approved

The follow-on plan is mechanical:

1. Update `tasks/memory-incorporation-plan.md` with chosen Decision 4 outcome (Tier B gated or not) and Decision 1 promotion path.
2. Extend `append-pointer.sh` (Tier A2) to accept heterogeneous pointer targets per Decision 1 + cross-store conventions.
3. If Decision 5 = B (retire workflow): archive `~/projects/mini-ak-wiki/` reference doc to PKM, retire its CLAUDE.md, fold its remaining decisions into this doc. If Decision 5 = A (keep workflow): leave mini-ak-wiki CLAUDE.md in place; just update its location reference from `80_Wiki/` to `10_Knowledge/wiki/` if not already correct.
4. Close `active.md` queued items: "PAI ↔ Wiki Boundary Decision" and the Phase-2 portion of "Consolidate Projects Tracking."
