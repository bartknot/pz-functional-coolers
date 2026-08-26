# Current Task

## ID

FC-006

## Status

READY — SUBSTANTIVE RUN AUTHORIZATION REQUIRED

## Assigned Roles and Gates

- Primary empirical owner: Researcher / Runtime Diagnostics
- Protocol and run-validity owner: Test Analyst
- Test-infrastructure owner: Test Engineer; the bounded setup-13 implementation, deployment, and infrastructure smoketest are complete and accepted
- Scope, sequencing, and canonical project-state owner: Planner
- Final task, infrastructure, run, evidence-write, and completion authority: Bart

## Objective

Establish bounded runtime evidence for the managed-to-vanilla Food handoff required by the accepted architecture.

The task asks whether a controlled Functional Coolers projection of managed Food state back to vanilla can be followed by vanilla processing without repeating or omitting the managed elapsed interval. It must identify either:

- a verified API sequence that produces that outcome within a precisely described tested scope; or
- a verified limitation, ambiguity, or unavailable control point that prevents the required outcome from being established and must be returned to Architect/Planner.

FC-006 is an evidence task, not a production implementation task. Bart accepted FC-006 on 2026-08-26. Phase A Researcher feasibility, Phase B Test Analyst protocol design, and Phase C Test Engineer infrastructure are complete. Bart accepted setup 13 and its passed infrastructure smoketest on 2026-08-26. A substantive FC-006 run, evidence persistence, and production-code changes remain unauthorized.

## Central Research Question

Within one controlled Build 42.20.3 scenario, what observable age/freezing/timing transition occurs when Food leaves simulated Functional Coolers management, receives the candidate final managed projection, and is next processed by vanilla?

The experiment must be capable of detecting, within its tested resolution:

- duplicate vanilla processing of elapsed time already represented by the managed state;
- omission of elapsed time that should be represented after handoff;
- delayed or hidden changes following `setAge`, `setHeat`, or `setFreezingTime`;
- the relationship between the projection, the observed `lastAged` value, and the first verified post-handoff vanilla update opportunity.

The task does not assume that Functional Coolers can set or otherwise control vanilla's internal timing cursor. Candidate control points must first be established through verified API/runtime evidence.

## Why Now

`docs/ARCHITECTURE.md` is accepted canonical architecture. It requires the managed-to-vanilla handoff to leave vanilla ready to continue without repeating or omitting the managed interval, but explicitly records the safe API sequence as unresolved and blocks complete production handoff implementation until Researcher evidence resolves it or establishes a verified limitation.

This is a higher-value dependency than starting a production refactor that would have to embed an unverified handoff assumption. It is narrower than investigating every unresolved lifecycle, transfer, save/load, context, or multiplayer question.

## Canonical Inputs

- `AGENTS.md`
- `AI_WORKFLOW.md`
- `CURRENT_TASK.md`
- `ai/RESEARCHER.md`
- `ai/test-lab/TEST_ANALYST.md`
- `ai/test-lab/TEST_ENGINEER.md` if infrastructure becomes necessary
- `docs/PROJECT_CHARTER.md`
- `docs/STATUS.md`
- `docs/TODO.md`
- `docs/ARCHITECTURE.md`, especially P-4, the next-task constraints, and unresolved runtime questions 1–3
- `docs/research/FC-003-2026-08-22.md`
- `docs/research/FC-004-2026-08-25.md`
- Canonical FC-003/FC-004 run records only where their run-level timing or validity constraints are directly relevant
- Current production source only as evidence of the prototype's existing getter/setter use, not as accepted handoff behavior
- Current test harness only as evidence of available observability, not as authorization to reuse or modify FC-004 behavior

Raw prior artifacts need not be reanalyzed unless a material ambiguity cannot be resolved from canonical records.

## Evidence and Scope Boundaries

The roles must distinguish:

- direct runtime observations;
- Bart-supplied execution metadata;
- Test Analyst run-level validity and interpretation;
- Researcher inference;
- broader conclusions accepted only within the tested scope.

Temporal proximity between projection and a later vanilla update does not by itself establish causality. A sequence is not “safe” merely because no obvious discontinuity appears in one sampled field.

`lastAged` is an observed vanilla timing field, not automatically an authorized or sufficient control surface. Food age, heat, freezing time, frozen state, world time, context, and the exact observed update opportunity must be interpreted together where practical.

