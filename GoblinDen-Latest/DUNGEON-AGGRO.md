# Local dungeon aggro

Dungeon guards now wait for a local encounter instead of pursuing the player from anywhere on the floor. This change applies to dungeon guards; existing raid combat and the vault boss's arena-entry trigger are retained.

- A guard notices the player within 350 world pixels, with a clear line of sight through the physical dungeon geometry.
- Taking damage alerts the struck guard. There is no floor-wide alarm or automatic chain alert.
- An engaged guard can follow briefly around a corner, but loses the player after three seconds without sight.
- Guards break pursuit if pulled more than 480 pixels from their home, or if the player retreats more than 620 pixels from that home. Pending attacks are cancelled as soon as the guard disengages.
- Disengaged guards follow navigation back home, then wait for another local encounter. Their health is not restored by this reset.
- Companions target nearby engaged dungeon guards, rather than running ahead to pull idle guards from other chambers. They leave the dormant vault boss alone.

Validation: entering all three floors leaves distant guards idle; approaching one guard engages it alone; real dungeon walls block detection; direct damage alerts its target; loss of sight and long retreats cancel attacks; a guard physically navigates home and can be re-engaged; companions respect local encounters. Existing dungeon progression/boss, combat and selective-loot/persistence checks passed in separate test-save profiles.

Includes the painted dungeon, clean HUD and controls menu, wandering NPCs, selective corpse loot, and Bog Trail fix. Open this folder's project.godot in Godot 4.7.2 and run the main scene. Existing saves remain compatible.
