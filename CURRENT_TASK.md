# Current Task

## ID

FC-004

## Status

EXPERIMENT AUTHORIZED

## Objective

Execute the accepted controlled matched experiment comparing a sustained selected/active Cooler with an otherwise equivalent unselected Cooler.

The bounded harness implementation and infrastructure smoketest are complete and reviewed. The experimental protocol is accepted, Planner confirms infrastructure readiness, and Bart authorizes both substantive counterbalanced FC-004 runs.

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
7. Emit `TARGET_REACHED` after 4.5 game hours.
8. Pause and emit the final `END` snapshot before changing UI, equip, location, or contents.
9. Preserve the full raw console log and Bart-supplied execution metadata.

Substantive execution of these steps is authorized for both accepted counterbalanced runs. No protocol deviation or additional substantive run is authorized.

### Run Classification

A run is `VALID` only when readiness passes, selected identity remains reliably demonstrated from `BEGIN` through `END`, both Coolers remain correctly carried and equipped, contents remain unchanged, the required duration and sampling are complete, and no unlogged interaction occurs.

A run is `INVALID` when selected identity cannot be demonstrated, selection changes or disappears, the relevant UI closes or collapses, either Cooler is moved or unequipped, contents or starting state are materially mismatched, sampling is insufficient, or the required duration is not reached.

A correctly executed run may be `INCONCLUSIVE` when neither group catches up in the observation window, timing resolution cannot distinguish the groups, the counterbalanced runs disagree, or a hand/UI confound remains unresolved.

Test Analyst owns final run classification. Researcher owns any later cross-run conclusion.

## Authorized Test Infrastructure

The Test Engineer may implement only the minimum FC-004 support needed to:

- Create the two matched `FC004-A` and `FC004-B` Cooler groups deterministically.
- Prepare and distribute their matched fresh and vanilla-frozen steak contents before measurement.
- Identify the actual selected player-inventory container through the client inventory UI binding rather than relying on `ItemContainer:isActive()`.
- Resolve the selected container to its containing Cooler and stable item ID.
- Log exact `worldHours`, selected Cooler identity, inventory-window visibility, collapsed/pinned state, hand assignment, location, contents, and relevant Food state at least once per game minute and on material state transitions.
- Emit explicit `READY`, `TREATMENT_STABLE`, `BEGIN`, `SAMPLE`, `INVALIDATED`, `TARGET_REACHED`, and `END` markers as applicable.
- Detect and report treatment or setup violations without silently repairing them.

This instrumentation observes the treatment and setup. It must not manufacture or directly modify vanilla `lastAged`, Food age, heat, freezing state, or the selected-container state being tested.

## Infrastructure Smoketest

After implementation, Test Engineer may deploy the harness to its documented local runtime target and perform a short non-experimental smoketest that verifies:

1. `FC004-A` selection is identified correctly.
2. Switching to `FC004-B` changes the marker correctly.
3. Closing the player inventory is detected.
4. Collapsing the inventory is detected.
5. Unequipping either Cooler is detected.
6. Restoring the required state is detected.
7. The restored treatment remains correctly logged for ten game minutes.
8. Matched setup, marker names, exact IDs, `worldHours`, and Food-state fields appear as designed.

The smoketest validates infrastructure only. Its output is not FC-004 experimental evidence and must not be used to answer the research question.

## Infrastructure Readiness Result

- Harness `v0.4.2-dev`, setup version `11`, is committed at `352870e`.
- The matched setup and selected-container binding were validated in Project Zomboid Build 42.20.3 with the required sandbox values.
- The complete infrastructure smoketest detected selection of both FC-004 Coolers, inventory closing and collapse, an equip-assignment change, and correct restoration.
- `FC004-B` remained correctly selected while secondary-equipped throughout the required restored stability period.
- The smoketest ended with `status=PASS` and `evidenceEligible=false`.
- Test Analyst accepted the infrastructure as practically executable and ready for Planner handoff.

Bart's subsequent authorization permits both substantive FC-004 runs. Repository persistence of their raw artifacts and canonical run records still requires separate explicit authorization.

## Assigned Role and Sequence

1. Test Engineer implements the bounded harness changes. Complete.
2. Test Engineer performs the authorized infrastructure smoketest and reports exact results and limitations. Complete.
3. Test Analyst reviews practical executability and marker validity. Complete.
4. Planner confirms readiness for the experiment without interpreting runtime results. Complete.
5. Bart separately authorizes the two substantive FC-004 runs. Complete.
6. Test Analyst classifies authorized runs and persists their evidence when separately authorized.
7. Researcher evaluates cross-run conclusions only after canonical run records exist.

## Allowed Changes

- Test Engineer may modify only:
  - `tools/test-harness/FunctionalCoolersTestHarness/42/media/lua/client/FunctionalCoolersTestSetup.lua`
  - `tools/test-harness/FunctionalCoolersTestHarness/42/mod.info`
  - `tools/test-harness/FunctionalCoolersTestHarness/README.md`
  - `tools/test-harness/FunctionalCoolersTestHarness/README.txt`
- Test Engineer may deploy those harness changes to the documented local runtime target solely for the authorized smoketest.
- Planner may update `CURRENT_TASK.md`, `docs/STATUS.md`, and `docs/TODO.md` for this accepted phase transition.
- Nothing under the repository's production `42/` path may be changed.
- No raw substantive experiment artifact or canonical run record may be added until Bart separately authorizes repository evidence persistence.
- Further repository writes require explicit authorization from Bart or a later accepted `CURRENT_TASK.md` revision.

## Acceptance Criteria

- Only the four authorized harness files change during implementation.
- The matched setup produces the two required Cooler groups and equivalent contents without modifying the measured vanilla Food state artificially.
- Selected identity is derived from the actual client inventory UI binding and resolved to the expected Cooler ID.
- Required context, contents, timing, and Food fields are emitted at the required cadence.
- Invalidating state changes are detected and reported.
- The full infrastructure smoketest passes or its exact failure is reported without protocol improvisation.
- No production source changes occur.
- Both substantive runs are executed only after their readiness gates pass and exactly according to the accepted protocol.
- Test Analyst reviews the completed infrastructure before experimental authorization.

## Out of Scope

- Production implementation or fixes
- Architecture changes
- Thermal recalibration
- Save/load, long unattended, vehicles, or multiplayer validation
- Treating the two-game-hour pattern as an established vanilla period
- Repeating FC-003 without a defined research purpose
- Treating infrastructure-smoketest output as experimental evidence
- Committing, pushing, tagging, releasing, branching, or creating a worktree without separate Git authorization

## Known Risks

- The selected player-inventory UI binding and sustained secondary selection passed the infrastructure smoketest but must still remain valid throughout each 4.5-game-hour substantive run.
- The selected and unselected groups may receive unequal vanilla processing for reasons other than selection.
- A single wait duration cannot distinguish a fixed period from a threshold processed at an update opportunity.
- Insufficient post-threshold sampling may repeat the incomplete P1G/FRIDGE outcome from FC-003.
- Adding infrastructure and changing the empirical intervention in one step could introduce multiple separable uncertainties.
