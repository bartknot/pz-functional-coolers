# Functional Coolers Architecture

## Status and Authority

- Baseline task: `FC-005`
- Evidence-reconciliation task: `FC-007`
- Status: `ACCEPTED — CANONICAL ARCHITECTURE`
- FC-007 revision status: `ACCEPTED — CANONICAL ARCHITECTURE`
- Proposal owner: Software Architect
- Reviewer gate: `COMPLETED — CLOSURE REVIEW PASSED`
- Architect response: `MATERIAL REVISIONS APPLIED AND ACCEPTED`
- FC-007 fresh Reviewer: `COMPLETED — READY FOR BART ACCEPTANCE`
- Final acceptance authority: Bart, Project Owner / Integrator

This is the first accepted canonical architecture baseline for Functional Coolers. The required Reviewer gate and post-revision closure review are complete, and Bart explicitly accepted the resulting proposal on 2026-08-26.

FC-007 revised only the bounded P-4 reconciliation required by canonical FC-006 evidence. The fresh Reviewer found no required fixes, reported one optional `LOW` precision improvement, and concluded `READY FOR BART ACCEPTANCE`. Bart accepted the revision as canonical architecture on 2026-08-26 and explicitly required no further revision for the optional `LOW` finding.

Accepted architecture at the start of FC-005: none. Charter principles and verified evidence supplied accepted constraints; the decisions below became accepted architecture only through the completed FC-005 review and Bart's explicit acceptance.

The document uses these evidence categories deliberately:

- **Accepted constraint:** already established by the Project Charter, governance, or accepted project direction.
- **Verified evidence constraint:** bounded conclusion from canonical Researcher synthesis.
- **Current implementation:** directly observed in production source; not automatically desirable or accepted.
- **Proposed decision:** architectural judgment submitted for review and Bart acceptance.
- **Unresolved:** requires runtime evidence, product direction, or later architecture work.
- **Deferred:** intentionally outside this minimum baseline.

## Scope

This proposal establishes only the minimum architecture needed to constrain the next production task:

- system boundary;
- durable state ownership;
- simulation lifecycle;
- vanilla Food ownership handoff;
- context abstraction;
- persistence principles;
- minimum module responsibilities;
- a future multiplayer authority constraint.

It does not define implementation file layout, final APIs, calibration values, UI, detailed vehicle behavior, or a complete multiplayer design.

## Canonical Basis

This proposal derives from:

- [Project Charter](PROJECT_CHARTER.md)
- [Project Status](STATUS.md)
- [FC-003 Researcher synthesis](research/FC-003-2026-08-22.md)
- [FC-004 Researcher synthesis](research/FC-004-2026-08-25.md)
- [FC-006 Test Analyst run record](tests/runs/FC-006-2026-08-26.md)
- [FC-006 Researcher synthesis](research/FC-006-2026-08-26.md)
- [Current production source](../42/media/lua/server/FunctionalCoolers.lua)
- [Active FC-007 task](../CURRENT_TASK.md)

Detailed run records remain authoritative for run-level assessment. This proposal does not reclassify experiments or infer an undocumented Project Zomboid mechanism.

## Current Implementation — Not Accepted Architecture

The current `Prototype v0.3.0-dev` is a single server-side Lua file combining production modeling, runtime diagnostics, and FC-003 test setup.

Direct source inspection establishes that it currently:

