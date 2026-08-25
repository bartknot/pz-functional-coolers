Functional Coolers Test Harness v0.4.2-dev

FC-004 matched selected-versus-unselected infrastructure.

Use a fresh dedicated save. Wait for WAITING_FOR_FREEZER_SELECTION, then open the nearby powered refrigerator/freezer and keep its freezer selected until MATCHED_SETUP_CREATED. Do not move or manipulate the two preparation steaks. FREEZER_SELECTED, FREEZER_SELECTION_LOST, and per-game-minute FREEZER_SAMPLE markers record the setup dependency and individual freezing state. Passive waiting is not a reliable freezer-preparation method in the tested Build 42.20.3 runtime.

Fixed test position:
  x=10693 y=9986 z=0

On a fresh dedicated save the harness:
  - configures the absolute Lua spawn at x=10693 y=9986 z=0 before the player is created
  - finds a nearby powered vanilla fridge/freezer
  - clears fridge and freezer once
  - freezes 2 Base.Steak entirely through vanilla behavior
  - creates player-inventory Coolers FC004-A and FC004-B
  - puts 1 fresh and 1 vanilla-frozen Base.Steak in each Cooler
  - uses zero cold packs in both matched groups
  - adds Base.WristWatch_Right_DigitalRed to player inventory
  - logs the actual selected player-inventory container binding
  - logs exact IDs, worldHours, hand assignment, UI state, contents and Food state every game minute during an active mode
  - rejects saves carrying an older harness setup version

Equip FC004-A primary and FC004-B secondary. Pin and keep the player inventory visible.

Right-click FC004-A, FC004-B, or one of their contents to use the FC-004 harness controls.
The context menu can start the infrastructure smoketest, arm an experiment (separate Bart authorization required), or end/cancel an active run.
This replaces the function-key controls because Ctrl+Shift+F9 also opens a Project Zomboid debug editor in the target runtime.

The smoketest must detect selection A, selection B, inventory closed, inventory collapsed, an equip-assignment change, and ten stable restored game minutes. Smoketest output is not experiment evidence.

Use a dedicated sandbox with loot disabled.
