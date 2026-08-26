Functional Coolers Test Harness v0.5.1-dev

FC-006 managed-to-vanilla Food handoff infrastructure.

Use a fresh dedicated save on Build 42.20.3. Enable this harness and disable the production Functional Coolers mod. Required sandbox values: DayLength=4, FoodRotSpeed=3, FridgeFactor=3.

Fixed test position:
  x=10693 y=9986 z=0

On a fresh dedicated save the harness:
  - configures the absolute Lua spawn at x=10693 y=9986 z=0 before the player is created
  - creates empty player-inventory Cooler FC006-GUARD
  - creates player-inventory Cooler FC006-TEST
  - puts labeled Base.Steak groups V, A and U in FC006-TEST
  - aligns and projects their common public baseline
  - adds Base.WristWatch_Right_DigitalRed to player inventory
  - logs the actual selected player-inventory container binding
  - logs exact IDs, worldHours, hand assignment, UI state, contents, lastAged, age, heat, freezing time and phase flags
  - rejects saves carrying an older harness setup version

Equip FC006-GUARD primary and FC006-TEST secondary. Pin and keep the player inventory visible. Select FC006-GUARD and leave it selected.

Right-click an FC-006 Cooler or V/A/U item to use the FC-006 harness controls. Start only the infrastructure smoketest under the current authorization. Do not arm the substantive experiment without separate Bart authorization.

For the smoketest, wait for READY, start it, and perform no further UI, container, equip, or item interaction. It first calls updateAge on disposable group U after exactly ten game minutes. The thaw gate requires a freezingTime decrease greater than 0.05, correct phase flags, valid setter calls, valid stale-version and public-state guard behavior, and timing within 0.001 game hour.

After that gate the smoke emits one expected mismatch INVALIDATED marker without a handoff commit, resets V/A/U, and runs the real shared one-hour handoff state-machine followed by UPDATE_1, UPDATE_2 and UPDATE_3 at ten-game-minute intervals. PASS requires exact marker order and a final baseline reset. The full smoke takes about 16 minutes 40 seconds of real time at DayLength=4 on normal speed. Do not use fast-forward.

All setup and smoketest output has evidenceEligible=false and is not experiment evidence.

Use a dedicated sandbox with loot disabled.
