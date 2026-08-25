# Current Task

## ID

FC-004

## Status

COMPLETE

## Objective

Complete the bounded automatic-endpoint refinement and the controlled matched selected/active-versus-unselected comparison through canonical Test Analyst evidence and Researcher synthesis.

The endpoint refinement, replacement Run A, counterbalanced Run B, raw-evidence persistence, Test Analyst records, and Researcher synthesis are complete. FC-004 authorizes no further experiment or implementation work.

## Why

The canonical FC-003 evidence established that brief equip/inspection was not necessary for the observed carried-Cooler and CONTROL catch-ups in the valid 2026-08-22 run. It did not determine whether sustained selected/active state has an additional effect.

The FC-003 Researcher synthesis identifies a matched sustained selected/active-versus-unselected comparison as more informative than simply repeating the same brief-inspection A/B/C/D sequence.

## Canonical Evidence

- `docs/tasks/FC-003.md` — preserved final canonical FC-003 task definition and protocol scope.
- `docs/tests/runs/FC-003-2026-08-21.md` — INVALID run, usable only for the narrower diagnostic observations preserved by its Test Analyst record.
- `docs/tests/runs/FC-003-2026-08-22.md` — VALID run.
- `docs/research/FC-003-2026-08-22.md` — accepted cross-run Researcher synthesis.
- Raw runtime artifacts referenced by the two canonical run records.
- `docs/tests/runs/FC-004-2026-08-25-A.md` — VALID replacement Run A.
- `docs/tests/runs/FC-004-2026-08-25-B.md` — VALID counterbalanced Run B.
- `test-artifacts/FC-004/2026-08-25/console-run-a.txt` and `console-run-b.txt` — byte-verified raw runtime artifacts.
- `docs/research/FC-004-2026-08-25.md` — canonical FC-004 Researcher synthesis.

## Research Question

Does a Cooler held selected/active throughout an extended waiting period show different vanilla Food `lastAged` catch-up timing from an otherwise matched Cooler left unselected in the same physical context?

This question must remain distinct from:

- whether brief equip or inspection is necessary;
- which vanilla mechanism implements catch-up;
- whether the approximately two-game-hour recurrence is a fixed period, a threshold, or a threshold processed at an update opportunity.

The protocol may collect evidence relevant to those questions but must not claim to answer them in advance.

## Completion Result

Both accepted counterbalanced runs are VALID. Across the tested pair, the sustained selected/active treatment determined which matched carried and equipped Cooler received continuous observable vanilla Food refresh. The mirrored result followed selected identity while A remained primary and B remained secondary, so fixed group identity and hand assignment do not independently explain the observed split.

This conclusion is bounded to the tested Build 42.20.3 setup and observable Food fields. It does not establish the internal vanilla mechanism, distinguish selection from the bundled visible/open/pinned UI treatment, or determine whether stale unselected Food receives no hidden processing versus deferred catch-up at a later update opportunity.

## Accepted Experimental Protocol

### Matched Groups

Use two groups named `FC004-A` and `FC004-B`.

Each group must have:

- One exact `Base.Cooler`.
- One vanilla-frozen `Base.Steak`.
- One fresh `Base.Steak`.
- Zero cold packs.
- The same starting physical context in player inventory.
- One hand assignment that remains unchanged during measurement.

Both Coolers must remain carried and equipped throughout measurement. One is held in the primary hand and the other in the secondary hand. The selected/active state is the intended experimental variable.

CONTROL may be retained as a player-inventory timing reference, but it is not part of the matched comparison.

### Counterbalanced Runs

The accepted experiment requires two fresh runs:

| Run | Primary | Secondary | Selected |
| --- | --- | --- | --- |
| A | FC004-A | FC004-B | FC004-A |
| B | FC004-A | FC004-B | FC004-B |

Run B must begin from a fresh equivalent setup rather than continuing Run A.

If a secondary-equipped Cooler cannot remain selected/open, do not silently alter this design. Record the infrastructure result and return the hand-assignment confound to Test Analyst.

### Readiness Gate

Immediately before each experimental measurement, an authoritative snapshot must confirm:

- Required runtime/build and sandbox configuration.
- Unique IDs for both Coolers and all test steaks.
- Both Coolers in player inventory.
- Expected primary and secondary hand assignments.
- Equivalent contents and cold-pack count.
- One fresh and one nominally frozen steak per Cooler.
- Starting `lastAged`, age, heat, freezing state, and frozen/thawing state.
- No unexpected extra test steaks.
- The reliable selected-container marker identifies the intended selected Cooler and not the unselected Cooler.

### Experimental Measurement

