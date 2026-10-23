# Connected opening

The starting den and early caves now form one 4608 x 2816 physical map. Camera movement, floor rendering, collision and navigation share this world. The original room IDs remain only for encounter placement and legacy save migration; internal scene changes, E-door prompts and arena-clear travel gates are removed.

## Routes

- Hearth Hall is the safe home and new-game start, with fire, shaman, keeper and supply chest.
- Treasure Alcove is north of home. Its upper tunnel loops east to Rootvein Nest.
- Armory is south of home; its eastern passage reaches Tribe Quarters, which reconnects north to Watch Tunnels.
- Watch Tunnels lead east to the human Breach incursion camp, then Daylight Grotto.
- Rootvein Nest is an optional spider encounter north of the camp, connected to the upper den loop.
- Daylight Grotto has the single surface exit into Thornwood Hollow. The old cave-mouth ogre is retired. The hollow's eastern forest route remains open even if its wolf rider survives.

## Encounters and services

Scouts, defenders, the commander, the optional spider and its spawned minions use local detection, sight checks and retreat leashes. Companions respect engaged targets. Priest support and commander buffs are local. Commander reinforcements spawn near him in the new map. Defeating the commander records incursion completion even if summoned guards survive.

All eight den facilities retain their functions at their new positions. The keeper wanders within the den. Existing inventory, equipment, level, currency, recruits, dungeon progress and volume preferences retain their save format. Old opening corpse records migrate once into world coordinates; new saves record layout version 2. Unclaimed loot remains selectable. Killed opening placements stay cleared across reloads, while a newly launched War Room raid refreshes the human encounters.

## Validation

Passed connected_opening_test, rpg_systems_test, audio_test, selective_loot_test, dungeon_test, dungeon_awareness_test, npc_wander_test and npc_test. The opening test verifies connected paths to every chamber, navigation against actual physics, body movement along the main route, safe-region checks, distant enemy idling, surface travel and return, reachable facilities and functioning rest, commander reinforcement positions, legacy corpse migration, selective loot and cleared-defender persistence. Windows OpenGL previews were rendered and visually inspected for the hearth, linking tunnel, armory, camp, optional nest, surface exit and whole layout.

## Painted assets and prompt set

Created using the imagegen skill, with project copies retained in assets/descent:

- starting_cave_materials.png: Four equal material swatches in a 2x2 atlas: compact warm cave earth, dark craggy cave rock, warmer straw-flecked goblin den earth, and moss/root cave floor with tiny teal minerals. Hand-painted overhead fantasy materials, evenly lit, no focal objects, labels, rooms or borders.
- starting_cave_props.png: Four isolated transparent props with generous quadrant padding: rustic blank arrow signpost with green pennant; natural stone cave-mouth arch with pale daylight only inside the opening; mossy root-and-boulder cluster with teal mushrooms; abandoned human scout lean-to, bedroll, shield, spear and supplies. Three-quarter overhead hand-painted fantasy style, warm earth palette, readable silhouettes, no people, labels, floor planes or background.

Runtime atlas regions trim transparent margins; rock-edge dressing stays off the main travel line. Existing painted facility, chest and torch assets are reused.