- runs from `Events.EveryOneMinute` and obtains `getSpecificPlayer(0)`;
- discovers named test Coolers in the first player's inventory or on nearby ground;
- uses one fixed ambient temperature rather than a resolved environmental boundary;
- stores `FC_temperature` on Coolers, cold packs, and managed Food;
- stores `FC_managedAge`, `FC_managedFreezingTime`, and `FC_coolerID` on Food;
- stores `FC_lastThermalUpdateHours` on the Cooler;
- reinitializes managed Food from vanilla getters when required fields are absent or `FC_coolerID` differs from the current Cooler ID;
- advances thermal and biological state from elapsed `worldHours` in one- or five-minute steps;
- silently reanchors the Cooler timestamp if world time moves backwards;
- advances `FC_lastThermalUpdateHours` before projecting managed Food state to vanilla;
- projects managed Food state through `setHeat`, `setAge`, and `setFreezingTime` after simulation;
- suppresses individual vanilla projection failures through `pcall` without making the aggregate cursor contingent on projection success;
- writes the Cooler temperature to `container:setCustomTemperature`, although earlier accepted findings establish that container-level temperature/aging controls were insufficient for nested Food;
- scans nearby powered freezers and recharges loose cold packs on a tick-count schedule rather than an elapsed-time lifecycle;
- keeps test activation and other orchestration state in transient Lua variables.

The prototype demonstrates useful APIs and a working elapsed-time model. It does not yet provide a general discovery model, explicit ownership transitions, schema migration, verified save/load recovery, context-history handling, or multiplayer authority.

## Accepted and Verified Constraints

### Product constraints

- **Accepted constraint:** the Cooler is the thermodynamic system; its location is a changing boundary condition.
- **Accepted constraint:** physical state must survive supported inventory, ground, nested-container, and future vehicle transitions rather than reset because location changes.
- **Accepted constraint:** cold packs, cold or frozen Food, warm Food, and future heat sources participate through one coherent thermal model.
- **Accepted constraint:** elapsed and unattended time must eventually be reconcilable.
- **Accepted constraint:** verified runtime behavior constrains architecture, but does not silently select the product response.

### Runtime evidence constraints

- **Verified evidence constraint:** FC-003 observed carried/CONTROL catch-ups before the scheduled brief equip/inspection interventions; brief inspection was not necessary for those events.
- **Verified evidence constraint:** FC-004's sustained selected/active UI treatment package determined which matched carried/equipped Cooler received continuous observable Food refresh in one valid counterbalanced pair.
- **Verified evidence constraint:** selection is not established as the only vanilla update opportunity.
- **Verified evidence constraint:** the selected treatment bundles selection with visible, open, pinned UI state; its responsible subcomponent is unresolved.
- **Verified evidence constraint:** the experiments do not distinguish absent processing from deferred catch-up for stale unselected Food.
- **Verified evidence constraint:** the internal vanilla scheduler and the relationship between FC-003 and FC-004 timing remain unresolved.
- **Verified evidence constraint:** FC-006 supports `setAutoAge()` followed by immediate reapplication of final managed public age, heat, and freezing-time values as a no-repeat/no-omit handoff sequence within one valid Build 42.20.4 `Base.Steak` scenario with three explicit post-handoff `updateAge()` opportunities.
- **Verified evidence constraint:** FC-006's projection-only control processed the stale interval, while its aligned candidate remained exactly equal to the reference; the private freezing-update cursor itself was not directly observed.
- **Verified evidence constraint:** FC-006 does not establish universal behavior across Food classes, thermal phases, contexts, stale durations, natural scheduler opportunities, failure paths, saves, transfers, or Project Zomboid builds.

Consequently, UI selection, inspection, `lastAged`, and observed vanilla refresh opportunities may be diagnostic inputs, but none may be the Functional Coolers simulation clock, physical boundary, or sole production trigger.

## Architecture Decisions

The FC-005 decisions below and the FC-007 changes to P-4 and directly dependent wording are accepted canonical architecture.

### P-1. Cooler Aggregate Is the Thermodynamic System

The Cooler item is the aggregate root for one thermodynamic system. During a simulation interval, the system contains:

- the Cooler shell/interior thermal state;
- the Coldpacks currently inside it;
- the Food currently inside it;
- any later explicitly supported thermal participant.

Project Zomboid location, containment chain, ambient conditions, powered cold storage, and world time remain external boundary inputs. UI visibility, container selection, inspection, and diagnostic labels are outside the physical system.

When an item leaves the Cooler, its own physical state travels with that item. Moving the Cooler or its contents changes membership or boundary conditions; it does not reinitialize physical state.

