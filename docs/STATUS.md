# Functional Coolers Project Status

## Current Project State

- Repository: `pz-functional-coolers`
- Branch at this snapshot: `main`
- Inspected HEAD: `5988ff89430fc6f7749630d2912e755eda8cae66`
- Runtime baseline recorded by the active task: Project Zomboid Build 42.20.3
- Active task: FC-003, status `TESTING`
- Production source identifies itself as `Prototype v0.3.0-dev`.
- The elapsed-time simulation and FRIDGE/context diagnostics are committed.
- The Functional Coolers Test Harness is tracked in the same repository.

`CURRENT_TASK.md` remains authoritative for current operational scope and procedure.

## Current Implementation

Direct inspection of `42/media/lua/server/FunctionalCoolers.lua` shows that the current prototype:

- Recognizes Cooler contents in carried and ground contexts.
- Stores Cooler and cold-pack thermal state in item `modData`.
- Stores managed Food temperature, age, and freezing state.
- Uses `getGameTime():getWorldAgeHours()` and `FC_lastThermalUpdateHours` as the basis for stepped elapsed-time simulation and short catch-up processing.
- Exchanges model heat between ambient, Cooler, cold packs, and Food.
- Writes managed Food age, heat, and freezing state back through available Food APIs.
- Recharges cold packs found in powered cold storage.
- Provides readiness and diagnostic output for P0, P1, P2, P4, P1G, CONTROL, and FRIDGE.
- Emits vanilla, Cooler-context, player-context, refrigerator, and catch-up diagnostics.
- Loads with the source marker `diagnostics=FRIDGE_CONTEXT`.

The current capacities, exchange rates, ambient reference, base aging rate, thaw rate, and freezer recharge rate are provisional calibration/model parameters, not final physical constants.

## Established Runtime and API Findings

The following are recorded project findings from the historical reports accepted by Bart. Their raw console logs are not currently tracked, so this status does not claim independent re-verification:

- Vanilla `Base.Cooler` and `Base.Coldpack` did not provide the required cooling behavior.
- Container-level `customTemperature` and `ageFactor` were insufficient for nested Food in a carried Cooler.
- Direct Food age, heat, and freezing-state getters/setters were usable in the tested runtime.
- `Food:updateFreezing()` was not Lua-callable in that runtime.
- The older vanilla-delta correction architecture failed when nested Food updates became stale.
- Elapsed world time replaced vanilla Food deltas as the simulation time basis.
- A recorded successful elapsed-time run produced near parity between carried P1 and ground P1G.
- That run showed an ordered response from 0, 1, 2, and 4 cold packs; P0 behaved approximately like ambient/control.
- Vanilla `lastAged` appeared lazy or irregular across contexts.
- `isFrozen()` and `freezingTime` did not map one-to-one.
- Short catch-up over missed minutes was observed; long unattended and save/load catch-up remains unvalidated.

These findings constrain further work but do not establish undocumented causes for vanilla refresh behavior.

## Test Infrastructure

The tracked Functional Coolers Test Harness is located at `tools/test-harness/FunctionalCoolersTestHarness/`.

- Mod ID: `FunctionalCoolersTestHarness`
- Mod version: `0.3.7`
- Source version: `v0.3.7-dev`
- Setup version: `9`

Its source prepares the fixed single-player calibration setup, named Cooler groups, freezer cohort, NEUTRAL container, and readiness workflow. It reports `[FCTH] status=READY_TO_DISTRIBUTE` before Bart manually distributes test items. The harness is test infrastructure and must not ship with the production mod.

## Current Active Investigation

FC-003 investigates whether vanilla Food timing/context state changes around container access or inactivity. It uses a controlled A/B/C/D sequence with Cooler groups, CONTROL, and a powered FRIDGE reference.

The current diagnostics passed the smoke test recorded in `CURRENT_TASK.md`. The first full attempt was invalid because P0, P1, P2, and P4 were not moved into player inventory and not all required groups were READY. No experimental conclusion may be drawn from that attempt. A valid complete A/B/C/D run remains pending.

## Known Limitations and Unresolved Questions

- The trigger and significance of lazy vanilla Food refresh remain unresolved.
- Long unattended, chunk-unloaded, save/load, and 24/72-hour catch-up are unvalidated.
- Freeze/thaw semantics and rates require further characterization and calibration.
- Real local ambient, indoor/outdoor, and vehicle boundary conditions are not integrated.
- Transfers, nested contexts, and vehicle contexts require validation.
- Clone/item-ID/`modData` behavior and the continuing need for `FC_coolerID` remain unresolved.
- Multiplayer is neither implemented nor tested; current production diagnostics still contain single-player assumptions such as `getSpecificPlayer(0)`.
- Canonical architecture and state-ownership documentation has not yet been established.
- The calibration environment is specified but not automatically guarded.

## Repository and Version Inconsistencies

- Production source says `Prototype v0.3.0-dev`, while production `42/mod.info` declares `modversion=0.2`.
- Production `mod.info` still describes the mod as a diagnostic test rather than the intended product.
- The only release tag is the historical `v0.2.0`; v0.3 remains an untagged development line.

These inconsistencies are recorded here, not fixed by this status task.

## Current Development Position

The project has moved beyond the superseded vanilla-delta approach to an elapsed-time managed prototype. The immediate priority is evidence: execute a valid FC-003 run, preserve its output, classify the run, and determine what it supports before changing production behavior. Environment guards, deeper persistence work, calibration, additional contexts, multiplayer, UX, and release preparation follow through separately accepted tasks.
