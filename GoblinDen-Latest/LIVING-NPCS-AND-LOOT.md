# Living NPCs and selective monster loot

This version includes the painted dungeon/HUD overhaul and the Bog Trail fix.
Open this folder's `project.godot` in Godot 4.7.2 and run the main scene. Existing saves remain compatible; new loot fields default cleanly when loading an older save.

## NPC movement

Residents and temporary travelers periodically choose a nearby clear destination, walk there with their existing directional animation, then idle for a few seconds. They stay within 88 world pixels of their home position and inside their current room. Body sweeps and scenery collision prevent walking through walls. NPCs do not block the player.

They stop when you approach and stay still during conversations. Talk prompts, depot access and traveler trades use their actual positions. NPCs in inactive rooms do not move. Existing NPC dialogue, services and traveler expiration rules remain available.

## Claiming monster loot

Defeating an enemy grants XP and kill/proficiency progress immediately. Items, named equipment and scrap stay in the corpse's loot record. No walk-over pickup is created, and materials no longer go straight into your backpack.

1. Approach the defeated enemy and press E at the Loot prompt.
2. Choose Take beside any item stack, or Take scrap for its currency.
3. Leave / Close takes nothing further. Esc or E also closes the window.
4. Take all that fits is an explicit optional action. It leaves any stacks that do not fit.

Loot inspection pauses the world. Full-backpack claims leave the rejected items intact. Named equipment unlocks when it is claimed, not merely when its owner dies. Empty bodies stop offering loot. Duplicate death notifications cannot award XP or create loot twice.

Unclaimed and partially claimed loot is saved, including its room and position. It lasts for 30 minutes of active gameplay; pause/inspection time does not consume that lifetime. Discovered bodies also appear as loot markers on the local map. Your own death-corpse recovery remains unchanged.

## Validation

Passed Godot 4.7.2 checks for periodic NPC walking, home radius, scenery avoidance, inactive-room behavior, approach/conversation stops, moving service prompts, depot access and traveler trading. Loot checks cover no automatic collection after a kill or by walking across a body, individual claims, optional take-all with a full bag, independent currency claims, remote-claim rejection, duplicate reward prevention, and full save/reload persistence. Actual rendered loot-window buttons were exercised and the resulting screens inspected. Existing NPC services, dungeon progression/boss rewards, RPG inventory/equipment, map persistence, movement/interaction and Bog Trail accessibility checks also passed.

All tests used separate local test-save profiles.