A single valid run may establish feasibility or expose a failure in its exact setup. It does not establish all Food types, contexts, durations, save/load cases, or Project Zomboid builds.

## Required Task Sequence

### Phase A — Researcher Feasibility and Observability

Status: COMPLETE

The Researcher must:

1. identify which relevant getters, setters, events, and timing fields are actually observable or callable in the target runtime;
2. separate verified capability from candidate or undocumented API assumptions;
3. define the minimum contrast needed to detect duplicate versus omitted elapsed processing;
4. hand the bounded empirical question and observability limits to Test Analyst.

If no protocol can distinguish the required outcomes with available observability, stop and report that limitation before infrastructure work.

### Phase B — Test Analyst Protocol and Validity Design

Status: COMPLETE

The Test Analyst must produce a practically executable protocol that:

- isolates one managed-to-vanilla transition question;
- includes an appropriate vanilla or otherwise justified baseline/control;
- defines the managed interval and transition time;
- records state immediately before projection, immediately after projection, and across the first verified post-handoff vanilla processing opportunity;
- specifies how that processing opportunity is observed without assuming selection, inspection, or equip is its internal cause;
- defines READY, BEGIN, HANDOFF, post-handoff observation, END, invalidation, and completion conditions;
- states which conclusions are supported by VALID, INVALID, or INCONCLUSIVE outcomes.

The Test Analyst must not implement the protocol or decide that an unverified API is safe.

### Accepted Feasibility and Protocol Basis

For the local Build 42.20.3 target, the Researcher established that the public Food state can be observed and projected through the relevant age, heat, and freezing-time getters and setters, while the vanilla freezing-update cursor remains private. Static runtime inspection found that `setAutoAge()` writes both `lastAged` and the private freezing-update cursor to current `worldHours`; `updateAge()` then processes freezing and aging. This supports testing the bounded candidate sequence `setAutoAge()` followed by the final public-state projection, without treating that sequence as production-safe before runtime evidence exists.

The accepted Test Analyst protocol uses a fresh dedicated save with only the FC-006 harness enabled, the production Functional Coolers mod disabled, and Build 42.20.3 with `DayLength = 4`, `FoodRotSpeed = 3`, and `FridgeFactor = 3`. An empty selected `FC006-GUARD` Cooler provides the stable selected/active context. An unselected `FC006-TEST` Cooler contains three `Base.Steak` items:

- V — vanilla-sync reference: `updateAge()` followed by the final public-state projection at handoff;
- A — aligned candidate: `setAutoAge()` followed by the same final public-state projection;
- U — unaligned sensitivity control: final public-state projection only, leaving vanilla timing cursors stale.

Setup aligns all three items through `setAutoAge()` and projects the common baseline. At BEGIN/T0, the harness starts a one-game-hour simulated managed/stale interval in which it performs getter-only observation and no state update on V, A, or U. The final handoff projection is `age = 0.5`, `heat = 1.0`, and `freezingTime = 80.0` for every item.

The HANDOFF operations must occur in one callback with no more than `0.001` game hour timestamp spread. Before `HANDOFF_COMMITTED`, V, A, and U must have equal projected numeric state within the defined tolerances and exactly equal public phase flags: `frozen = false`, `freezing = false`, and `thawing = true`. Any mismatch ends the run as INVALID with reason `public_phase_state_mismatch`; `HANDOFF_COMMITTED` must not be emitted.

After handoff, the harness waits exactly ten game minutes without state updates, explicitly calls `updateAge()` on V, A, and U, and records UPDATE_1. It repeats the same wait/update/record sequence for UPDATE_2 and UPDATE_3, then emits automatic END. The accepted tolerances are `0.001` game hour for time, `0.00001` for age, `0.01` for heat, and `0.05` for freezing time. Logs must preserve marker order, world time, group identity, intervention identity, public numeric state, phase flags, and `lastAged` observations.

The freezing-domain comparison is interpretable only if the authorized thaw-response smoketest passes, the pre-handoff phase flags are equal, U demonstrates sensitivity to stale cursor state, and A agrees with V within tolerance. Otherwise the applicable domain or run is INCONCLUSIVE or INVALID under the predeclared protocol; criteria must not be relaxed after observing results.

### Phase C — Infrastructure Authorization Gate

Status: COMPLETE — SETUP 13 ACCEPTED

