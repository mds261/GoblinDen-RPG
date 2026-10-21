# Thornwood Expanse — Layered Continuous 2D Update

The production direction is a continuous painted 2D exterior. The world preserves GoblinDen's established visual identity and complete combat stack while fixing the flat-backdrop problem with foreground occlusion, depth sorting, collision, traversal routes, and a scrolling camera.

Characters can pass behind selected trees, the watch shrine, the hunter camp, and foreground cliff masses. Three woodland patrols are spread across the map so the existing attacks, specials, projectiles, companions, status effects, and drops remain visible and playable outdoors.

## Progression

- Defeat the Thornwood Wolf Rider in Thornwood Hollow.
- The east trail marker changes from a blocked route to `E EXPLORE`.
- Interact at the trail to enter Thornwood Expanse.
- Return through the marked cave entrance in the northwest of the exterior.

## Continuous exterior behavior

- The expanse uses a 2304x1440 world instead of the 1152x720 cave-room bounds.
- The goblin, party members, combat ranges, and movement speed retain their existing scale.
- The player Camera2D follows across the world and clamps to the exterior perimeter.
- There are no internal room gates. Paths, trees, cliffs, water, and elevation visually organize exploration.
- Painted scenery has matching physics: old-growth trunks, thorn groves, shrine masonry, camp props, stream banks, waterfall drops, forest walls, and cliff edges block the player. The marked ford and wooden bridge remain open crossings.
- Returning to Thornwood Hollow restores the standard camera and collision limits.

## Exploration landmarks

The exterior tracks five proximity discoveries:

1. Fallen-Root Arch
2. Old Watch Shrine
3. Abandoned Hunter Camp
4. Whispering Stream Ford
5. Thornwood High Overlook

Discovery count appears in the objective and is preserved by the existing ConfigFile save system.

## World interactions

- Forage root-herbs to refill a potion.
- Touch the old shrine to restore health.
- Search the abandoned camp for scrap.
- Search the ford for river-polished scrap.
- Study the overlook trail totem for exploration XP.

Each interaction is one-time, displays a nearby `E` prompt, and persists through the save system.

## Main implementation points

- `assets/thornwood_expanse.png`: expanded painted exterior.
- `scripts/cave.gd`: world-sized backdrop, adaptive perimeter, navigation grid, and exterior ambience.
- `scripts/main.gd`: wolf-gated progression, camera switching, return gate, landmarks, HUD objective, and hints.
- `scripts/save_data.gd`: landmark persistence.
- `tests/expansion_test.gd`: progression, bounds, discovery, and return-path checks.

Godot will generate the image import metadata the first time the project is opened.