Rationale: this follows the Charter and prevents carried, ground, nested, and later vehicle contexts from becoming separate thermal implementations.

Simpler alternative rejected: storing only a context-specific preservation bonus cannot represent content thermal mass, transfer continuity, or reusable cold sources. Storing all participant state only on the Cooler would lose continuity when Food or a cold pack moves independently.

### P-2. One Logical Authority Per State

Persistent physical state belongs to the item whose physical property it represents. The Cooler simulation owns coordinated advancement while an item is a managed participant.

| State | Durable owner | Logical authority while managed | Persistence requirement | Notes |
| --- | --- | --- | --- | --- |
| Cooler thermal state | Cooler item | Functional Coolers | Required | Represents the Cooler shell/interior model, not its location. |
| Cooler simulation cursor | Cooler item | Lifecycle Coordinator | Required | Monotonic world-hour position through which the aggregate is committed. |
| Last accepted boundary descriptor | Cooler item | Lifecycle Coordinator | Required where unattended reconciliation depends on it | It is boundary history, not the Cooler identity or thermal state. |
| Coldpack thermal state, participant cursor, lifecycle mode, and last accepted boundary | Coldpack item | Functional Coolers in every initialized lifecycle mode | Required | Travels with the cold pack through Cooler, powered-storage, and ambient contexts. Explicit phase state is conditional on later accepted phase-transition design. |
| Managed Food temperature | Food item | Functional Coolers while managed | Required | Vanilla heat is a projection during management. |
| Managed Food age/freezing state | Food item | Functional Coolers while managed | Required | Vanilla fields are projections, not a second clock. |
| Managed ownership marker, ownership epoch, and state cursor | Food item | Lifecycle Coordinator | Required while managed | Separates each vanilla-to-managed period and prevents stale managed values or duplicate advancement. |
| Context kind and current ambient inputs | None; resolved snapshot | Boundary Resolver | Ephemeral | Recomputed from Project Zomboid state. |
| Test group, selected UI state, and diagnostic labels | None | Diagnostics/Test Harness | Not production authority | Must never control simulation. |

All essential state must live in namespaced persistent item state, presently expected to use item `modData`, with an explicit schema version. Transient Lua tables may index or cache state but may not be its sole authority.

The exact field names and serialization representation are implementation details. Current fields such as `FC_coolerID` are legacy implementation evidence, not accepted identity architecture. Stable item-ID, clone, and replication behavior requires evidence before any identifier becomes a durable ownership key.

State invariants:

1. A managed Food item has exactly one logical simulation authority.
2. An initialized Coldpack always has one Functional Coolers lifecycle authority, including when it is outside a Cooler and not recharging.
3. After a successful aggregate commit, the Cooler and all current participants represent the same simulation cursor.
4. A cursor never advances until state advancement and required vanilla projection succeed.
5. Transfer changes ownership, lifecycle mode, or membership only after the source state is advanced to the transition time.
6. Missing discovery or an unknown context never resets physical state.
7. Schema initialization and migration are explicit, idempotent operations rather than incidental consequences of opening or moving an item.

A Food ownership epoch begins on every successful vanilla-to-Functional-Coolers handoff. A direct transfer between managed Coolers preserves the active epoch because vanilla never regains authority. A successful exit retires that epoch and marks all retained managed values as historical and non-authoritative. On later re-entry, a new epoch always overwrites or logically invalidates those historical values from a fresh verified vanilla transition snapshot. Exact field deletion versus invalidation is an implementation representation choice; reusing a retired snapshot is forbidden.

An initialized Coldpack moves between three minimum lifecycle modes:

- **Cooler-managed:** the Cooler aggregate advances it against the Cooler interior.
- **Powered-recharge:** a standalone lifecycle advances it against the resolved powered cold boundary.
- **Ambient standalone:** a standalone lifecycle advances it against the resolved non-powered environment.

