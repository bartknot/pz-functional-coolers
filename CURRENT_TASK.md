# Current Task

## ID

FC-003

## Status

TESTING

## Objective

Validate the newly added FRIDGE and context diagnostics and execute the controlled A/B/C/D runtime experiment intended to characterize vanilla food refresh/catch-up behavior across cooler contexts and a powered refrigerator control.

## Why

The elapsed-time simulation fixed the previously observed carried-versus-ground discrepancy, but vanilla Food timing fields such as `lastAged` appear to refresh lazily or irregularly.

The current diagnostics were added to observe vanilla timing and player/container context without yet changing the thermal model.

## Current State

- Project Zomboid runtime baseline is Build 42.20.3.
- Elapsed-time simulation is committed.
- FRIDGE/context diagnostics are committed.
- Diagnostics passed an initial runtime smoke test.
- The load marker `diagnostics=FRIDGE_CONTEXT` was observed.
- FRIDGE detection and readiness reporting were observed working.
- The first full experiment attempt was invalid.
- P0, P1, P2, and P4 had not been moved into player inventory.
- Therefore, not all required groups were READY.
- No experimental conclusions may be drawn from that run.

## Calibration Preconditions

The controlled calibration sandbox must use:

- `DayLength = 4`
- `FoodRotSpeed = 3`
- `FridgeFactor = 3`

If these values differ, do not treat the run as a valid calibration experiment.

The Functional Coolers Test Harness must reach:

```text
[FCTH] status=READY_TO_DISTRIBUTE
```

before manual distribution begins.

## Required Test Groups

### P0

- `Base.Cooler`
- 0 cold packs
- 1 fresh steak
- 1 frozen steak
- Carried in player inventory during measurement

### P1

- `Base.Cooler`
- 1 cold pack
- 1 fresh steak
- 1 frozen steak
- Carried in player inventory during measurement

### P2

- `Base.Cooler`
- 2 cold packs
- 1 fresh steak
- 1 frozen steak
- Carried in player inventory during measurement

### P4

- `Base.Cooler`
- 4 cold packs
- 1 fresh steak
- 1 frozen steak
- Carried in player inventory during measurement

### P1G

- `Base.Cooler`
- 1 cold pack
- 1 fresh steak
- 1 frozen steak
- Remains on the ground during measurement

### CONTROL

- 1 fresh steak
- 1 frozen steak
- Directly in player inventory

### FRIDGE

- Powered vanilla refrigerator
- 1 fresh steak
- 1 frozen steak

### NEUTRAL

- Neutral inventory container used as the selected context when no test group is being intentionally inspected

## Readiness Gate

Measurement must not begin until all of the following report READY:

- P0
- P1
- P2
- P4
- P1G
- CONTROL
- FRIDGE

If any group reports MISSING or WAITING, the experiment has not started and must not be interpreted as a valid run.

READY status must be confirmed immediately before Phase A begins. A group that previously reported READY may return to WAITING if its nominally frozen steak thaws before measurement starts.

## A/B/C/D Test Procedure

After all groups report READY:

Record the current `worldHours` value from diagnostics at the start and end of each phase where practical.

### Phase A

- Select NEUTRAL.
- Leave all test groups untouched for approximately 2 game hours.
- Do not move food, cold packs, or coolers.

### Phase B

- Inspect/select the groups in this order:
  1. P4
  2. P2
  3. P1
  4. P1G
  5. P0
  6. FRIDGE
- Do not move items.
- For each group, perform only the minimum UI interaction required to open/select that container or context. Do not move, equip, transfer, consume, or otherwise manipulate any test item.
- Return to NEUTRAL after inspection.

### Phase C

- Leave all groups untouched for approximately another 2 game hours.
- Keep NEUTRAL selected.
- Do not alter the setup.

### Phase D

- Repeat the Phase B inspection sequence.
- Do not move items.
- For each group, perform only the minimum UI interaction required to open/select that container or context. Do not move, equip, transfer, consume, or otherwise manipulate any test item.

The purpose is to observe whether vanilla timing/context state changes around access or inactivity.

Do not assume beforehand that opening, selecting, or inspecting a container causes a refresh. The experiment is intended to determine that empirically.

## Allowed Changes

None to production source for this task.

Test infrastructure exception for FC-003:

- The already working Functional Coolers Test Harness may be imported unchanged into:
  `tools/test-harness/FunctionalCoolersTestHarness/`
- A minimal README may document its purpose, runtime deployment target, and known harness version/state.
- No behavioral changes to the harness are authorized.
- Nothing under `42/` production source may be changed.

Project documentation exception for FC-003:

- `docs/PROJECT_CHARTER.md`, `docs/STATUS.md`, and `docs/TODO.md` may be created and reviewed.
- FC-003 remains the active operational task.
- This exception does not authorize production changes or harness behavioral changes.
- These documents may record accepted product scope, current project state, and backlog.
- They must not invent architecture or runtime conclusions.
- `CURRENT_TASK.md` remains authoritative for what is operationally authorized now.

This task is runtime validation and evidence collection.

If a defect is discovered that appears to require a source change:

- Stop.
- Record the evidence.
- Create or request a separate implementation task.

Do not fix production code as part of FC-003.

## Acceptance Criteria

- Functional Coolers loads with `diagnostics=FRIDGE_CONTEXT`.
- No new Functional Coolers Lua errors occur.
- Calibration sandbox values match the required environment.
- P0, P1, P2, P4, P1G, CONTROL, and FRIDGE all report READY before measurement begins.
- The complete A/B/C/D protocol is executed without altering the test setup.
- The resulting console log is preserved for analysis.
- Validity or invalidity of the experiment is explicitly recorded.
- No conclusions are drawn beyond what the log supports.

## Out of Scope

- Environment guard implementation
- Thermal recalibration
- Freeze/thaw redesign
- Save/load redesign
- Multiplayer
- Vehicles
- Electrical cooler
- UX
- Release packaging
- Production fixes discovered during this experiment

## Known Risks

- Vanilla `lastAged` behavior is not yet understood.
- `isFrozen()` and `freezingTime` do not map one-to-one.
- Interacting with containers may itself affect the observed vanilla state.
- Incomplete manual distribution invalidates the experiment.
- A group may lose READY status before measurement if its nominally frozen steak thaws.
- Diagnostic observations must not be mistaken for established causal behavior.
