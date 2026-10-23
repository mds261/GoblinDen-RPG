# Painted dungeon & clean HUD update

Open this folder's `project.godot` in Godot 4.7.2, then run the main scene.
Use this project instead of the previous Bog-Trail-Fixed project. The save identity is unchanged, so your existing progress loads normally.

## Dungeon art

- Five new painted atlases replace the cropped floor textures and enlarged chest icon.
- Distinct root crypt, drowned scriptorium, ruined sanctuary and gilded vault floor paintings, cut to the existing walkable chamber geometry.
- Shadowed rock wall tops, painted masonry faces, carved stone stairs, ward obelisks, reliquaries, torch sconces, broken pillars and low ground scatter.
- Dedicated chest-mimic boss sprites for dormant, idle, locomotion, bite, slam/coin storm and defeat; bobbing, leaping, damage reaction and attack telegraphs remain responsive to the combat state.
- Dungeon objects now use the shared nearby interaction prompt instead of always-visible floating labels.

## Interface

- Compact vitals in the upper left; location and one objective at the top; smaller map in the upper right.
- Removed the permanent bottom control sentence and large footer panel.
- Empty action slots are hidden. Assigned actions remain clickable with hover descriptions and cooldowns. Core combat readiness stays visible.
- Esc or Menu opens a pause menu. Controls & training contains the reference guide.
- Backpack pages: Inventory, Character, Journal, Crafting, Actions. Services automatically open Inventory, with the existing merchant/trainer options retained.
- Nearby world markers replace persistent interaction labels. The journal/chat stays hidden until Enter is pressed.

## Checks completed

Godot 4.7.2 imported and rendered the project without script errors. Three-floor progression, ward locks, physical stairs traversal, boss phases/rewards, RPG inventory/equipment logic, map visibility and persistence, movement/interaction focus, and Bog Trail body clearance checks passed. Rendered previews were inspected for floor art, stairs, seals, boss states, pause/help menu, inventory and bindings. Twelve assigned actions fit the HUD without overlapping its other controls.

Tests ran with a separate APPDATA profile, preserving your normal game save.