Each mode transition first advances the old mode to the observed transition time, then changes the boundary without resetting temperature. If the true transition time or boundary history is unavailable, the state remains intact and the accuracy limitation follows the unresolved boundary-history policy; the Coldpack must not remain cold indefinitely merely because it is outside the currently scanned contexts.

### P-3. Server-Owned, World-Time Lifecycle

Functional Coolers advances from authoritative game world time. UI actions and vanilla `lastAged` changes do not measure elapsed simulation time.

The Lifecycle Coordinator performs this conceptual sequence for an observable Cooler:

1. Obtain authoritative `nowWorldHours` and a boundary snapshot.
2. Load, validate, and if necessary migrate the Cooler and participant state.
3. Detect membership or boundary transitions and reconcile their ownership before ordinary advancement.
4. Compute elapsed time from the persisted simulation cursor.
5. Advance a pure thermal/biological model over that interval using the applicable boundary history.
6. Project managed Food state to verified vanilla APIs.
7. Persist participant state, Cooler state, boundary descriptor, and the new cursor as one logical commit.
8. Emit diagnostics as observation of the result, never as part of the state transition.

Zero elapsed time is a valid no-op. Negative elapsed time is a state/time inconsistency: it must not run negative simulation or silently overwrite the accepted cursor. The implementation must report it and apply only a separately accepted recovery or migration policy.

“Bounded catch-up” means a finite maximum amount of simulation work per Lifecycle Coordinator invocation. It does not mean discarding elapsed time or moving the cursor directly to the target.

For every invocation:

1. record the target world time;
2. advance at most the accepted work budget;
3. commit only the exact cursor actually reached;
4. mark catch-up as pending when the committed cursor remains behind the target;
5. continue from that cursor in later invocations until the target is reached.

The numeric budget, step sizes, scheduling mechanism, and future analytical optimization are implementation decisions. The architectural invariant is that work per invocation is finite, partial progress is explicit, and no elapsed interval is silently skipped or claimed as complete.

Known membership and boundary transitions are timestamped and processed in cursor order. If bounded work has not yet reached a transition time, the transition remains pending with the participant state needed to replay it; it is not applied early against stale state. Pending catch-up and transitions are durable when they must survive save/load. Any gameplay action that requires current authoritative state must either bring the relevant state to the action time within the accepted budget or explicitly report/defer the unsupported operation; it must not silently use stale state as current.

Boundary transitions must be timestamped at the best authoritative observation point. If Project Zomboid does not expose enough event coverage to know when a transition occurred while unloaded or unobserved, the architecture does not invent that history. The supported fallback and its accuracy require an explicit later decision informed by runtime evidence.

### P-4. Explicit Vanilla Food Ownership Handoff

Food ownership has three transitions:

#### Vanilla to Functional Coolers

When Food enters a managed Cooler:

1. advance or capture vanilla state at the transition through verified APIs;
2. start a new managed ownership epoch;
3. overwrite or invalidate any retired managed snapshot and initialize the new epoch from that vanilla transition snapshot;
4. record Functional Coolers ownership and the transition cursor;
5. stop using later vanilla getter changes as the managed elapsed-time clock.

#### While managed

Functional Coolers is the logical authority for managed temperature, age, and freezing state. Vanilla Food fields are a write-through projection required for game compatibility, UI, and other vanilla consumers. The architecture does not assume vanilla's internal scheduler can be disabled; any consequential vanilla side effects while managed require evidence and an explicit mitigation.

#### Functional Coolers to vanilla

For a handoff within an explicitly accepted support boundary backed by FC-006 or later verified evidence, when Food leaves management:

1. advance the source Cooler and Food to the transition time;
2. while Functional Coolers remains authoritative, call the FC-006-supported timing-alignment operation `setAutoAge()`;
3. immediately reapply the final managed age, heat, and freezing-time values through the verified public projection APIs, because those final managed values—not any public-state mutation performed by `setAutoAge()`—are the state being handed back;
4. validate that timing alignment and every required final projection call succeeded, preserving the outcome that the next vanilla update neither repeats nor omits the managed interval;
5. only after that complete handoff succeeds, change the ownership mode to vanilla and retire the completed managed epoch;
6. treat any retained managed values as historical and invalid for a future entry snapshot.

