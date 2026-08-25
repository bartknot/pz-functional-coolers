# Functional Coolers Test Harness

## Purpose

This is the development and test harness for Functional Coolers. It is test infrastructure and is not part of the Functional Coolers release mod.

## Repository Location

`tools/test-harness/FunctionalCoolersTestHarness/`

## Runtime Deployment Target

`C:\Users\bartk\Zomboid\mods\FunctionalCoolersTestHarness`

## Version and State

- Mod ID: `FunctionalCoolersTestHarness`
- Mod version: `0.4.2`
- Source version: `v0.4.2-dev`
- Setup version: `11`

This version implements the bounded FC-004 matched setup and selected-container observability. It requires a fresh dedicated save; saves prepared with an older setup version are rejected rather than repaired.

Build 42.20.3 runtime observation showed that passive waiting did not reliably refresh the prepared freezer steaks. The operator must therefore keep the powered freezer selected during vanilla freezing. This is a standardized pre-measurement setup intervention, not FC-004 experiment evidence.

## FC-004 Setup

The harness prepares two matched player-inventory Coolers named `FC004-A` and `FC004-B`. Each receives one fresh `Base.Steak`, one steak frozen entirely by vanilla, and zero cold packs. It never writes measured Food age, heat, `lastAged`, freezing state, or selected-container state.

Complete the freezer-activation sequence before the matched groups are created:

1. Wait for `status=WAITING_FOR_FREEZER_SELECTION`.
2. Open the nearby powered refrigerator/freezer and select the freezer containing the two steaks.
3. Keep that freezer continuously selected until `status=MATCHED_SETUP_CREATED` appears. Do not move or otherwise manipulate either steak.

`FREEZER_SELECTED` and `FREEZER_SELECTION_LOST` record selection transitions with exact `worldHours`. `FREEZER_SAMPLE` records the selected state and each steak's stable ID, `lastAged`, heat, `freezingTime`, and frozen state once per game minute. If selection is lost, reselect the freezer and keep it selected; do not interpret the interrupted preparation as experiment evidence.

Before `READY`, manually equip:

- `FC004-A` in the primary hand.
- `FC004-B` in the secondary hand.
- Pin and leave the player-inventory window visible.
- Select either FC-004 Cooler.

The selected marker reads the actual client binding at `getPlayerInventory(0).inventoryPane.inventory` and resolves its containing Cooler. It does not use `ItemContainer:isActive()`.

## Controls

Right-click `FC004-A`, `FC004-B`, or any item inside either Cooler. The FC-004 inventory context menu provides these actions:

- `FC-004: Start infrastructure smoketest`.
- `FC-004: Arm experiment (Bart authorization required)`. Do not use this without separate Bart authorization.
- `FC-004: End/cancel active harness run` while a run is active.

The context menu replaces the previous function-key controls because `Ctrl+Shift+F9` also opens a Project Zomboid debug editor in the target runtime.

For the smoketest, perform these observable transitions:

1. Select `FC004-A`.
2. Select `FC004-B`.
3. Close the player inventory.
4. Reopen it and collapse it.
5. Restore it, then unequip either Cooler.
6. Restore `FC004-A` primary, `FC004-B` secondary, pin the visible inventory, and select either FC-004 Cooler.
7. Leave the restored state unchanged for at least ten game minutes.

The smoketest passes only after every transition is detected and the restored state remains stable for ten game minutes. All smoketest output includes `evidenceEligible=false` where it could otherwise be mistaken for experiment evidence.

## Logging

`[FCTH-FC004]` records exact `worldHours`, build and sandbox values, group and Food IDs, primary/secondary assignment, selected Cooler identity, inventory visibility/collapse/pin state, contents, and vanilla Food timing/state fields.

The accepted protocol and current authorization remain canonical in `CURRENT_TASK.md`.

## Release Boundary

This harness must not be packaged with the production Functional Coolers mod.
