# Unified Blade and enemy animations

Open `project.godot` with Godot 4.7.2, then press F5 to play. To inspect the animation gallery, open `scenes/enemy_gallery.tscn` and press F6. Keys 1–4 or the arrow keys switch pages.

## What changed

- Blade Goblin now uses one coherent 16-pose atlas for front, rear, right, mirrored left, and attacks. Walking sideways no longer switches to the older character design. Companion Blades use the same rendering path.
- Ten enemy atlases provide distinct red knights, blue captains, rangers, mages, priests, rogues, ogres, wolf riders, gray wolves, and Rootvein spiders. Spiderlings use the spider atlas at a smaller scale, with a green tint and faster gait.
- Each enemy atlas contains 20 poses: four down-walk, four up-walk, four right-walk, four attack, and four death poses. Left walking mirrors right. There are 216 new art poses including Blade.
- Enemies retain their facing while idle, breathe subtly, flash when hurt, react while stunned, and finish their death sequence. Direction changes use a small diagonal dead band to reduce jitter.
- Attack animation contact is triggered by the actual combat event. Anticipation follows the existing windup timer, including the ogre's charged windup. Captain charges, sweeps and rallies; priest healing; spider brood and gas; and rider pack calls now trigger animation playback.
- Actor names and health bars sit above the tallest living pose, including raised weapons.

The attached catalogs were used as visual references. Their printed labels and inconsistent pose ordering were not imported as game frames. New sheets preserve the broad armor, creature, weapon and palette ideas while fitting the existing painted game.

## Existing updates retained

This project includes the previous connected den and terrain collision update: Main Hall, Treasury, Armory and Strategy Room; assigned stations; connected routes; and revised tree, statue, water and cliff boundaries. It also retains Cave Fang's brown beast appearance, skeletal necromancer summons, all nine evolved class appearances, and the earlier animated special effects.

Combat damage, cooldowns, progression and collision sizes remain governed by the existing gameplay code. Attack art follows the existing side-facing convention; it does not supply a separate attack sequence for every direction. Idle, hurt and stun presentation reuse poses and procedural motion. Blade retains its existing death presentation rather than receiving the enemy four-pose death sequence. Small variations in generated anatomy or equipment can still occur between poses.

## Source and asset organization

- `scripts/enemy_animation.gd`: shared enemy animation state and timing.
- `scripts/atlas_clip.gd`: native UV polygon drawing that isolates each pose.
- `scripts/enemy_animation_frames.gd` and `assets/enemies/frames.json`: exact regions, pivots and clipping contours.
- `scripts/directional_actor.gd`, `scripts/directional_frames.gd` and `assets/directional/frames.json`: unified Blade rendering and metadata.
- `scripts/knight.gd`, `scripts/large_enemy.gd`, `scripts/monster_minion.gd` and `scripts/iron_captain.gd`: gameplay animation hooks.
- `assets/enemies/*.png` and `assets/directional/blade.png`: original generated PNGs, preserved byte-for-byte with their transparency. Frames use individually measured bounds and contours rather than equal cell splitting.
- `docs/ENEMY_AND_BLADE_ART_PROMPTS.json`: complete image-generation prompts and reference provenance.
- `tests/enemy_animation_test.gd` and `tests/enemy_render_smoke.gd`: new automated and full-game render checks.

## Validation

Thirteen targeted automated suites passed: enemy animation, directional animation, Blade animation, class animation, combat, class roster, large enemies, specials/packs, summon animation, evolved specials, den network/collision, world expansion, and directional render smoke. The new enemy suite passed 36,531 checks, including UV contour triangulation, bounds, direction selection and actual gameplay animation hooks.

OpenGL full-game rendering passed for human roles, the captain, spider brood, the ogre, and the rider with wolves. The gallery rendered 192 captured frames across its four pages; screenshots and animated previews were inspected. Some older combat tests emit an existing ObjectDB shutdown warning. These targeted passes do not mean every legacy test passes: the earlier connected-den notes document pre-existing expansion-test assertions and exterior camera/spawn expectations that remain outside this update.

The ZIP is the complete editable Godot source project. The GitHub upload also rebuilds the browser export in `docs/` from this source; the earlier downloadable source ZIP did not include that export. The separate asset ZIP is supplementary; use the complete project for the integrated behavior and all earlier changes.