If timing alignment or any final projection call fails, Functional Coolers remains the logical authority and the managed epoch is not retired. The failure must be reported while retaining the durable managed state needed for an explicitly accepted retry, reconciliation, or recovery path. A partially mutated vanilla object is not proof that ownership transferred successfully, and the implementation must not silently create two authorities. Exact rollback, retry scheduling, and player-facing failure behavior remain implementation decisions.

An exit outside the explicitly accepted support boundary must not be reported as a successful vanilla handoff merely by applying the bounded sequence speculatively. The transition remains unsupported until additional evidence extends the boundary or Bart accepts an explicit limited-support or recovery policy through the appropriate architecture and planning task.

A transfer directly between managed Coolers advances the source state, carries the Food's physical/biological state and active ownership epoch, and assigns it to the destination without rereading stale vanilla state or resetting because the Cooler identity changed.

FC-006 supplies bounded evidence for this sequence: in one valid Build 42.20.4 carried/equipped `Base.Steak` scenario, `setAutoAge()` followed by final public projection remained exactly aligned with the reference through three explicit post-handoff `updateAge()` opportunities, while public projection alone processed the stale interval. This supports the architectural sequence within that verified boundary; it is not a universal or future-build API guarantee.

Functional Coolers does not write `lastAged` directly and does not use `lastAged`, UI state, or observed natural refresh timing as its simulation clock. FC-006 did not establish when vanilla naturally schedules the next update or whether untested Food states and contexts have additional side effects. A later implementation task must either remain within an enforceable evidence-supported boundary or include the additional evidence gates required by its broader claimed support.

Simpler alternative rejected: allowing Functional Coolers and vanilla deltas to advance managed Food concurrently creates two authorities and previously failed when vanilla fields became stale. Continuously rereading vanilla state would also couple simulation correctness to UI-dependent refresh opportunities demonstrated by FC-004.

### P-5. Context Is a Resolved Boundary Snapshot

The Boundary Resolver converts the current Project Zomboid containment/environment into a small immutable input for a simulation interval. Its physical inputs are compositional rather than one mutually exclusive context kind. Conceptually it supplies:

- an ordered containment chain from the item outward;
- a mobility/location facet such as carried, ground, world object, or future vehicle;
- the outer environmental temperature input;
- zero or more enclosing thermal layers and their accepted heat-exchange properties;
- powered cooling/recharge capability attached to the physical layer that provides it;
- observation world time;
- whether the necessary context history is authoritative, inferred, or unavailable.

The resolver must follow the full containment chain rather than equating direct player inventory, ground proximity, or active UI state with physical context.

Boundary composition is deterministic:

1. the nearest enclosing physical container supplies the immediate enclosure layer;
2. additional nested containers contribute ordered outer layers rather than replacing inner context;
3. the outer room, world, player-carried environment, or future vehicle supplies the external environment facet;
4. powered cooling applies only where the resolved containment chain identifies the item as physically inside the powered layer;
5. the resolver produces one effective boundary for the Model while retaining enough structured provenance for diagnostics and later refinement.

For example, a Cooler inside a bag carried by a player is simultaneously nested and carried: the bag is an enclosure layer and the player's environment supplies the outer boundary. A Cooler inside powered cold storage has that storage as its immediate powered layer while the surrounding room remains an outer environmental facet. Future vehicle context supplies another outer environment facet and does not require a parallel Cooler model.

A short context label may be derived for diagnostics, but it has no authority and does not drive context-specific simulation branches.

Coldpack recharge outside a Cooler is an item lifecycle using the same powered-boundary evidence and elapsed world time. A nearby freezer scan or UI selection is not itself the physical rule.

### P-6. Persistent, Versioned, Recoverable State

