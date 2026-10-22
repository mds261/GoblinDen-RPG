# Connected den and outdoor collision update

This build includes the previous Cave Fang wolf, skeleton summons, four-direction character animations, all nine evolutions and animated special attacks.

## Open and play

Extract GoblinDen-Connected-Den-Collision-Fixes.zip into a new folder, import project.godot in Godot 4.7, and press F5. Use WASD to move and E at a labelled passage or station. This is the Godot source project; browser exports have not been rebuilt.

## Den rooms and station assignments

| Room | Existing stations | Connections |
| --- | --- | --- |
| Main Hall (starting room) | Rest fire, Shaman Hut | West to Treasure Room, north to Armory, south to Strategy Room, east to the original raid |
| Treasure Room | Treasure/loot equipment station | Main Hall and Armory |
| Armory / Weapon Room | Forge, Archery & Trap Workshop | Main Hall, Treasure Room and Strategy Room |
| Strategy Room | Training Pit, Recruitment Hut, War Table | Main Hall and Armory |

The extra passages form loops, so the three rooms are more than dead-end menus. Travel uses the existing E interaction convention. Every passage has a return route and a clear arrival point. Every station exists once and responds only in its assigned room. The existing prices, upgrades, loot, recruitment and raid mechanics are retained. Class switching and periodic autosaving work throughout the safe den.

Three new painted room backgrounds were generated using built-in image_gen. The original starting hall artwork is retained. Final prompts are in docs/DEN_ROOM_ART_PROMPTS.json. Generated source PNGs are preserved byte-for-byte.

The three new room IDs are appended after the original seven world rooms, preserving the old combat IDs and progression save format. Reaching the end of the outdoor trail does not accidentally enter a den room. Existing saves still start in the main hall with their progression restored.

## Collision changes

- Replaced offset outdoor polygons with boundaries traced in the actual background image's coordinates and scaled to the game world.
- Expanded the statue/shrine blocker around the plinth and front steps, so approach stops at the base rather than on the monument.
- Traced the old-growth tree/root mass and nearby wooded obstacles.
- Tightened the stream banks and downstream water boundaries. The diagonal wooden bridge deck remains crossable.
- Followed the visible cliff-top contour around the overlook, ravine and waterfall drop.
- Moved the shrine interaction to a dry approach beside the plinth. All five outdoor interactions remain reachable.
- Added physical footprints to the den stations. Their colliders activate only in the current room, preventing invisible obstacles from inactive rooms.
- Added room-floor bounds around the new rooms' painted walls and perimeter furniture.
- Navigation derives from the same obstacle polygons. It adds body clearance, using a smaller safe clearance around the narrow bridge. The new test sweeps a 15-pixel body along every path segment to all five outdoor interactions.

The collision overlay screenshot shows the solid outdoor regions in red for review. The overlay is off during normal play. Enable Cave.debug_collision_overlay only for development.

## Validation

Godot 4.7.2, with an isolated APPDATA directory so the user's save was not used:

- den_network_collision_test.gd: PASS, zero failures. Checks all eight stations, every passage in both directions, clear arrivals, safe-room interactions, forge/recruitment/raid functions, class switching, save/load, hidden colliders, raid access, outdoor endpoint behavior, tree/statue/water/cliff swept collisions, the bridge, and physically traversable companion paths to every outdoor interaction.
- blade_animation_test.gd: PASS.
- class_animation_test.gd: PASS.
- directional_animation_test.gd: PASS.
- summon_animation_test.gd: PASS.
- combat_test.gd: PASS.
- class_roster_test.gd: PASS.
- evolved_specials_test.gd: PASS.
- specials_and_packs_test.gd: PASS.
- world_expansion_test.gd: PASS (updated for ten rooms).
- large_enemy_test.gd: PASS.
- den_visual_smoke.gd: PASS with OpenGL, successful exit; all four den rooms and the outdoor collision overlay rendered and visually inspected.

The older expansion_test.gd is not fully passing: it reports eight failures involving fresh-run assumptions, loot/recruitment state, camera-shake assumptions, damage-effect counting and an obsolete return-position assertion. The same eight failures were reproduced on the previous build. Both comparisons used a guard for stale drop references so the old test could complete. Station interactions in the updated test now enter their assigned rooms. Those pre-existing failures are documented rather than counted as passes. The earlier project's known camera/spawn assertions in thornwood_expanse_test.gd remain outside this collision and den-layout update.

Editor imports completed with the same isolated editor-settings safe-save diagnostic as before; runtime suites and OpenGL rendering completed successfully. The project ZIP excludes the .godot import cache, which Godot regenerates.

## Source changes

- scripts/expanse_geometry.gd: traced terrain boundaries in source-image coordinates.
- scripts/den_layout.gd: station assignments, floor bounds and connected-room graph.
- scripts/cave.gd: room artwork, physical boundaries, shared navigation and optional collision overlay.
- scripts/main.gd: room travel, station dispatch, safe-room behavior, objectives, labels and shrine approach.
- scripts/painted_prop.gd: station collision footprints and activation.
- scripts/tutorial.gd: updated first-visit guidance.
- tests/den_network_collision_test.gd and tests/den_visual_smoke.gd: new coverage.
- tests/world_expansion_test.gd and tests/expansion_test.gd: room count and station-location updates; stale-drop guard in the legacy integration test.
- assets/den_treasury.png, den_armory.png, den_strategy.png: new painted room art.

Earlier animation and summon assets/controllers are retained unchanged. See START_HERE_SUMMONS_SPECIALS.md for that update and its preview gallery.
