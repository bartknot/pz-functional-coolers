Functional Coolers Test Harness v0.3.7-dev

Single-player calibration setup for Functional Coolers.

Fixed test position:
  x=10693 y=9986 z=0

On a new save the harness:
  - configures the absolute Lua spawn at x=10693 y=9986 z=0 before the player is created
  - finds a nearby powered vanilla fridge/freezer
  - clears fridge and freezer once
  - adds 8 Base.Coldpack and 7 Base.Steak to the freezer
  - spawns exact Base.Cooler items named P0, P1, P2, P4 and P1G on the floor
  - adds Base.WristWatch_Right_DigitalRed to player inventory
  - adds Base.Bag_Schoolbag to player inventory
  - watch and schoolbag are equipped manually by the tester
  - adds an empty Base.Bag_Satchel named NEUTRAL
  - waits for vanilla to freeze the steaks and for Functional Coolers to cool the packs
  - creates 7 fresh Base.Steak in player inventory when the freezer cohort is ready

The harness does not distribute steaks or coldpacks between test groups.
Use a dedicated sandbox with loot disabled.
