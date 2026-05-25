# PKM Phase 2 Consolidation Plan

**Status:** Draft for iteration  
**Created:** 2026-05-25  
**Scope:** Planning only. Do not move, delete, or restructure files from this document alone.

## 1. Working Doctrine

PKM is the constructed knowledge layer. DEVONthink and `WorkingStorage/Data` are captured/raw layers.

The target is not to merge everything into one folder. The target is to make each layer's job explicit, preserve raw archives, and promote only selected material into the curated PKM.

| Layer | Role | Canonical? | Notes |
|---|---|---:|---|
| `~/Library/CloudStorage/OneDrive-GreatBayLabs/PKM` | Curated/constructed knowledge, active projects, records | Yes | Must remain readable without DEVONthink |
| DEVONthink databases | Capture, indexing, AI classification, search | No, except transient inbox/raw custody | DEVONthink should augment PKM, not own constructed truth |
| `~/WorkingStorage/Data` | Historical captured archive | Raw canonical archive | Evaluate and promote selectively; do not wholesale restructure |
| `~/projects/*` | Code, agents, tooling, workflow engines | Code canonical only | Durable outputs/state should promote into PKM when useful |
| App-local databases | Operational state | No | Keep only as runtime state unless exported/promoted |

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

Initial interpretation: this is captured history, not a folder tree to "fix" by renaming everything. It needs sampling, provenance preservation, and selective promotion.

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

Planning assumption: DEVONthink should index and enrich the PKM, but the durable curated files should remain in OneDrive PKM.

### Project/tooling folders

- `Personal_AI_Infrastructure`: full PAI development/migration workspace.
- `pai-copilot`: corporate-friendly PAI layer for Copilot CLI.
- `research-agent`: recurring research workflow engine with local runtime data.

These are not knowledge homes. They are engines. Durable outputs, decisions, and synthesized findings should land in PKM.

## 3. Phase 2 Goals

- Preserve the PKM as the curated, constructed knowledge system.
- Keep raw capture archives stable and auditable.
- Make DEVONthink an indexing/classification/search layer over the PKM, not the owner of curated truth.
- Define explicit promotion lanes from captured material into curated PKM.
- Reduce source-of-truth ambiguity across PAI, research-agent, DEVONthink, and OneDrive.
- Avoid destructive or premature restructuring of `WorkingStorage/Data`.

## 4. Non-Goals

- No wholesale restructuring of `WorkingStorage/Data`.
- No bulk moves without a manifest and rollback plan.
- No deletion of raw historical captures during Phase 2.
- No migration of app-local databases into PKM as opaque blobs.
- No attempt to make DEVONthink the sole system of record.
- No attempt to collapse all agent/tooling repos into one repo.

## 5. Ideal State Criteria

- [ ] Every major storage root has a documented role and source-of-truth status.
- [ ] The PKM remains independently usable through OneDrive files without DEVONthink.
- [ ] DEVONthink indexing of the PKM is treated as an add-on capability.
- [ ] `WorkingStorage/Data` has a manifest and evaluation status by top-level folder.
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

### Workstream D: `WorkingStorage/Data` evaluation

Do not move the archive. Build an inventory and sample it.

For each top-level folder:

- Size
- File count
- Dominant extensions
- Date range if cheaply available
- Sensitivity
- Topic/domain
- Duplicate likelihood
- PKM promotion value
- Recommended disposition

Disposition values:

- `raw-only`
- `sample-more`
- `promote-selected`
- `synthesize-to-wiki`
- `candidate-cold-archive`
- `needs-human-review`

### Workstream E: DEVONthink role cleanup

Confirm intended database roles:

- Which DT database indexes PKM?
- Which databases are legacy/raw archives?
- Which inboxes are active?
- Which databases can be left alone as historical capture stores?

Desired rule: DEVONthink can search, classify, tag, and expose; OneDrive PKM owns constructed files.

### Workstream F: Promotion workflow

Define a standard promotion path:

1. Capture lands in DEVONthink inbox, `PKM/00_Inbox`, research-agent output, or `WorkingStorage/Data`.
2. Triage decides whether it is a record, reference, or synthesizable knowledge.
3. Permanent PKM location is selected.
4. Provenance is preserved.
5. DEVONthink index/tag update happens after file placement.
6. Wiki synthesis happens only for material that teaches something reusable.

## 7. Historical Archive Evaluation Method

Start with sampling, not moving.

For each major `WorkingStorage/Data` folder:

1. Generate a manifest.
2. Sample 10-25 representative files by type and age.
3. Identify whether the folder is mostly records, reference material, correspondence, project history, or mixed.
4. Decide whether the folder deserves promotion work.
5. Record disposition.

Suggested first-pass priority:

1. `Tech notes`, `AI`, `privacy-security`, `career` - likely high knowledge reuse.
2. `Legal`, `Financial`, `Medical Records` - sensitive records; promote cautiously.
3. `Politics`, `Legislative Research`, `New Hampshire` - possible knowledge/project value.
4. `homesteading`, `Outdoors`, `HamRadio` - reference/project value.
5. Email-heavy folders - defer until there is a dedicated email policy.

## 8. Risks and Guardrails

| Risk | Guardrail |
|---|---|
| Premature restructuring destroys context | Inventory and sample before moving |
| DEVONthink becomes hidden source of truth | Keep curated files in OneDrive PKM |
| Duplicates multiply | Prefer provenance links and manifests before copying |
| Sensitive material gets promoted too broadly | Tag sensitivity during evaluation |
| Project/runtime DBs become knowledge silos | Promote durable outputs, not runtime state |
| Archive cleanup becomes endless | Use folder-level dispositions, not item-level perfection |

## 9. Open Questions

- Should the first Phase 2 execution target be project/task state sprawl or `WorkingStorage/Data` inventory?
- Should there be a formal `PKM/20_Reference/Raw Historical Archive Index/` or should archive manifests live under `30_Projects/PKMBuildout/`?
- Which DEVONthink database is intended to be the long-term PKM index: `PKM.dtBase2`, `Main.dtBase2`, or both?
- Should sensitive record categories use a separate PKM convention, or is the existing folder structure plus DEVONthink tagging enough?
- What is the desired lifecycle for root-level PKM files like `copilot-shared-state.md` and `copilot-instructions.md`?

## 10. Recommended Next Move

Start with **Workstream B: Project and task state consolidation**, then do **Workstream D: `WorkingStorage/Data` evaluation**.

Reason: project/task state sprawl is smaller and active. Cleaning it up first creates better operating discipline before touching the large historical archive.