After readiness succeeds:

1. Keep both Coolers equipped according to the run matrix.
2. Open/select only the assigned selected Cooler and leave its container view visible and unchanged.
3. Emit `BEGIN` with exact `worldHours` only after the treatment is stable.
4. Run for at least 4.5 game hours.
5. Do not click, inspect, transfer, move, consume, equip, unequip, or switch any test item or container during measurement.
6. Sample selected identity, context, contents, and Food timing at least once per game minute.
7. Emit `TARGET_REACHED` after 4.5 game hours and automatically emit final `END` from the same authoritative state snapshot.
8. Mark the harness run complete immediately after automatic `END`. The operator may then pause or exit without needing to monitor the scrolling console or interact with a test container to end measurement.
9. Preserve the full raw console log and Bart-supplied execution metadata.

The accepted execution authorization covered exactly one replacement Run A and the existing Run B. Both are complete. No protocol deviation or additional substantive run is authorized.

### Run Classification

A run is `VALID` only when readiness passes, selected identity remains reliably demonstrated from `BEGIN` through `END`, both Coolers remain correctly carried and equipped, contents remain unchanged, the required duration and sampling are complete, and no unlogged interaction occurs.

A run is `INVALID` when selected identity cannot be demonstrated, selection changes or disappears, the relevant UI closes or collapses, either Cooler is moved or unequipped, contents or starting state are materially mismatched, sampling is insufficient, or the required duration is not reached.

A correctly executed run may be `INCONCLUSIVE` when neither group catches up in the observation window, timing resolution cannot distinguish the groups, the counterbalanced runs disagree, or a hand/UI confound remains unresolved.

Test Analyst owns final run classification. Researcher owns any later cross-run conclusion.

## Attempted Run A Assessment

- The first attempted Run A reached `TARGET_REACHED` after `4.500626` game hours with selected identity, hand assignment, UI state, contents, and sampling intact.
- It emitted no `INVALIDATED` marker but ended when the game exited without the protocol-required `END` marker.
- Test Analyst classified the attempt `INVALID` for the accepted experiment solely because the required endpoint marker was absent.
- Its observations may be retained as narrower diagnostic evidence if repository persistence is later authorized, but they do not replace the authorized counterbalanced runs or establish the research conclusion.

## Completed Test Infrastructure Authorization

The Test Engineer was authorized to implement only the minimum FC-004 support needed to:

- Create the two matched `FC004-A` and `FC004-B` Cooler groups deterministically.
- Prepare and distribute their matched fresh and vanilla-frozen steak contents before measurement.
- Identify the actual selected player-inventory container through the client inventory UI binding rather than relying on `ItemContainer:isActive()`.
- Resolve the selected container to its containing Cooler and stable item ID.
- Log exact `worldHours`, selected Cooler identity, inventory-window visibility, collapsed/pinned state, hand assignment, location, contents, and relevant Food state at least once per game minute and on material state transitions.
- Emit explicit `READY`, `TREATMENT_STABLE`, `BEGIN`, `SAMPLE`, `INVALIDATED`, `TARGET_REACHED`, and `END` markers as applicable.
- Detect and report treatment or setup violations without silently repairing them.
- When the 4.5-game-hour target is reached, emit `TARGET_REACHED` and `END | status=COMPLETE` from the same state snapshot, then stop further experiment sampling.

This instrumentation observes the treatment and setup. It must not manufacture or directly modify vanilla `lastAged`, Food age, heat, freezing state, or the selected-container state being tested.

The automatic endpoint must not pause the game, change game speed, change UI state, alter equipment or contents, or modify measured Food state. It only defines and records the completed measurement endpoint.

## Infrastructure Smoketest

After implementation, Test Engineer was authorized to deploy the harness to its documented local runtime target and perform a short non-experimental smoketest that verified:

1. `FC004-A` selection is identified correctly.
2. Switching to `FC004-B` changes the marker correctly.
3. Closing the player inventory is detected.
4. Collapsing the inventory is detected.
5. Unequipping either Cooler is detected.
6. Restoring the required state is detected.
7. The restored treatment remains correctly logged for ten game minutes.
8. Matched setup, marker names, exact IDs, `worldHours`, and Food-state fields appear as designed.

The smoketest validates infrastructure only. Its output is not FC-004 experimental evidence and must not be used to answer the research question.

For the automatic-endpoint refinement, Test Engineer was required to verify the source path from target detection through `TARGET_REACHED`, automatic `END`, and completed state, then deploy the reviewed harness. The existing smoketest demonstrated automatic duration-threshold completion in smoketest mode. Runtime verification of the experiment endpoint occurred during the authorized replacement Run A; no shortened experiment or additional substantive validation run is authorized.

