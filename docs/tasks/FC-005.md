# Current Task

## ID

FC-005

## Status

COMPLETE

## Assigned Roles

- Primary proposal owner: Software Architect
- Required acceptance gate: Reviewer / Optimization Critic operating in a fresh Reviewer context after the proposal is produced

## Objective

Produce one minimal canonical architecture proposal that establishes the system boundary, state ownership, simulation lifecycle, vanilla handoff, context abstraction, persistence model, and minimum module responsibilities needed to constrain the next Functional Coolers production task.

The proposal must describe the current implementation separately from accepted constraints, proposed architecture, unresolved questions, and runtime assumptions requiring evidence. It must not change production behavior or convert observed vanilla refresh timing into an undocumented causal mechanism.

Because this is the project's first canonical architecture baseline, the proposal must receive one fresh, procedurally independent Reviewer pass before Bart considers accepting it. This is a task-specific FC-005 risk-control experiment, not a universal workflow rule.

Bart accepted FC-005, the Architect produced the bounded proposal, and the required fresh Reviewer pass identified five findings. The Architect materially revised the proposal, the focused closure review classified all five findings as `RESOLVED` with no material new finding, and Bart explicitly accepted `docs/ARCHITECTURE.md` as canonical architecture on 2026-08-26.

## Why Now

Functional Coolers has an elapsed-time managed prototype and two completed empirical evidence chains, but no canonical architecture baseline. Further production changes would otherwise risk preserving prototype accidents, assigning state inconsistently, or coupling the mod to vanilla update opportunities whose internal mechanism remains unresolved.

The Project Charter already establishes the Cooler as the thermodynamic system and its location as a changing boundary condition. The next justified step is to translate that accepted product principle, the present implementation, and verified runtime constraints into the smallest architecture proposal capable of guiding a later implementation task.

## Canonical Inputs

The Architect must use:

- AGENTS.md
- AI_WORKFLOW.md
- CURRENT_TASK.md
- ai/ARCHITECT.md
- docs/PROJECT_CHARTER.md
- docs/STATUS.md
- relevant architecture and technical items in docs/TODO.md
- 42/media/lua/server/FunctionalCoolers.lua as evidence of current implementation, not accepted architecture
- docs/research/FC-003-2026-08-22.md
- docs/research/FC-004-2026-08-25.md
- referenced canonical Test Analyst records only when run-level detail is necessary

Raw runtime artifacts need not be reanalyzed unless a material ambiguity cannot be resolved from the canonical Researcher and Test Analyst records. The Architect must not replace their empirical interpretation.

The Reviewer must read the proposed `docs/ARCHITECTURE.md`, this task, the Architect and Reviewer role files, and the canonical inputs necessary to test the proposal against accepted scope and evidence. The Reviewer must not substitute a new architecture of its own.

## Current Constraints

- The Cooler is the intended thermodynamic system; location supplies a changing boundary condition.
- Thermal state must persist across supported context changes rather than reset on transfer.
- The current prototype stores Cooler, cold-pack, and managed Food fields in item modData, advances a stepped model from elapsed worldHours, and writes managed state through available Food APIs.
- The current single-file prototype combines context discovery, state initialization, simulation, vanilla Food handoff, freezer recharge, diagnostics, and test support. That organization is current implementation, not an accepted module design.
- FC-003 establishes that brief equip or inspection was not necessary for the specific observed carried/CONTROL catch-ups.
- FC-004 establishes that the sustained selected/active UI treatment package determined continuous observable refresh in one valid counterbalanced pair.
- Neither evidence chain identifies the internal vanilla scheduler, proves selection is the only update opportunity, or determines whether stale unselected Food receives no processing versus deferred catch-up.
- Save/load, long unattended catch-up, transfers, nested and vehicle contexts, and multiplayer authority remain incompletely validated.
- Multiplayer is a future accepted direction, but detailed networking design is not required for this minimum baseline.
- Calibration constants and current diagnostic structures are provisional and must not become architectural requirements merely because they exist.

## Architecture Questions to Resolve

The proposal must make the minimum coherent decisions needed for later implementation planning:

1. **System boundary:** What belongs to the Cooler thermodynamic system, and what remains an external Project Zomboid boundary condition?
2. **State ownership:** Which durable state belongs to the Cooler, cold packs, and Food; which values are derived, cached, diagnostic, or legacy; and which component is authoritative for each state while Food is managed?
3. **Simulation lifecycle:** How are initialization, elapsed-time advancement, bounded catch-up, ordinary update opportunities, context transitions, and reactivation ordered without duplicate or negative simulation?
4. **Vanilla handoff:** When does Functional Coolers take ownership of Food temperature, age, and freezing state, and how is state reconciled when Food enters, leaves, or becomes unmanaged without relying on a presumed vanilla refresh cause?
5. **Context abstraction:** What minimum boundary interface represents carried, ground, nested-container, powered cold-storage, and future vehicle contexts while preserving one thermodynamic state model?
6. **Persistence:** What must survive save/load and context transfer, where is it stored, and what initialization or migration rules are required conceptually?
7. **Module responsibilities:** What is the smallest useful separation between simulation, persistent state, context/vanilla adapters, orchestration, and diagnostics? The proposal must not predesign a large module hierarchy.
8. **Future authority boundary:** What minimum constraint keeps the design compatible with later server-authoritative multiplayer without designing the complete network protocol now?

If any answer depends materially on unverified Project Zomboid behavior, classify it as unresolved and formulate the specific Researcher question instead of inventing an API or runtime fact.

## Required Output

Under the accepted FC-005 task, the Architect may create exactly one architecture document:

- docs/ARCHITECTURE.md