Persistent state uses namespaced item storage because Coolers, Food, and cold packs must carry their own physical state through inventory and world transfers. Each persistent state shape has a schema version.

Persistence rules:

- Food initializes a managed snapshot when no valid active epoch exists, when an explicit migration requires it, or when vanilla-to-managed entry starts a new epoch; retired historical fields never suppress re-entry initialization;
- direct managed-Cooler transfer preserves the active Food epoch and does not initialize from vanilla;
- Coldpack lifecycle mode, participant cursor, and last accepted boundary survive every context transition;
- pending catch-up and timestamped transition state survive save/load when the committed cursor has not yet reached their target;
- migrations are versioned and idempotent;
- save/load reconstructs transient coordination from item state rather than depending on Lua globals;
- world-hour cursors, ownership phase, and physical state survive restart;
- invalid, partial, non-finite, or future-version state is reported and handled through an explicit recovery policy;
- the simulation cursor advances last in the logical commit;
- item clone, split, duplicate-ID, and replication behavior must be verified before identity-dependent migration is implemented.

The proposal does not claim that current `modData` replication is already sufficient for multiplayer. It identifies item-local persistence as the state-placement principle and leaves exact Project Zomboid replication behavior unresolved.

### P-7. Minimum Responsibility Boundaries

These are responsibility boundaries, not a required one-file-per-row layout.

| Responsibility | Owns | Must not own |
| --- | --- | --- |
| Lifecycle Coordinator | authoritative time, ordered ownership/lifecycle transitions, bounded catch-up scheduling, partial-progress state, logical commit | thermodynamic formulas, UI state, persistence representation details |
| Persistent State Store | validation, schema migration, item-state read/write | simulation policy, context discovery, gameplay decisions |
| Boundary Resolver | containment/environment inspection, compositional boundary snapshots, deterministic layer precedence | durable thermal state, UI-driven update policy, thermodynamic advancement |
| Thermal/Biology Model | deterministic state transition from prior state, boundary, and elapsed time | Project Zomboid object discovery, persistence, logging |
| Vanilla Food Adapter | verified getter/setter projection and ownership handoff | simulation clock, physical model, unverified causal assumptions |
| Diagnostics | structured observation of inputs, decisions, and outputs | mutation of production state or experiment setup |

Standalone coldpack recharge composes the State Store, Boundary Resolver, Model, and Lifecycle Coordinator; it does not require a parallel freezer-specific state system.

This separation is the minimum justified because it isolates pure model calculation from volatile Project Zomboid APIs, isolates persistence from discovery, and makes the vanilla ownership boundary reviewable. A larger service, class, or ADR hierarchy is not proposed.

### P-8. Future Multiplayer Authority Constraint

Any implementation derived from this architecture must permit one authoritative server-side writer for simulation state and world-time cursors. Clients may display replicated state or request actions, but must not independently advance the same Cooler or Food.

Essential state may not exist only in a player-specific or transient Lua table. `getSpecificPlayer(0)`, nearby scans centered on one player, and client UI state are prototype constraints, not acceptable authority boundaries.

Detailed command routing, replication, conflict resolution, ownership transfer between clients, and networking protocol are deferred. Before multiplayer implementation, Researcher evidence must establish relevant `modData`, inventory-event, and server/client API behavior.

## Cross-Cutting Transaction Rules

The proposed decisions imply these rules for every later implementation slice:

1. Discover or receive an event; do not infer physical state from UI selection.
2. Reconcile the old owner and boundary to an authoritative transition time before changing membership.
3. Compute state changes without mutating Project Zomboid objects where practical.
4. Apply vanilla projections through one adapter.
5. Persist new managed state and advance the cursor only after the transition succeeds.
6. On partial failure, retain enough prior state to retry or report; never silently claim the interval was committed.
7. Diagnostics record the chosen boundary, elapsed interval, ownership transition, schema version, and outcome without changing them.

Lua item writes are not assumed to be database transactions. “Logical commit” means the implementation orders and validates writes so the cursor cannot claim progress that the managed state or vanilla projection did not receive.

