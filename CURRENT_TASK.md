# Current Task

## ID

FC-006

## Status

READY — RESEARCHER FEASIBILITY AUTHORIZED

## Assigned Roles and Gates

- Primary empirical owner: Researcher / Runtime Diagnostics
- Protocol and run-validity owner: Test Analyst
- Test-infrastructure owner: Test Engineer, only if a later bounded implementation is explicitly authorized
- Scope, sequencing, and canonical project-state owner: Planner
- Final task, infrastructure, run, evidence-write, and completion authority: Bart

## Objective

Establish bounded runtime evidence for the managed-to-vanilla Food handoff required by the accepted architecture.

The task asks whether a controlled Functional Coolers projection of managed Food state back to vanilla can be followed by vanilla processing without repeating or omitting the managed elapsed interval. It must identify either:

- a verified API sequence that produces that outcome within a precisely described tested scope; or
- a verified limitation, ambiguity, or unavailable control point that prevents the required outcome from being established and must be returned to Architect/Planner.

FC-006 is an evidence task, not a production implementation task. Bart accepted FC-006 on 2026-08-26. This acceptance authorizes only Phase A read-only Researcher feasibility/observability work and the subsequent Phase B Test Analyst protocol design; it does not authorize changing the harness, executing a substantive run, or modifying production code.

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

The Researcher must:

1. identify which relevant getters, setters, events, and timing fields are actually observable or callable in the target runtime;
2. separate verified capability from candidate or undocumented API assumptions;
3. define the minimum contrast needed to detect duplicate versus omitted elapsed processing;
4. hand the bounded empirical question and observability limits to Test Analyst.

If no protocol can distinguish the required outcomes with available observability, stop and report that limitation before infrastructure work.

### Phase B — Test Analyst Protocol and Validity Design

The Test Analyst must produce a practically executable protocol that:

- isolates one managed-to-vanilla transition question;
- includes an appropriate vanilla or otherwise justified baseline/control;
- defines the managed interval and transition time;
- records state immediately before projection, immediately after projection, and across the first verified post-handoff vanilla processing opportunity;
- specifies how that processing opportunity is observed without assuming selection, inspection, or equip is its internal cause;
- defines READY, BEGIN, HANDOFF, post-handoff observation, END, invalidation, and completion conditions;
- states which conclusions are supported by VALID, INVALID, or INCONCLUSIVE outcomes.

The Test Analyst must not implement the protocol or decide that an unverified API is safe.

### Phase C — Infrastructure Authorization Gate

Only after Phases A and B may Test Engineer identify the minimum instrumentation or deterministic setup required.

Any harness modification, new test path, deployment, or infrastructure smoketest requires a later explicit Bart authorization naming the permitted files and actions. Production source under `42/` is not an eligible test-infrastructure path.

### Phase D — Experiment Authorization Gate

A substantive run requires:

- an accepted executable protocol;
- any required infrastructure to have passed its own smoketest;
- Test Analyst confirmation that the evidence stream can distinguish the planned outcomes;
- separate explicit Bart authorization for the run.

Infrastructure-smoketest output is not empirical FC-006 evidence.

### Phase E — Evidence Chain and Project Consequence

If a substantive run is authorized and completed:

1. raw runtime evidence is preserved under a task/date-specific artifact path;
2. Test Analyst creates the canonical run record and classifies it;
3. Researcher creates a canonical FC-006 synthesis only when the evidence supports a durable task-level conclusion;
4. Planner records any accepted project-state, sequencing, backlog, or architecture-handoff consequence.

A verified limitation that blocks the accepted handoff outcome must be routed back to Architect. Runtime evidence does not silently rewrite `docs/ARCHITECTURE.md`.

## Current Allowed Changes

For the accepted planning transition, Planner may modify only:

- `CURRENT_TASK.md`
- `docs/STATUS.md`
- `docs/TODO.md`
- `docs/tasks/FC-005.md`

Under the accepted initial specialist phase:

- Researcher may perform the read-only feasibility and observability assessment defined by Phase A;
- Test Analyst may subsequently design the executable protocol and validity criteria defined by Phase B;
- no test infrastructure may be changed or deployed;
- no experiment may be executed;
- no artifact, run record, or Researcher synthesis may be created;
- no architecture, governance, role instruction, production source, release, or packaging file may be changed;
- no Git staging, commit, push, branch, worktree, tag, or release operation is authorized.

Every repository write beyond this accepted Planner transition, infrastructure change, deployment, smoketest, substantive run, and evidence-persistence action still requires the later explicit gate described above.

## Acceptance Criteria

- The task tests one handoff-continuity uncertainty rather than general vanilla refresh behavior.
- Researcher identifies verified observable/callable surfaces before Test Analyst relies on them.
- The protocol can distinguish duplicate processing, omitted processing, a bounded continuous result, and insufficient observability.
- Baseline/control logic and the first verified post-handoff vanilla processing opportunity are explicit.
- Required fields and timestamps are recorded at enough transition points to support the planned comparison.
- Selection, inspection, equip, or other UI action is recorded as an intervention/update opportunity and not declared the internal vanilla cause.
- Test Analyst can classify each run as VALID, INVALID, or INCONCLUSIVE without relaxing criteria after seeing the result.
- No production code is changed.
- No harness behavior or experiment execution occurs before its explicit gate.
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

FC-006 is accepted. Hand off first to Researcher for the read-only API/runtime feasibility and observability assessment, then to Test Analyst for the executable protocol and validity criteria. No Test Engineer implementation or runtime experiment is authorized until the later explicit gates are satisfied.