The Test Engineer implemented and deployed the minimum deterministic setup, observability, control sequence, validity guards, and automatic marker/endpoint behavior required by the accepted protocol. Setup 13 (`v0.5.1-dev`) passed the complete non-evidence infrastructure smoketest and was accepted by Bart after Test Analyst review. The completed Phase C authorization does not permit further infrastructure work. Production source under the repository-root `42/` was not changed.

### Phase D — Experiment Authorization Gate

Status: WAITING — EXPLICIT BART RUN AUTHORIZATION REQUIRED

A substantive run requires:

- an accepted executable protocol;
- any required infrastructure to have passed its own smoketest;
- Test Analyst confirmation that the evidence stream can distinguish the planned outcomes;
- separate explicit Bart authorization for the run.

The accepted executable protocol, passed setup-13 infrastructure smoketest, and Test Analyst evidence-stream readiness confirmation now satisfy the first three requirements. The separate Bart run authorization remains open. The substantive run must use a new fresh setup-13 save rather than the infrastructure-smoketest save.

Infrastructure-smoketest output is not empirical FC-006 evidence.

### Phase E — Evidence Chain and Project Consequence

If a substantive run is authorized and completed:

1. raw runtime evidence is preserved under a task/date-specific artifact path;
2. Test Analyst creates the canonical run record and classifies it;
3. Researcher creates a canonical FC-006 synthesis only when the evidence supports a durable task-level conclusion;
4. Planner records any accepted project-state, sequencing, backlog, or architecture-handoff consequence.

A verified limitation that blocks the accepted handoff outcome must be routed back to Architect. Runtime evidence does not silently rewrite `docs/ARCHITECTURE.md`.

## Current Allowed Changes

For completed Phase C, Bart authorized the Test Engineer to modify only these existing repository files:

- `tools/test-harness/FunctionalCoolersTestHarness/README.md`
- `tools/test-harness/FunctionalCoolersTestHarness/README.txt`
- `tools/test-harness/FunctionalCoolersTestHarness/42/mod.info`
- `tools/test-harness/FunctionalCoolersTestHarness/42/media/lua/client/FunctionalCoolersTestSetup.lua`

The completed authorization permitted the Test Engineer to:

- implement the accepted FC-006 setup, instrumentation, state projection, validity guards, logging, scheduled explicit `updateAge()` calls, and automatic endpoint in those files;
- update harness documentation and consistent version/setup markers only as required to identify this FC-006-capable harness state;
- deploy only the resulting `FunctionalCoolersTestHarness` files to `C:\Users\bartk\Zomboid\mods\FunctionalCoolersTestHarness\` for the authorized smoketest;
- support and assess the Authorized Infrastructure Smoketest below using a fresh dedicated save and Bart-supplied runtime observations or console output.

The Phase C work is complete and its active permission is exhausted. No further Test Engineer modification, deployment, or smoketest is authorized without a new explicit gate.

No role is currently authorized to execute a substantive FC-006 run, preserve new evidence, modify production or architecture, or perform Git writes. The following Phase C prohibitions remain applicable to its completed scope:

- add, delete, rename, or modify any other repository file;
- change anything under the repository-root production `42/` path or enable the production Functional Coolers mod during the smoketest;
- execute or classify a substantive FC-006 experiment;
- preserve smoketest output as empirical FC-006 evidence, create an artifact/run record/Researcher synthesis, or update project status from empirical results;
- introduce `setLastAged(T)` as a required control or fallback; it is not used by the accepted candidate sequence and is not required by this task;
- stage, commit, push, pull, create a branch/worktree/tag/release, rewrite history, or change Git identity.

Substantive run authorization, evidence persistence, and every additional repository or runtime write require a later explicit gate.

## Authorized Infrastructure Smoketest

The completed smoketest was infrastructure validation only and every emitted line identified `evidenceEligible=false`. Setup 13 verified:

1. the enabled-mod set excludes the production Functional Coolers mod and includes the newly identifiable FC-006 harness version/setup;
2. the harness accepts a fresh dedicated save and rejects incompatible prior harness state;
3. it creates `FC006-GUARD` and `FC006-TEST` with exactly the V/A/U `Base.Steak` groups, their intended selected/unselected contexts, equal initial public state, and unambiguous group identity;
4. required getter observation and calls to `setAutoAge()`, `setAge()`, `setHeat()`, `setFreezingTime()`, and `updateAge()` work in the deployed runtime; `setLastAged(T)` callability is not a mandatory smoketest item;
5. a disposable thaw-response item is aligned with `setAutoAge()`, projected to `heat = 1.0` and `freezingTime = 80.0`, and observed as `frozen = false`, `freezing = false`, `thawing = true`; after exactly ten game minutes with no update call, one explicit `updateAge()` must produce `freezingTimeBefore - freezingTimeAfter > 0.05`, with elapsed time within `0.001` game hour of the target;
6. the harness blocks `HANDOFF_COMMITTED` and emits INVALID reason `public_phase_state_mismatch` if V/A/U do not share equal projected numeric state and the exact required public phase flags;
7. BEGIN, pre-handoff, HANDOFF, UPDATE_1 through UPDATE_3, invalidation, and automatic END scheduling/logging can be exercised with correct ordering and sufficient fields without generating substantive experiment evidence.

The Test Analyst accepted the complete setup-13 infrastructure gate. The smoke directly demonstrated the required thaw response, the expected mismatch invalidation without handoff commit, the real shared `BEGIN` through `END` state-machine and exact marker order, V/A agreement with U sensitivity, and successful final baseline reset. These observations establish infrastructure readiness only and are not empirical FC-006 evidence.

## Acceptance Criteria

- The task tests one handoff-continuity uncertainty rather than general vanilla refresh behavior.
- Researcher identifies verified observable/callable surfaces before Test Analyst relies on them.
- The protocol can distinguish duplicate processing, omitted processing, a bounded continuous result, and insufficient observability.
- Baseline/control logic and the first verified post-handoff vanilla processing opportunity are explicit.
- Required fields and timestamps are recorded at enough transition points to support the planned comparison.
- Selection, inspection, equip, or other UI action is recorded as an intervention/update opportunity and not declared the internal vanilla cause.
- Test Analyst can classify each run as VALID, INVALID, or INCONCLUSIVE without relaxing criteria after seeing the result.
- No production code is changed.
- Harness changes, deployment, and smoketest behavior remain confined to the explicit Phase C authorization; no substantive experiment occurs before its separate gate.
- Any claimed safe sequence is bounded to the exact verified build, Food type, context, setters, timing, and observation conditions.
- A negative or inconclusive feasibility result may complete FC-006 if it precisely establishes the unresolved limitation and routes the consequence correctly.
- The accepted architecture is preserved unless Bart later accepts an Architect revision based on verified evidence.

## Out of Scope

- Implementing the production ownership epoch or managed-to-vanilla handoff
- Refactoring the single-file production prototype
- General schema migration or persistent-state implementation
- Transfer-event coverage, nested containers, save/load, chunk unload, or long unattended catch-up
- Coldpack lifecycle or recharge behavior
- Calibration, thermal formulas, UI/UX, deployment tooling, packaging, or version cleanup
- Identifying the entire internal vanilla Food scheduler
- Proving behavior across multiple Project Zomboid builds, Food classes, contexts, or arbitrary durations
- Independent replication beyond the minimum first bounded result
- Repeating FC-003 or FC-004 without direct relevance to the handoff contrast
- Modifying `docs/ARCHITECTURE.md` without a later Architect task and Bart acceptance
- Git writes without separate explicit authorization

## Known Risks

- Vanilla may expose `lastAged` for observation without exposing a safe supported way to align it.
- Setter calls may have delayed side effects that are visible only at a later vanilla update opportunity.
- Lazy or UI-associated vanilla refresh can confound handoff timing unless the protocol records the exact intervention and suitable controls.
- Age and freezing state may update on different schedules or with different hidden state.
- Sampling may be too sparse to distinguish one vanilla interval from a duplicate or omitted interval.
- Direct test manipulation of Food state can invalidate the comparison unless it is deterministic, logged, identical where required, and confined to the planned handoff intervention.
- Existing Functional Coolers behavior could contaminate a harness-only experiment unless enabled mods and state ownership are explicitly controlled.
- A superficially smooth first update could hide a later discontinuity.
- Expanding the task to every setter, Food type, context, or lifecycle transition would defeat the bounded purpose.

## Planner Handoff

Setup 13 is accepted and Phase C is complete. Before Phase D, Bart should separately authorize Git commit/push of the reviewed Planner and four-file harness transition so the runtime source is canonical and reproducible. Bart may then separately authorize one substantive FC-006 run on a new fresh setup-13 save. Evidence persistence, production modification, architecture changes, and any later Git write remain separately gated.