## Constraints for the Next Implementation Task

Any bounded implementation task derived from the accepted FC-007 revision must:

- choose one coherent architectural slice rather than rewrite the entire prototype at once;
- preserve the one-authority Food invariant;
- use world time rather than vanilla refresh deltas or UI activity as its simulation clock;
- introduce schema/version handling before adding or changing durable fields;
- avoid reinitializing Food merely because it changes Coolers or contexts;
- keep diagnostics observational and test setup outside production responsibilities;
- stop if the slice requires an unresolved Project Zomboid API assumption;
- use the FC-006-supported handoff sequence only within the implementation's explicitly accepted and testable support boundary;
- keep the managed epoch authoritative on any timing-alignment or final-projection failure and define observable failure handling before claiming handoff completion;
- include migration or compatibility handling for existing prototype state when that state becomes in scope;
- leave calibration and unrelated prototype cleanup to separately accepted tasks.

This proposal does not select that first slice. Planner owns sequencing after Bart accepts the architecture and any blocking Researcher questions are routed.

## Unresolved Runtime Questions

### Bounded handoff evidence established; broader support remains unresolved

FC-006 resolves the former exact-sequence blocker within its tested boundary: `setAutoAge()` followed by immediate final public projection produced the required observable no-repeat/no-omit outcome relative to the reference. Remaining questions are:

1. Does the sequence preserve continuity across additional Food classes, thermal phases, contexts, stale durations, natural update opportunities, saves, transfers, and future Project Zomboid builds?
2. Do `setAutoAge()`, `setAge`, `setHeat`, and `setFreezingTime` have delayed, hidden, or state-specific side effects outside the FC-006 observations?
3. Can vanilla Food processing be safely treated as projection-only while managed, or do intermediate vanilla updates create gameplay side effects that must be suppressed or reconciled?
4. What retry, reconciliation, or recovery behavior is safe when timing alignment succeeds but one or more final projection calls fail?

### Blocking before reliable transfer and unattended support

5. Which server-observable inventory/container events cover entry, exit, nested transfer, ground placement, and unloaded/reactivated transitions, and what authoritative time is available at each event?
6. What boundary history can be known across save/load, chunk unload, or transfer while the item is not actively discovered?
7. How do item IDs and `modData` behave across cloning, duplication, save/load, and server replication, and can any current identifier safely represent durable ownership?

### Required before broader context or multiplayer work

8. Which server-side APIs provide authoritative local ambient, indoor/outdoor, powered refrigeration, and later vehicle boundary data?
9. Which server hooks can discover or schedule relevant Coolers without a first-player or nearby-scan assumption?
10. How are item `modData` mutations replicated and conflict-resolved in the intended multiplayer runtime?
11. What exact vanilla semantics connect `freezingTime`, `isFrozen`, heat, age, and thawing across the supported Food types?

These questions are Researcher/Test Lab handoffs, not assumptions for Architect or Coder to answer from documentation alone.

## Deliberately Deferred Design

- final thermal capacities, conductance, insulation, thaw, freezing, and spoilage formulas;
- explicit Coldpack phase-state schema until phase-transition behavior is separately accepted;
- analytical versus stepped long-interval integration;
- detailed vehicle temperatures and battery-powered upgrades;
- multiplayer messages, prediction, synchronization, and client UX;
- player-facing status, tooltips, colors, and configuration;
- migration field names and exact Lua module/file layout;
- general thermodynamic-container reuse beyond the Cooler;
- release packaging, version cleanup, deployment, and Git-to-runtime provenance tooling;
- the next empirical protocol and independent FC-004 replication.

## FC-005 Reviewer Findings and Architect Responses

The required fresh Reviewer pass concluded that material revision was necessary before Bart acceptance. No `BLOCKER` was reported. Architect responses follow.

### Finding 1 — HIGH: Food re-entry ownership epoch was ambiguous

**Architect response: accepted and materially revised.**

