# Current Task

## ID

FC-004

## Status

PROTOCOL DESIGN

## Objective

Design a controlled matched experiment that tests whether keeping a Cooler selected/active throughout an extended waiting period changes vanilla Food `lastAged` catch-up timing relative to an otherwise equivalent Cooler left unselected.

This task defines and reviews the protocol only. Runtime execution begins only after Bart accepts the completed protocol.

## Why

The canonical FC-003 evidence established that brief equip/inspection was not necessary for the observed carried-Cooler and CONTROL catch-ups in the valid 2026-08-22 run. It did not determine whether sustained selected/active state has an additional effect.

The FC-003 Researcher synthesis identifies a matched sustained selected/active-versus-unselected comparison as more informative than simply repeating the same brief-inspection A/B/C/D sequence.

## Canonical Evidence

- `docs/tasks/FC-003.md` — preserved final canonical FC-003 task definition and protocol scope.
- `docs/tests/runs/FC-003-2026-08-21.md` — INVALID run, usable only for the narrower diagnostic observations preserved by its Test Analyst record.
- `docs/tests/runs/FC-003-2026-08-22.md` — VALID run.
- `docs/research/FC-003-2026-08-22.md` — accepted cross-run Researcher synthesis.
- Raw runtime artifacts referenced by the two canonical run records.

## Research Question

Does a Cooler held selected/active throughout an extended waiting period show different vanilla Food `lastAged` catch-up timing from an otherwise matched Cooler left unselected in the same physical context?

This question must remain distinct from:

- whether brief equip or inspection is necessary;
- which vanilla mechanism implements catch-up;
- whether the approximately two-game-hour recurrence is a fixed period, a threshold, or a threshold processed at an update opportunity.

The protocol may collect evidence relevant to those questions but must not claim to answer them in advance.

## Assigned Role and Sequence

1. Test Analyst designs the controlled protocol and validity criteria.
2. Test Analyst identifies any observability or reproducibility requirement that belongs to Test Engineer.
3. Planner checks scope and sequencing without replacing Test Analyst experimental judgment.
4. Bart reviews and accepts the protocol and any separately proposed infrastructure task.
5. Runtime execution, evidence persistence, run classification, and Researcher synthesis occur only through subsequently authorized steps.

## Protocol Design Requirements

The proposed protocol must:

- Use otherwise matched Cooler groups with equivalent contents and starting state.
- Hold both groups in the same physical context unless the protocol explicitly identifies context as a separate controlled factor.
- Keep one group selected/active for the defined measurement interval and the matched group unselected.
- Avoid inspection, transfer, item movement, or other unequal intervention during the measurement interval.
- Define how selected/active state is established and verified without assuming that UI appearance proves runtime state.
- Define an authoritative readiness snapshot for group identity, location, contents, fresh/frozen state, and any required cold-pack state.
- Record exact `worldHours` boundaries for baseline, intervention, and observation windows.
- Sample long enough before and after the candidate two-game-hour threshold to capture delayed P1G/FRIDGE-like behavior where relevant.
- Define whether varied waiting durations are required to help distinguish fixed-period behavior from threshold/update-opportunity behavior.
- Define controls, validity criteria, invalidating deviations, evidence limitations, and required Bart-supplied execution metadata.
- Preserve raw runtime evidence and produce a canonical Test Analyst run record after any authorized execution.

The Test Analyst should prefer the smallest design that isolates sustained selected/active state as the primary uncertainty.

## Test Infrastructure Boundary

Possible infrastructure improvements include:

- automatic Cooler filling or distribution;
- explicit phase markers;
- stronger final-readiness logging;
- reliable selected/active-state markers;
- extended post-intervention sampling.

These are infrastructure candidates, not empirical conclusions and not automatically authorized work. If the protocol requires a harness or diagnostic change, the Test Analyst must identify the minimum requirement and hand it to Test Engineer through a separate Bart-authorized task.

## Allowed Changes

- No production source changes are authorized.
- No harness or test-tooling changes are authorized.
- No runtime artifact import is authorized because execution has not begun.
- Planner may update `CURRENT_TASK.md`, `docs/STATUS.md`, and `docs/TODO.md` within this authorized project-state transition.
- Further repository writes require explicit authorization from Bart or a later accepted `CURRENT_TASK.md` revision.

## Acceptance Criteria

- The Test Analyst proposes a complete, controlled, practically executable protocol.
- Sustained selected/active state is the primary experimental variable.
- Matched controls and authoritative readiness evidence are defined.
- Timing, sampling duration, and post-threshold observation are explicit.
- Validity and invalidating deviations are explicit.
- Empirical questions are separated from infrastructure improvements.
- Any required Test Engineer work is bounded and routed separately.
- Bart accepts the protocol before runtime execution begins.

## Out of Scope

- Executing FC-004 before protocol acceptance
- Production implementation or fixes
- Architecture changes
- Thermal recalibration
- Save/load, long unattended, vehicles, or multiplayer validation
- Treating the two-game-hour pattern as an established vanilla period
- Repeating FC-003 without a defined research purpose

## Known Risks

- Current diagnostics may not reliably prove sustained selected/active state.
- Establishing selection may require equip or UI context that introduces another variable.
- The selected and unselected groups may receive unequal vanilla processing for reasons other than selection.
- A single wait duration cannot distinguish a fixed period from a threshold processed at an update opportunity.
- Insufficient post-threshold sampling may repeat the incomplete P1G/FRIDGE outcome from FC-003.
- Adding infrastructure and changing the empirical intervention in one step could introduce multiple separable uncertainties.