The document must be explicitly marked PROPOSED — BART ACCEPTANCE REQUIRED until Bart accepts it. It must use ordinary Markdown and contain only the structure needed to distinguish:

- scope and status;
- current implementation;
- accepted product and evidence constraints;
- proposed architecture decisions with rationale;
- unresolved runtime questions and assumptions requiring evidence;
- constraints for the next implementation task;
- deliberately deferred design.

No ADR directory, architecture index, diagram set, roadmap, or parallel status document is authorized.

## Required Acceptance Sequence

1. Bart has accepted FC-005; the Architect creates the proposed `docs/ARCHITECTURE.md` within the existing scope.
2. After the proposal is ready for review, a fresh Reviewer context performs the required acceptance-gate review without modifying files.
3. The Reviewer challenges incorrect assumptions, hidden coupling, state-ownership problems, persistence and lifecycle risks, premature abstraction, unsupported runtime assumptions, conflicts with accepted evidence, and plausible simpler alternatives.
4. Reviewer findings use the existing project classifications and distinguish blocking or material corrections from optional improvements and questions.
5. The Reviewer does not own architecture decisions, directly rewrite the document, or replace the proposal with the Reviewer's preferred design.
6. The Architect remains responsible for responding to material findings and revising the proposal where justified. Rejected findings must receive an explicit rationale rather than being silently ignored.
7. If material architectural revisions result, Bart must be shown the revised proposal, the material findings, the Architect's responses, and a clear revision summary or diff before acceptance.
8. Bart remains the only authority who may accept `docs/ARCHITECTURE.md` as canonical architecture.

The Reviewer pass and Architect response may occur through explicit role handoffs; no separate review-document hierarchy is created by FC-005.

## Allowed Changes

- FC-005 is complete and authorizes no further architecture, review, research, implementation, test, production, or harness change.
- Bart's acceptance and Planner handoff authorize only the canonical acceptance-state reconciliation in `docs/ARCHITECTURE.md`, `CURRENT_TASK.md`, `docs/STATUS.md`, and `docs/TODO.md`.
- No production source under `42/` may be changed.
- Git staging, commit, push, branch, worktree, tag, and release operations require separate explicit authorization.

## Acceptance Criteria

- Exactly one architecture document is created and no existing file is modified by the Architect.
- Current implementation, accepted architecture, proposed architecture, unresolved questions, and runtime assumptions requiring evidence are clearly distinguished.
- Every proposed decision is traceable to accepted Charter direction, verified evidence, a stated engineering rationale, or an explicitly identified constraint.
- FC-003 and FC-004 constrain the proposal without being reinterpreted as proof of an undocumented vanilla mechanism.
- State ownership and the vanilla handoff are explicit enough to prevent two simultaneous authorities from silently advancing the same Food state.
- The lifecycle covers initialization, elapsed-time advancement, reactivation, context transfer, and save/load at the architectural level without inventing unverified APIs.
- Context abstraction preserves one thermodynamic system across supported locations while deferring detailed vehicle behavior.
- The minimum module responsibilities are clear enough for Planner to derive a later bounded implementation task.
- Future multiplayer compatibility is protected by a minimal authority/persistence constraint without designing a complete multiplayer subsystem.
- Calibration, UI, release work, deployment tooling, detailed experimental protocols, and implementation sequencing remain outside the architecture proposal.
- The document states what remains unresolved and gives a precise handoff to Researcher or Planner as appropriate.
- A fresh Reviewer pass occurs only after the complete architecture proposal is ready for review.
- The Reviewer explicitly assesses every challenge category required by this task and reports material findings without taking ownership of the architecture.
- The Architect responds to all material findings and makes justified revisions visible rather than silently absorbing them.
- Bart receives the reviewed proposal, material findings, Architect responses, and any material revision summary or diff before deciding acceptance.
- The resulting architecture remains a proposal until Bart explicitly accepts it.

## Out of Scope

- Modifying or refactoring production code
- Changing the Functional Coolers Test Harness
- Running or reclassifying experiments
- Drawing new empirical conclusions
- Selecting final calibration constants or balance values
- Detailed UI or tooltip design
- Detailed vehicle thermal behavior
- Complete multiplayer networking, synchronization, or protocol design
- Deployment, Git-to-runtime provenance, artifact collection, packaging, version cleanup, tags, or releases
- Creating an ADR hierarchy or comprehensive future architecture in advance
- Creating a universal Reviewer gate or changing project-wide workflow governance
- Creating a separate review-document hierarchy for this task
- Allowing the Reviewer to author a replacement architecture or directly edit the proposal
- Defining the next implementation task before the architecture proposal is reviewed
- Committing or pushing without separate authorization

## Known Risks

- Treating the current prototype structure or modData fields as accepted architecture merely because they already exist.
- Treating selected/active UI state as the desired simulation trigger or as a known vanilla causal mechanism.
- Hiding unresolved runtime dependencies inside architectural language.
- Designing every future context or multiplayer detail before the next implementation needs it.
- Producing a document too abstract to constrain state authority and vanilla handoff.
- Producing a document so detailed that it preimplements the system on paper.
- Letting the Reviewer expand architecture coverage beyond the accepted FC-005 baseline.
- Treating procedural review independence as proof of cognitive independence.
- Hiding material post-review revisions from Bart before architecture acceptance.

## Planner Handoff

FC-005 is complete. `docs/ARCHITECTURE.md` is the accepted canonical architecture baseline. No successor task or implementation is currently authorized. Planner should next derive a bounded successor proposal from the accepted architecture, preserving its unresolved runtime-evidence blockers and one-coherent-slice constraint, for Bart's separate acceptance. All Git writes remain a separate decision.