- P-2 now defines an explicit Food ownership epoch.
- Successful exit retires the epoch and makes retained managed values historical and non-authoritative.
- Every later vanilla-to-managed entry starts a new epoch and overwrites or invalidates the retired snapshot from a fresh transition capture.
- Direct managed-Cooler transfer preserves the active epoch and never rereads vanilla.
- P-4 and P-6 now state the same lifecycle consistently.

This resolves the stale re-entry path while leaving exact deletion versus invalidation as an implementation representation choice.

### Finding 2 — HIGH: Coldpack authority outside Cooler or powered recharge was undefined

**Architect response: accepted and materially revised.**

- P-2 now makes Functional Coolers the lifecycle authority for every initialized Coldpack.
- Cooler-managed, powered-recharge, and ambient-standalone modes are explicit.
- Each mode has a persistent cursor and boundary; transitions advance the old mode before switching without resetting temperature.
- P-5 and P-6 now carry the standalone lifecycle through boundary resolution and save/load.

Exact event coverage and unknown historical transition timing remain correctly routed as runtime questions, but indefinite stale cold is no longer permitted by the architecture.

### Finding 3 — MEDIUM: Context kinds overlapped and hid precedence

**Architect response: accepted and materially revised.**

- P-5 replaces mutually exclusive context kinds with ordered containment layers, a location/mobility facet, an outer environment, and layer-attached powered capability.
- Deterministic inner-to-outer composition and concrete carried/nested and powered/nested examples are included.
- Any short context kind is now diagnostic only and cannot select a simulation branch.

This preserves the single boundary abstraction without adding detailed vehicle design.

### Finding 4 — MEDIUM: Bounded catch-up lacked an operative contract

**Architect response: accepted and materially revised.**

- P-3 now defines the bound as finite simulation work per coordinator invocation.
- Partial progress commits only the cursor actually reached and remains explicitly pending.
- Timestamped transitions wait in cursor order and persist when necessary.
- No interval may be skipped and no stale state may be silently presented as current for an authoritative operation.
- Numeric budgets, step sizes, and scheduling remain implementation decisions.

This constrains later implementation while avoiding premature numerical policy.

### Finding 5 — LOW: Coldpack phase state was prematurely mandatory

**Architect response: accepted.**

The durable-state table now requires Coldpack thermal state but makes explicit phase state conditional on later accepted phase-transition design. The deferred-design section records that boundary. No present schema commitment to Coldpack phase state remains.

## Material Revision Summary for Bart

The post-review revision changes four architectural contracts and one deferred commitment:

1. Food management is epoch-based across exit, re-entry, and direct managed transfers.
2. Coldpacks have continuous Functional Coolers authority in Cooler, powered, and ambient lifecycle modes.
3. Physical context is a compositional containment/environment boundary rather than a mutually exclusive kind.
4. Catch-up is bounded by work per invocation with durable partial progress and ordered pending transitions.
5. Coldpack phase state is deferred until phase-transition design is accepted.

No production code, task scope, calibration, detailed vehicle behavior, multiplayer protocol, or implementation file layout is added by these revisions.

## Architecture Handoff

The required fresh Reviewer pass, Architect response, and focused post-revision closure review are complete. The closure review classified findings 1–5 as `RESOLVED`, identified no material new finding, and concluded `READY FOR BART ACCEPTANCE`.

Bart accepted the revised proposal as canonical architecture on 2026-08-26. Planner owns subsequent task sequencing; unresolved runtime questions and implementation constraints in this document remain binding until addressed through the appropriate role and acceptance process.

FC-007 completed the bounded P-4 evidence reconciliation above. It preserves the accepted ownership and transaction model, replaces the wholly unresolved exact-sequence statement with the FC-006-supported sequence and scope, and adds no production implementation. The fresh Reviewer found no required fix and Bart accepted the revision as canonical architecture on 2026-08-26. Handoff returns to Planner for separately authorized sequencing of the smallest justified next task.