## Infrastructure Readiness Result

- Harness `v0.4.3-dev`, setup version `11`, including automatic experiment completion, is committed with the evidence at `d302f08`.
- The matched setup and selected-container binding were validated in Project Zomboid Build 42.20.3 with the required sandbox values.
- The complete infrastructure smoketest detected selection of both FC-004 Coolers, inventory closing and collapse, an equip-assignment change, and correct restoration.
- `FC004-B` remained correctly selected while secondary-equipped throughout the required restored stability period.
- The smoketest ended with `status=PASS` and `evidenceEligible=false`.
- Test Analyst accepted the infrastructure as practically executable and ready for Planner handoff.
- The automatic experiment endpoint was runtime-verified in both valid substantive runs: `TARGET_REACHED` and `END | status=COMPLETE` used the same endpoint snapshot and no experiment samples followed `END`.
- Both valid run artifacts and canonical Test Analyst records are persisted in the repository.

## Assigned Role and Sequence

1. Test Engineer implemented the original bounded harness changes. Complete.
2. Test Engineer and Test Analyst completed and accepted the infrastructure smoketest. Complete.
3. Planner confirmed readiness and Bart authorized the original counterbalanced runs. Complete.
4. Test Analyst classified the first attempted Run A `INVALID` because its required `END` marker was absent. Complete.
5. Bart authorized automatic-`END` instrumentation and exactly one replacement Run A. Complete.
6. Test Engineer implemented, source-verified, and deployed the bounded endpoint refinement. Complete.
7. Bart reviewed and accepted the endpoint refinement before replacement Run A. Complete.
8. Test Analyst classified the fresh replacement Run A `VALID`. Complete.
9. Test Analyst classified the fresh counterbalanced Run B `VALID`. Complete.
10. Test Analyst persisted the authorized assessed evidence. Complete.
11. Researcher persisted the canonical cross-run synthesis. Complete.
12. Planner closed FC-004 and updated canonical project state. Complete.

## Allowed Changes

- FC-004 is complete and authorizes no further harness changes, experiment execution, evidence writes, architecture changes, or production changes.
- Bart's closeout authorization permits only the canonical Researcher synthesis and Planner updates to `CURRENT_TASK.md`, `docs/STATUS.md`, and `docs/TODO.md` completed in this transition.
- Nothing under the repository's production `42/` path may be changed.
- Any successor experiment, infrastructure change, or other repository write requires new authorization from Bart or a later accepted `CURRENT_TASK.md` revision.

## Acceptance Criteria

- Only the four authorized harness files change during implementation.
- The matched setup produces the two required Cooler groups and equivalent contents without modifying the measured vanilla Food state artificially.
- Selected identity is derived from the actual client inventory UI binding and resolved to the expected Cooler ID.
- Required context, contents, timing, and Food fields are emitted at the required cadence.
- Invalidating state changes are detected and reported.
- `TARGET_REACHED` and `END | status=COMPLETE` use the same authoritative endpoint snapshot, after which no further experiment samples are emitted.
- Automatic completion changes no game, UI, equipment, contents, or measured Food state.
- The full infrastructure smoketest passes or its exact failure is reported without protocol improvisation.
- No production source changes occur.
- Replacement Run A and Run B are executed only after their readiness gates pass and exactly according to the accepted protocol.
- Test Analyst reviews the completed infrastructure before experimental authorization.

## Out of Scope

- Production implementation or fixes
- Architecture changes
- Thermal recalibration
- Save/load, long unattended, vehicles, or multiplayer validation
- Treating the two-game-hour pattern as an established vanilla period
- Repeating FC-003 without a defined research purpose
- Treating infrastructure-smoketest output as experimental evidence
- Adding pause automation, visible notifications, new controls, shortened experiment modes, or any endpoint behavior beyond automatic logging and completion
- Executing any substantive run beyond the authorized replacement Run A and Run B
- Committing, pushing, tagging, releasing, branching, or creating a worktree without separate Git authorization

## Residual Uncertainties

- The FC-004 effect has one valid counterbalanced pair but no independent replication.
- The treatment bundles selected identity with a visible, pinned, open inventory context; the responsible subcomponent is unresolved.
- Observable stale fields do not distinguish absent vanilla processing from deferred catch-up at a later update opportunity.
- The internal relationship between FC-003's approximately two-game-hour catch-ups and FC-004's continuous selected refresh remains unresolved.
- Generalization to other builds, contexts, equipment states, durations, and Food items requires further evidence.
