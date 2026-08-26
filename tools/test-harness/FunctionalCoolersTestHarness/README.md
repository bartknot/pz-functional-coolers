# Functional Coolers Test Harness

## Purpose

This is the development and test harness for Functional Coolers. It is test infrastructure and is not part of the Functional Coolers release mod.

## Repository Location

`tools/test-harness/FunctionalCoolersTestHarness/`

## Runtime Deployment Target

`C:\Users\bartk\Zomboid\mods\FunctionalCoolersTestHarness`

## Version and State

- Mod ID: `FunctionalCoolersTestHarness`
- Mod version: `0.5.2`
- Source version: `v0.5.2-dev`
- Setup version: `14`

This version implements the bounded FC-006 managed-to-vanilla Food handoff setup and infrastructure smoketest. It requires a fresh dedicated save; saves prepared with an older setup version are rejected rather than repaired.

The production Functional Coolers mod must be disabled. Enable only the test harness among the Functional Coolers mods. The required sandbox values are `DayLength = 4`, `FoodRotSpeed = 3`, and `FridgeFactor = 3` on Project Zomboid Build 42.20.4.

## FC-006 Setup

The harness creates two player-inventory Coolers:

- `FC006-GUARD`, which remains empty and selected/active;
- `FC006-TEST`, which remains unselected and contains `FC006-V`, `FC006-A`, and `FC006-U` `Base.Steak` items.

V is the vanilla-sync reference, A is the aligned candidate, and U is the unaligned sensitivity control. Setup aligns all three through `setAutoAge()` and projects the shared public state `age=0.5`, `heat=1.0`, and `freezingTime=80.0`.

Before `READY`, manually:

- Equip `FC006-GUARD` in the primary hand.
- Equip `FC006-TEST` in the secondary hand.
- Pin and leave the player-inventory window visible.
- Select `FC006-GUARD` and leave it selected.

The selected marker reads the actual client binding at `getPlayerInventory(0).inventoryPane.inventory` and resolves its containing Cooler.

## Controls

Right-click an FC-006 Cooler or one of the V/A/U items. The context menu provides:

- `FC-006: Start infrastructure smoketest`.
- `FC-006: Arm experiment (Bart authorization required)`. Do not use this without separate Bart authorization.
- `FC-006: End/cancel active harness run` while a run is active.

The experiment action being present does not authorize a substantive run.

## Authorized Infrastructure Smoketest

Use a fresh dedicated save and wait for `MATCHED_SETUP_CREATED`. Prepare the required equip/UI state, wait for `READY | status=READY`, then choose `FC-006: Start infrastructure smoketest`. Do not interact with the UI, Coolers, equipment, or their contents until automatic END.

The smoketest first uses U as a disposable thaw-response item. It verifies the required setters, phase flags, stale-version guard, and one explicit `updateAge()` response after exactly ten game minutes. The thaw gate requires `freezingTimeBefore - freezingTimeAfter > 0.05` and elapsed time within `0.001` game hour of the target.

After that gate passes, the same smoke performs an expected mismatch probe through the shared handoff-commit guard. It must emit `INVALIDATED | status=EXPECTED_SMOKE_PROBE | reason=public_phase_state_mismatch` without emitting `HANDOFF_COMMITTED` for that probe. It then resets V/A/U and executes the real shared protocol state-machine with `evidenceEligible=false`: one getter-only game hour, handoff, and three explicit update rounds ten game minutes apart. Final PASS requires the exact marker order `BEGIN,PRE_HANDOFF,HANDOFF_COMMITTED,UPDATE_1,UPDATE_2,UPDATE_3,END` and a successful final baseline reset.

At `DayLength=4` the complete smoke takes approximately 16 minutes 40 seconds of real time on normal speed after `SMOKE_BEGIN`. Do not use fast-forward because every scheduled boundary has a strict `0.001` game-hour tolerance.

All setup, mismatch-probe, and protocol-dry-run output is marked `evidenceEligible=false`. Smoketest output is not FC-006 empirical evidence. A failed smoketest blocks a substantive run pending Test Analyst review.

## Separately Gated Experiment Path

The implemented path waits one game hour without harness state updates, applies the V/A/U handoff sequences in one callback, requires equal projected values and exact `frozen=false`, `freezing=false`, `thawing=true` flags before `HANDOFF_COMMITTED`, then performs three explicit `updateAge()` rounds at ten-game-minute intervals. It automatically emits END after UPDATE_3.

This path must not be armed until Bart separately authorizes a substantive FC-006 run.

## Logging

`[FCTH-FC006]` records exact `worldHours`, build and sandbox values, enabled production-mod state, group and Food IDs, primary/secondary assignment, selected Cooler identity, inventory visibility/collapse/pin state, contents, `lastAged`, age, heat, freezing time, and public phase flags.

The accepted protocol and current authorization remain canonical in `CURRENT_TASK.md`.

## Release Boundary

This harness must not be packaged with the production Functional Coolers mod.
