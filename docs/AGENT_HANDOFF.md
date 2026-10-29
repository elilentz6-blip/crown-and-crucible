# Crown & Crucible: Multi-Agent Coordination & Handoff Protocol

**Document Version**: 2.0.0  
**Status**: Authoritative Multi-Agent Operational Protocol  
**Lead Author**: Agent 4 (Chief Architect & Integration Lead)  
**Co-Authors**: Agent 1 (Source Doc Lead), Agent 2 (Test & Runtime Lead), Agent 3 (Narrative & Design Lead)  
**Project**: Crown & Crucible (`BLANK GAME.yyp`)  
**Target Engine**: GameMaker 2024.14.4.222 (Runtime 2024.14.4.268)  
**Date**: October 2026  

---

## 1. Multi-Agent Governance & Integrity Directives

To execute large-scale, concurrent engineering tasks on Crown & Crucible without merge conflicts, code regressions, or architectural drift, all contributing agents operate under strict jurisdictional boundaries and four non-negotiable integrity directives:

1. **Zero New Features**: No agent may invent, scaffold, or introduce unrequested gameplay systems, items, or mechanics.
2. **Zero Architectural Redesign**: No agent may refactor, rewrite, or alter existing working gameplay logic, math, combat pipelines, or rendering code.
3. **Zero Resource Deletion**: Existing scripts, objects, rooms, assets, or tools must never be removed or disabled.
4. **Strict Single-Agent File Ownership**: Under no circumstance may two agents edit the same file concurrently. Every file in the repository is locked to an exclusive agent owner.

---

## 2. Definitive File Ownership & Lock Matrix

The following matrix delineates absolute file ownership across the multi-agent team. Editing a file outside your assigned domain is a direct protocol violation:

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                          DEFINITIVE FILE OWNERSHIP MATRIX                              │
├─────────────────┬─────────────────────────────────────────────────┬────────────────────┤
│ Agent Role      │ Exclusively Owned Files & Directories           │ Permitted Scope    │
├─────────────────┼─────────────────────────────────────────────────┼────────────────────┤
│ **Agent 1**     │ • `scripts/**/*.gml` (All 33 script files)      │ JSDoc headers,     │
│ Source Doc      │ • `objects/**/*.gml` (All 16 event files)       │ function comments, │
│ Lead            │ • `docs/OBJECT_AND_SCRIPT_REFERENCE.md`         │ param typing, and  │
│                 │                                                 │ Bug B12 fix only.  │
├─────────────────┼─────────────────────────────────────────────────┼────────────────────┤
│ **Agent 2**     │ • `docs/TEST_REPORT.md`                         │ Node test suites,  │
│ Test & Runtime  │                                                 │ Igor compilation,  │
│ Lead            │                                                 │ Mac_Runner launch, │
│                 │                                                 │ verification tiers.│
├─────────────────┼─────────────────────────────────────────────────┼────────────────────┤
│ **Agent 3**     │ • `docs/STORY_BIBLE.md`                         │ World cosmology,   │
│ Narrative &     │ • `docs/QUEST_AND_DIALOGUE_REFERENCE.md`        │ characters, quests,│
│ Design Lead     │                                                 │ civil war, endings,│
│                 │                                                 │ War Clock proposal.│
├─────────────────┼─────────────────────────────────────────────────┼────────────────────┤
│ **Agent 4**     │ • `CROWN_AND_CRUCIBLE_MASTER_DOSSIER.md`        │ Master Dossier,    │
│ Chief Architect │ • `docs/PROJECT_OVERVIEW.md`                    │ System synthesis,  │
│ & Integration   │ • `docs/ARCHITECTURE.md`                        │ Inventory tables,  │
│ Lead            │ • `docs/SYSTEM_INVENTORY.md`                    │ Save v2 schema,    │
│ (Current Agent) │ • `docs/SAVE_DATA_SCHEMA.md`                    │ Bug registry,      │
│                 │ • `docs/KNOWN_BUGS.md`                          │ Coordination guide.│
│                 │ • `docs/AGENT_HANDOFF.md`                       │                    │
└─────────────────┴─────────────────────────────────────────────────┴────────────────────┘
```

---

## 3. The 9 Standalone Architecture Guides in `docs/`

The complete documentation suite for Crown & Crucible is partitioned into nine cross-referenced standalone references:

| File Path in `docs/` | Title & Purpose | Responsible Agent Owner |
|---|---|---|
| `docs/PROJECT_OVERVIEW.md` | Executive brief, genre synthesis, core loop, technology stack, directory layout | **Agent 4** (Integration Lead) |
| `docs/ARCHITECTURE.md` | Object hierarchy, per-frame event pipeline, subsystem clusters, world layout, dependency cycles | **Agent 4** (Integration Lead) |
| `docs/SYSTEM_INVENTORY.md` | Exhaustive inventories: 12 weapons, 7 armors, 6 relics, 12 cards, 3 foes, 16 NPCs, 9 retinue, landmarks | **Agent 4** (Integration Lead) |
| `docs/SAVE_DATA_SCHEMA.md` | Complete Save v2 JSON specification, hero state, equipment payload, warfare, retinue, and migrations | **Agent 4** (Integration Lead) |
| `docs/KNOWN_BUGS.md` | Master defect registry B1–B12, detailed root causes, resolutions, visual debt, and toolchain findings | **Agent 4** (Integration Lead) |
| `docs/AGENT_HANDOFF.md` | Multi-agent governance, file locking protocols, build commands, and handoff standards | **Agent 4** (Integration Lead) |
| `docs/TEST_REPORT.md` | Four-tier verification report, 7 test suites breakdown (121 tests), Igor compilation, runtime telemetry | **Agent 2** (Test Lead) |
| `docs/STORY_BIBLE.md` | Canonical world bible, cosmology, Greenmere Vale geography, Rowan canon, 4 factions, 4 endings | **Agent 3** (Narrative Lead) |
| `docs/QUEST_AND_DIALOGUE_REFERENCE.md` | Dialogue scripts, branching conditions, stage triggers, and rewards for all 35 quests and contracts | **Agent 3** (Narrative Lead) |
| `docs/OBJECT_AND_SCRIPT_REFERENCE.md` | JSDoc index of all 4 objects, core `obj_game` events, and all 33 scripts / 364 functions | **Agent 1** (Source Doc Lead) |

---

## 4. Multi-Agent Verification & Build Commands

Before declaring any task or milestone complete, an agent must execute and document the following verification commands:

### 4.1 Automated Logic & Integration Tests
```bash
cd "/Users/elilentz/GameMakerProjects/BLANK GAME"
/opt/homebrew/bin/node tests/run_all.cjs
```
- **Acceptance Criterion**: Must conclude with `7/7 suites passed` and all 121 individual tests reporting `PASS`.

### 4.2 Static GML Syntax & AST Verification
```bash
/opt/homebrew/bin/node tests/gml_translator.test.cjs
```
- **Acceptance Criterion**: Must output `5 translator tests passed`, confirming all 33 scripts and 4 `obj_game` events parse cleanly without syntax errors.

### 4.3 Native GameMaker Headless Compilation
```bash
/Users/Shared/GameMakerStudio2/Cache/runtimes/runtime-2024.14.4.268/bin/igor/osx/arm64/Igor \
  --rp=/Users/Shared/GameMakerStudio2/Cache/runtimes/runtime-2024.14.4.268 \
  --runtime=VM \
  -options="/tmp/GameMakerStudio2/GMS2TEMP/build.bff" \
  -v -- Mac PackageZip
