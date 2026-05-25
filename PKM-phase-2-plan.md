# PKM Phase 2 Consolidation Plan

**Status:** Draft for iteration  
**Created:** 2026-05-25  
**Scope:** Planning only. Do not move, delete, or restructure files from this document alone.

## 1. Working Doctrine

The OneDrive PKM is the canonical home for curated knowledge, records, active project material, and constructed/synthesized outputs.

OneDrive also has a second strategic role: it is material that Microsoft 365 Copilot can access and reason over away from the main machine. That means cloud placement is not only a backup/sync decision; it is also an AI-availability decision.

DEVONthink is a tool layer, not a knowledge area. It indexes, classifies, searches, and exposes material from the PKM and raw archives. The distinction is blurry when DEVONthink acts as an inbox or temporary capture surface, but durable curated truth should remain in ordinary files in the OneDrive PKM.

`~/WorkingStorage/Data` is a raw historical source archive. The current intent is to keep it unchanged as source material, while using DEVONthink indexing to make it searchable and useful. "Evaluate" means understand what is there and decide what, if anything, should be copied, referenced, or synthesized into PKM; it does not mean reorganizing the raw archive.

The target is not to merge everything into one folder. The target is to make each layer's job explicit, preserve raw archives, and promote or synthesize only selected material into the curated PKM.

| Layer | Role | Canonical? | Notes |
|---|---|---:|---|
| `~/Library/CloudStorage/OneDrive-GreatBayLabs/PKM` | Curated/constructed knowledge, active project material, records, selected AI-available reference/source material | Yes | Must remain readable without DEVONthink; accessible to Microsoft 365 Copilot |
| DEVONthink databases | Tool layer for indexing, classification, search, and inbox/capture workflows | Tool canonical only | DEVONthink should augment PKM and raw archives, not own constructed truth |
| `~/WorkingStorage/Data` | Raw historical source archive | Raw source canonical | Keep unchanged; index/search via DEVONthink; copy/reference/synthesize selected material into PKM |
| `~/projects/*` | Code, agents, tooling, workflow engines | Code canonical only | Durable outputs/state should promote into PKM when useful |
| `PKM/30_Projects/*` | Active project knowledge/workspace material | PKM canonical for project records and synthesized project context | Distinct from code repos; this is the project knowledge working set |
| App-local databases | Runtime/operational state owned by a specific app or tool | No, unless exported to ordinary files | Examples include agent runtime stores, caches, SQLite databases, browser/app indexes, and similar implementation details |

## 2. Current Observed State

### Main roots

- `~/WorkingStorage` is about 23 GB.
- `~/WorkingStorage/Data` is about 10 GB.
- `~/Library/CloudStorage/OneDrive-GreatBayLabs/PKM` is about 1.8 GB.
- `~/projects/Personal_AI_Infrastructure` is about 697 MB.
- `~/projects/pai-copilot` is about 3.5 MB.

### `WorkingStorage/Data`

Large historical archive, mostly PDFs, email, HTML, and images.

Largest visible top-level folders by count or size include:

- `Financial`
- `Deborah`
- `mail`
- `Politics`
- `fdn.enex`
- `covid`
- `Legal`
- `ImportedDocsFromWhitebox`
- `Personal`
- `homesteading`

Initial interpretation: this is source material, not a folder tree to "fix" by renaming everything. It should remain unchanged. Any Phase 2 work should create external manifests, notes, references, or synthesized PKM outputs without reorganizing the archive itself.

### PKM

Current PKM structure already reflects a workable Johnny Decimal / PARA hybrid:

- `00_Inbox`
- `00_Self`
- `10_Areas`
- `10_Knowledge`
- `20_Reference`
- `30_Projects`
- `40_Legislative`
- `50_Personal`
- `60_Finance`
- `70_Career`
- `90_Archive`

The strongest existing principle: if Robley or an agent synthesizes it, it belongs in `10_Knowledge`; if someone else authored it, it generally belongs in `20_Reference`; records go into the relevant life area.

### DEVONthink

Observed databases include:

- `PKM.dtBase2`
- `DEVONthink 2.dtBase2`
- `Main.dtBase2`
- `DT-Books.dtBase2`
- `Programming.dtBase2`
- `Research.dtBase2`
- `email-dtp.dtBase2`

Planning assumption: DEVONthink should index and enrich the PKM and all of `WorkingStorage/Data`, but durable curated files should remain in OneDrive PKM and the raw archive should remain unchanged.

### Project/tooling folders

- `Personal_AI_Infrastructure`: full PAI development/migration workspace.
- `pai-copilot`: corporate-friendly PAI layer for Copilot CLI.
- `research-agent`: recurring research workflow engine with local runtime data.

