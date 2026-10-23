# Exploration mini-map

The mini-map is displayed in the upper-right corner in every current area, including all three dungeon floors. It starts dark and gradually uncovers nearby ground as you move. Revealed ground remains visible when you leave and return, die, or save/reload. The previous fully revealed dungeon overview has been replaced.

Discovery uses a 192-pixel sight radius and wall raycasts. Walls can reveal their visible surface, but they block discovery of cells behind them. Each area and floor has independent explored cells. Routes, NPCs, loot landmarks and ward seals appear only after discovering them; unexplored objectives and stairs are not shown. Boss/enemy locations are not exposed by the mini-map. Corpses are marked only on ground already explored.

Press **M**, or click/tap the Mini-map button, to show or hide it. Exploration continues while it is collapsed. Typing in chat or interacting with the inventory/dialogue does not toggle the map accidentally. Its visibility preference is saved. Player position/facing is cyan, people green, routes cream, loot gold, wards purple/green, and recoverable corpses red.

Map discoveries join the existing save system, with an additional save after approximately five seconds of new exploration. Earlier saves remain compatible; old full-map access does not automatically grant explored terrain in this update.

Implementation: `scripts/exploration_map.gd`; persistence is in the existing RPG save section. Tested nearby reveal, hidden distant chambers and stairs, wall occlusion, independent floors, returning to explored areas, exploration outside the dungeon and with the panel collapsed, and full scene/save reload. Coverage and RPG integration checks passed, and the on-screen map was rendered and inspected.

All previous features remain included. Re-export the Web preset to update the browser build.