```
- **Acceptance Criterion**: Must report `Final Compile finished` and successfully write bytecode binary `game.ios` (1.55 MB).

### 4.4 Ad-Hoc AMFI Code Signing & Native Launch
```bash
# Ad-hoc sign the bundle to satisfy macOS ARM64 kernel security:
codesign --force --deep -s - "/Users/elilentz/gamemakerstudio2/GM_MAC/BLANK_GAME/BLANK GAME.app"

# Verify 5-second launch into main loop:
"/Users/elilentz/gamemakerstudio2/GM_MAC/BLANK_GAME/BLANK GAME.app/Contents/MacOS/Mac_Runner" -outputdebugstring
```
- **Acceptance Criterion**: Must report `Entering main loop.` running at 60 FPS on Metal OpenGL 2.1.

---

## 5. Formal 5-Component Handoff Protocol

Every agent completing a milestone must generate a `handoff.md` file within their designated working directory (`.agents/teamwork/<agent_id>/handoff.md`) containing the five mandatory sections:

1. **Observation**: Exact file paths, line numbers, tool outputs, verbatim errors, and quantitative measurements. Quote directly without speculation.
2. **Logic Chain**: Step-by-step deductive reasoning linking observations to conclusions.
3. **Caveats**: Explicit boundaries of investigation, tool limitations, assumptions made, and areas not verified.
4. **Conclusion**: Final assessment directly supported by the logic chain, actionable, and strictly scoped.
5. **Verification Method**: Concrete terminal commands, reproducible test scripts, and exact invalidation conditions enabling peer agents or auditors to independently verify the claims.

---

## 6. Git & Repository Protection Guidelines

- **Untracked Directory Alert**: The GameMaker project folder `/Users/elilentz/GameMakerProjects/BLANK GAME` is **not** an independent Git repository. The enclosing git repository is the user's home directory (`~/.git`).
- **Prohibited Git Commands**: Contributing agents must **NEVER** run `git add .`, `git commit`, `git checkout`, `git reset`, or `git push` from within `BLANK GAME`. Doing so risks polluting the user's personal home directory repository with thousands of binary cache artifacts.
- **Backup Archive Practice**: All milestone checkpoints and backups are stored as standalone ZIP archives within `~/GameMakerProjects/_backups/`.