These are not knowledge homes. They are engines. Durable outputs, decisions, and synthesized findings should land in PKM.

This is separate from `PKM/30_Projects`, which is intended to be the PKM working set for active project material.

## 3. Phase 2 Goals

- Preserve the PKM as the curated, constructed knowledge system.
- Preserve OneDrive as the cloud AI-reasoning surface for selected material that should be available to Microsoft 365 Copilot.
- Keep raw source archives stable, unchanged, indexed, and auditable.
- Make DEVONthink an indexing/classification/search layer over the PKM, not the owner of curated truth.
- Define explicit promotion lanes from captured material into curated PKM.
- Reduce source-of-truth ambiguity across PAI, research-agent, DEVONthink, and OneDrive.
- Avoid restructuring `WorkingStorage/Data`.

## 4. Non-Goals

- No restructuring of `WorkingStorage/Data`.
- No bulk moves without a manifest and rollback plan.
- No deletion of raw historical captures during Phase 2.
- No migration of app-local databases into PKM as opaque blobs.
- No attempt to make DEVONthink the sole system of record.
- No attempt to collapse all agent/tooling repos into one repo.

## 5. Ideal State Criteria

- [ ] Every major storage root has a documented role and source-of-truth status.
- [ ] The PKM remains independently usable through OneDrive files without DEVONthink.
- [ ] DEVONthink indexing of the PKM is treated as an add-on capability.
- [ ] `WorkingStorage/Data` has an external manifest/index summary by top-level folder, without changing the archive.
- [ ] Promotion lanes from raw capture to curated PKM are documented.
- [ ] Research-agent durable outputs have a defined PKM destination.
- [ ] PAI/project task state has one preferred durable location.
- [ ] Any future move batch has a preflight checklist, move log, and rollback note.

## 6. Proposed Workstreams

### Workstream A: Boundary and source-of-truth map

Create a compact map of all relevant roots:

- Path
- Role
- Canonical status
- Backed up/synced status
- Owner/tool
- What belongs there
- What does not belong there
- Promotion path, if any
- Whether the material should be available to Microsoft 365 Copilot

Output candidate: `PKM/10_Knowledge/wiki/pkm-storage-boundaries.md` or a project note under `PKM/30_Projects/PKMBuildout/`.

### Workstream B: Project and task state consolidation

Resolve active project/task sprawl before touching the large archive.

Questions to answer:

- Which project state belongs in `PKM/10_Knowledge/copilot-project-state/`?
- Which state should remain repo-local under `tasks/`?
- Which project folders under `PKM/30_Projects/` are active versus archival?
- What should happen to `copilot-shared-state.md` and root-level PKM Copilot files?

Recommended first target because it is small, active, and affects every future session.

### Workstream C: Research-agent output promotion

Keep `research-agent/data` as app/runtime state. Promote durable outputs to PKM.

Candidate policy:

- Raw run data: stay in `research-agent/data`.
- Generated reports: copy or move to `PKM/20_Reference` or `PKM/30_Projects/<project>`.
- Synthesized reusable knowledge: file into `PKM/10_Knowledge/wiki`.
- Operational lessons: PAI memory or project task state first; promote to wiki only when generally reusable.

### Workstream D: `WorkingStorage/Data` index and source-map

Do not move or restructure the archive. It is raw source material and is already indexed by DEVONthink. Build an external source map that explains what is there and where selected material might be useful.

For each top-level folder, document:

- Size
- File count
- Dominant extensions
- Date range if cheaply available
- Sensitivity
- Topic/domain
- Duplicate likelihood
- PKM promotion value
- Recommended PKM relationship

PKM relationship values:

- `raw-only`
- `reference-from-pkm`
- `copy-selected-to-pkm`
- `synthesize-to-wiki`
- `needs-human-review`

### Workstream E: DEVONthink role clarification

Confirm intended database roles:

- Which DT database indexes PKM?
- Which DT database indexes all of `WorkingStorage/Data`?
- Which databases are legacy/raw archives?
- Which inboxes are active?
- Which databases can be left alone as historical capture stores?

Desired rule: DEVONthink can search, classify, tag, and expose; OneDrive PKM owns constructed files; `WorkingStorage/Data` remains unchanged raw source material.

### Workstream F: Promotion workflow

Define a standard promotion path:

