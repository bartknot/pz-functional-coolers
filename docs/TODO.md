# Functional Coolers Backlog

`CURRENT_TASK.md` defines the active operational task. This file records pending, future, or exploratory work; presence here does not authorize implementation. Completed work should normally move to `STATUS.md` or project history rather than remain an active TODO. Do not create parallel task records.

## Active Follow-Up

- [x] Have the Test Analyst design the FC-004 matched sustained selected/active-versus-unselected protocol.
- [x] Define authoritative active-state verification, readiness, exact timing, and sufficient post-threshold sampling.
- [x] Identify the minimum Test Engineer infrastructure requirement without implementing it in the protocol-design task.
- [x] Obtain Bart's acceptance of the protocol and the separately bounded infrastructure task.
- [ ] Implement the authorized FC-004 matched setup, selected-container observability, state markers, and invalidation detection.
- [ ] Perform and report the authorized infrastructure-only smoketest.
- [ ] Have Test Analyst review practical executability and marker validity.
- [ ] Obtain Bart's separate authorization for the substantive counterbalanced FC-004 runs.
- [ ] Execute the authorized runs, preserve raw evidence, classify them, and persist their canonical records.
- [ ] Route assessed FC-004 evidence to Researcher before updating broader project conclusions.

## Near Term

- [ ] Characterize lazy vanilla Food refresh sufficiently for production decisions.
- [ ] Add an environment/calibration guard for `DayLength = 4`, `FoodRotSpeed = 3`, and `FridgeFactor = 3` through a separately authorized implementation task.
- [ ] Establish canonical architecture documentation, including explicit state ownership and vanilla handoff.
- [ ] Evaluate legacy identity/tracking fields such as `FC_coolerID` after clone and context evidence is available.
- [ ] Create a production development deployment script.
- [ ] Create a separate harness deployment script.
- [ ] Establish a runtime log collection workflow.
- [ ] Document the calibration environment.
- [ ] Create a dedicated test scenario only if future testing justifies it.

## Validation and Calibration

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
