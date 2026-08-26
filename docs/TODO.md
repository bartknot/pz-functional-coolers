# Functional Coolers Backlog

`CURRENT_TASK.md` defines the active operational task. This file records pending, future, or exploratory work; presence here does not authorize implementation. Completed work should normally move to `STATUS.md` or project history rather than remain an active TODO. Do not create parallel task records.

## Active Follow-Up

`FC-005` is complete and its reviewed result is the accepted canonical `docs/ARCHITECTURE.md`. No successor task is currently authorized by this backlog.

- [ ] Have Planner/Bart accept, revise, defer, or reject one bounded successor task derived from the accepted architecture and its unresolved runtime-evidence blockers.


## Near Term

- [ ] Characterize lazy vanilla Food refresh sufficiently for production decisions.
- [ ] Add an environment/calibration guard for `DayLength = 4`, `FoodRotSpeed = 3`, and `FridgeFactor = 3` through a separately authorized implementation task.
- [ ] Evaluate legacy identity/tracking fields such as `FC_coolerID` after clone and context evidence is available.
- [ ] Create a production development deployment script.
- [ ] Create a separate harness deployment script.
- [ ] Establish a runtime log collection workflow.
- [ ] Record the exact deployed commit/build identity and automatic hashes or metadata in runtime artifacts through separately authorized tooling.
- [ ] Document the calibration environment.
- [ ] Create a dedicated test scenario only if future testing justifies it.

## Validation and Calibration

- [ ] Independently replicate the FC-004 counterbalanced selected/active-versus-unselected effect before broad generalization or production decisions.
- [ ] Test whether an observably stale unselected Cooler catches up immediately when first selected after a controlled waiting interval.
- [ ] Distinguish selected-container binding from visible/open/pinned inventory state through a separately accepted experiment if the mechanism remains decision-relevant.
- [ ] Replicate the approximately two-game-hour carried/CONTROL catch-up pattern with varied waiting durations.
- [ ] Obtain complete repeated timing for P1G and powered FRIDGE with sufficient post-threshold sampling.
- [ ] Run long unattended catch-up tests.
- [ ] Test save/load persistence and guard against duplicate or negative elapsed simulation.
- [ ] Run 24-hour and 72-hour unattended tests.
- [ ] Test transfer and context changes without thermal-state reset.
- [ ] Test indoor and outdoor contexts.
- [ ] Investigate vehicle context and temperature APIs.
- [ ] Test clone, item-ID, and `modData` behavior where still useful.
- [ ] Recalibrate Cooler insulation and thermal capacity.
- [ ] Distinguish and calibrate thermal capacity and conductance.
- [ ] Calibrate Food and cold-pack capacities and exchange rates.
- [ ] Calibrate freezer recharge behavior.
- [ ] Characterize vanilla freeze/thaw semantics and improve thaw-rate calibration.
- [ ] Validate frozen Food as meaningful cold thermal mass.
- [ ] Integrate real ambient/local temperature when supported by evidence and accepted design.
- [ ] Consider a latent-heat/phase-transition model after basic calibration is stable.

## Persistence and Contexts

- [ ] Generalize context boundary handling for carried, ground, nested-container, indoor/outdoor, and vehicle contexts.
- [ ] Validate long catch-up efficiency and consider an analytical approach for very long intervals.
- [ ] Validate Cooler transfers between ground, player inventory, portable containers, and shared storage.
- [ ] Preserve physical thermal state while changing only applicable boundary conditions.

## Multiplayer

Accepted direction: multiplayer should eventually use an appropriate authoritative structure and persistent item state. Concrete architecture remains an Architect decision.

- [ ] Establish the server-authoritative design.
- [ ] Ensure essential state is not stored only in transient local Lua tables.
- [ ] Remove single-player assumptions from production paths when appropriate.
- [ ] Test a local multiplayer server with one player.
- [ ] Test save/restart and item pickup/drop in multiplayer.
- [ ] Progress to additional local characters or clients only after the basic server path is stable.
- [ ] Test transfer between players and detect server/client desynchronization.

## UX and Release

- [ ] Provide understandable cold-pack thermal status.
- [ ] Provide useful Cooler thermal feedback.
- [ ] Avoid exposing meaningless internal heat-scale values to players.
- [ ] Clean up production `mod.info` version and description.
- [ ] Create README and user/developer documentation from accepted technical truth.
- [ ] Document configuration and known limitations.
- [ ] Add a changelog.
- [ ] Prepare packaging and Workshop material when release scope is accepted.
- [ ] Create icon/preview artwork later in release preparation.

## Accepted Future Directions

These directions belong to the product vision but are not current feature commitments:

- [ ] Insulation upgrades using period-appropriate materials and relevant skills.
- [ ] A period-appropriate 12V thermoelectric/Peltier Cooler upgrade.
- [ ] Vehicle battery use and plausible electrical efficiency behavior.
- [ ] Warm-water bottles or heat packs using the same thermal model.
- [ ] Warm-food use cases and thermal gameplay trade-offs.
- [ ] A more general thermodynamic-container model after the Cooler is proven.
- [ ] Useful phase-transition and latent-heat behavior.

## Exploratory Ideas

These ideas require product, architecture, runtime, and balance evaluation before acceptance:

- Carpentry, Tailoring, and Maintenance relationships for insulation quality or durability.
- Electronics skill effects on wiring, efficiency, repair, fans, or heat sinks.
- Thermometer-dependent precision or a contextual “Inspect Cooler” interaction.
- Thermal status colors or icon overlays.
- Sun-heated vehicles and other detailed environmental effects.
- Thermos, insulated-bag, hot-meal-container, or related applications of a future general engine.