1. Capture lands in DEVONthink inbox, `PKM/00_Inbox`, research-agent output, or already exists in `WorkingStorage/Data`.
2. Triage decides whether it is a record, reference, or synthesizable knowledge.
3. Decide whether cloud AI availability via Microsoft 365 Copilot is useful enough to justify OneDrive placement.
4. Permanent PKM location is selected.
5. Provenance is preserved.
6. DEVONthink index/tag update happens after file placement, when applicable.
7. Wiki synthesis happens only for material that teaches something reusable.

## 7. Historical Archive Source-Mapping Method

Start with external source mapping, not moving.

For each major `WorkingStorage/Data` folder:

1. Generate or update an external manifest.
2. Sample 10-25 representative files by type and age.
3. Identify whether the folder is mostly records, reference material, correspondence, project history, or mixed.
4. Decide whether the folder deserves PKM reference, selected copy-out, or synthesis work.
5. Record the PKM relationship.

Suggested first-pass priority:

1. `Tech notes`, `AI`, `privacy-security`, `career` - likely high knowledge reuse.
2. `Legal`, `Financial`, `Medical Records` - sensitive records; promote cautiously.
3. `Politics`, `Legislative Research`, `New Hampshire` - possible knowledge/project value.
4. `homesteading`, `Outdoors`, `HamRadio` - reference/project value.
5. Email-heavy folders - defer until there is a dedicated email policy.

## 8. Risks and Guardrails

| Risk | Guardrail |
|---|---|
| Premature restructuring destroys context | Do not restructure `WorkingStorage/Data`; use external source maps |
| DEVONthink becomes hidden source of truth | Keep curated files in OneDrive PKM |
| Duplicates multiply | Prefer provenance links and manifests before copying |
| Sensitive material gets promoted too broadly | Tag sensitivity during source mapping |
| Project/runtime DBs become knowledge silos | Promote durable outputs, not runtime state |
| Archive cleanup becomes endless | Use folder-level PKM relationships, not item-level perfection |

## 9. Session Decisions and Resume Context

Decisions clarified on 2026-05-25:

- OneDrive PKM is the canonical cloud home for curated knowledge, records, active project material, and synthesized outputs.
- OneDrive also matters because Microsoft 365 Copilot can reason over material stored there while away from the main system.
- DEVONthink is a tool/index/search/classification layer, not a knowledge area or source-of-truth store.
- `~/WorkingStorage/Data` is the unchanged raw historical source archive and is indexed by DEVONthink.
- Because `~/WorkingStorage/Data` is about 10 GB and OneDrive for Business plans commonly provide about 1 TB per user, mirroring public harvested source material into OneDrive is reasonable if clearly marked as a mirror.
- The recommended model is mirror, not migrate: keep `~/WorkingStorage/Data` canonical locally and create an AI-available OneDrive mirror only if useful for M365 Copilot reasoning.
- Suggested OneDrive mirror naming: `PKM/20_Reference/AI_Available_Source_Material/Data` or similar, with a note that canonical source remains `~/WorkingStorage/Data`.

OneDrive incident context:

- A second OneDrive install created a stale "OneDrive 2" File Provider domain and a nested symlink from the real OneDrive folder to `OneDrive2-GreatBayLabs`.
- The nested symlink/cache entries were removed, and the real OneDrive root was verified intact at `~/Library/CloudStorage/OneDrive-GreatBayLabs`.
- Verified present: `PKM`, `PKM/10_Knowledge`, `PKM/20_Reference`, and `PKM/30_Projects`.
- Remaining cleanup item: macOS still reports a stale File Provider/LaunchServices registration for "OneDrive 2" pointing at the deleted/trash app, plus an empty `~/Library/CloudStorage/OneDrive2-GreatBayLabs` folder that has File Provider ACL protection.

## 10. Open Questions

- Should the first Phase 2 execution target be project/task state sprawl or the `WorkingStorage/Data` source map?
- Should there be a formal `PKM/20_Reference/Raw Historical Archive Index/` or should archive manifests live under `30_Projects/PKMBuildout/`?
- Which DEVONthink database is intended to be the long-term PKM index: `PKM.dtBase2`, `Main.dtBase2`, or both?
- Should sensitive record categories use a separate PKM convention, or is the existing folder structure plus DEVONthink tagging enough?
- What is the desired lifecycle for root-level PKM files like `copilot-shared-state.md` and `copilot-instructions.md`?
- Should the AI-available Data mirror live inside `20_Reference`, a dedicated `20_Reference/AI_Available_Source_Material`, or a separate top-level PKM area?

## 11. Recommended Next Move

Start with **Workstream B: Project and task state consolidation**, then do **Workstream D: `WorkingStorage/Data` index and source-map**.

Reason: project/task state sprawl is smaller and active. Cleaning it up first creates better operating discipline before touching the large historical archive.
