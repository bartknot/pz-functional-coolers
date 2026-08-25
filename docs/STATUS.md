# Functional Coolers Project Status

## Current Project State

- Repository: `pz-functional-coolers`
- Branch at this snapshot: `main`
- Canonical evidence and workflow inspected through HEAD: `2809410db1d53e5d3e6ff5cd7065ebb01c9f5d9e`
- Runtime baseline recorded by the active task: Project Zomboid Build 42.20.3
- Active task: WF-004, status `COMPLETE`; no successor task is currently authorized.
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

## Canonical FC-003 Evidence Findings

FC-003 is complete as an evidence task. Its canonical evidence chain consists of:

- `docs/tests/runs/FC-003-2026-08-21.md` — INVALID run.
- `docs/tests/runs/FC-003-2026-08-22.md` — VALID run.
- `docs/research/FC-003-2026-08-22.md` — accepted Researcher synthesis.
- The raw runtime artifacts referenced by both run records.

Its superseded final task definition and protocol scope are preserved separately in `docs/tasks/FC-003.md`.

The accepted synthesis establishes, within the tested valid run, that brief equip/inspection was not necessary for the observed carried-Cooler and CONTROL `lastAged` catch-ups: those catch-ups occurred before the recorded intervention in both observation windows.

P1G and powered FRIDGE refreshed later than carried/CONTROL in the first valid observation window and before their own inspection. The context timing difference is established for that run, while its mechanism and generality require replication.

The approximately two-game-hour carried/CONTROL recurrence is meaningful candidate evidence for a periodic or threshold-based vanilla mechanism, but one valid run and two intervals do not establish a general period or distinguish a timer from a threshold processed at an update opportunity.

## Test Infrastructure

The tracked Functional Coolers Test Harness is located at `tools/test-harness/FunctionalCoolersTestHarness/`.

- Mod ID: `FunctionalCoolersTestHarness`
- Mod version: `0.4.3`
- Source version: `v0.4.3-dev`
- Setup version: `11`

Its source prepares the deterministic matched `FC004-A` and `FC004-B` Cooler groups, uses vanilla freezing for their frozen steaks, observes the actual player-inventory selected-container binding, logs exact setup and Food state, detects invalidating UI, selection, equip, context, or contents changes, and automatically completes an experiment at the accepted 4.5-game-hour endpoint. The complete Build 42.20.3 infrastructure smoketest passed, including sustained selection of secondary-equipped `FC004-B`. The automatic endpoint was runtime-verified in both valid FC-004 runs. Smoketest output is marked `evidenceEligible=false`. The harness is test infrastructure and must not ship with the production mod.

## Canonical FC-004 Evidence Findings

FC-004 is complete. Its canonical evidence chain consists of:

- `docs/tests/runs/FC-004-2026-08-25-A.md` — VALID replacement Run A.
- `docs/tests/runs/FC-004-2026-08-25-B.md` — VALID counterbalanced Run B.
- `docs/research/FC-004-2026-08-25.md` — accepted Researcher synthesis.
- The byte-verified raw artifacts referenced by both run records.
- `docs/tasks/FC-004.md` — preserved final FC-004 task definition.

The accepted synthesis establishes with high confidence within the tested Build 42.20.3 scope that the sustained selected/active treatment determined which matched carried and equipped Cooler received continuous observable vanilla Food refresh. The update pattern reversed with selected identity while A remained primary and B remained secondary, so fixed group identity and hand assignment do not independently explain the split.

This does not establish that selection is necessary for every possible catch-up, identify the internal vanilla update mechanism, distinguish selection from the bundled visible/open/pinned UI treatment, or determine whether unselected stale Food receives no hidden processing versus deferred catch-up at a later update opportunity. One counterbalanced pair is not independent replication.

## Workflow Planning State

- FC-003 and FC-004 demonstrated that the layered canonical context, explicit authorization boundaries, experiment-validity rules, evidence chain, task archiving, and Role/Task Git traceability are operationally useful.
- No material role-handoff context loss was identified that justifies a mandatory handoff template or additional standing checklist.
- `WF-004` completed one bounded milestone retrospective addressing three governance gaps: durable reconciliation of direct Bart authorization, the limit of procedural role separation without cognitive independence, and a lightweight trigger for future retrospectives.
- Separately, Bart explicitly accepted developing and validating a reusable AI-assisted development workflow as a durable second Project Charter objective.
- The review added no handoff template, pre-flight checklist, conflict-resolution system, debt taxonomy, or new document hierarchy because current evidence did not justify them.

## Known Limitations and Unresolved Questions

- The vanilla processing path responsible for pre-inspection carried/CONTROL catch-up remains unresolved.
- Sustained selected/active state versus unselected state is tested by one valid counterbalanced pair; independent replication and broader generalization remain outstanding.
- Which part of the selected/visible/open/pinned UI treatment supplies the update opportunity remains unresolved.
- Whether stale unselected Food receives no hidden processing or catches up when first selected remains unresolved.
- The approximately two-game-hour recurrence requires replication and varied-duration testing.
- Complete repeated timing for P1G and FRIDGE remains unresolved.
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

The project has moved beyond the superseded vanilla-delta approach to an elapsed-time managed prototype and completed both the FC-003 and FC-004 evidence chains. FC-004 provides a bounded, counterbalanced selected/active refresh finding but no automatic architecture or production consequence. WF-004 is complete. No successor task is currently authorized. The next justified product-development dependency is a minimal canonical architecture baseline before further production implementation. Empirical follow-ups and Git/runtime provenance tooling remain separate backlog concerns and require their own accepted tasks before implementation.
