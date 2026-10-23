# All-class walking and attack animations

This project includes the prior Blade walk/attack update plus new Archer, Knight and Mage sprite animations, created using built-in image generation with the existing class art as character references.

## Play

Extract the entire project ZIP into a new folder. Open project.godot in Godot 4.7 and press F5.
In the Den: 1 = Blade, 2 = Archer, 3 = Knight, 4 = Mage.
WASD moves; Space/left click attacks; Q/right click uses the class special.

For an animated preview, open scenes/animation_gallery.tscn and press F6. It shows the three new classes walking and attacking in both directions. Its attack clips run slightly slower for inspection than gameplay.

## Animation behavior

- Archer: eight walking poses and eight bow draw/release/recovery poses.
- Knight: eight walking poses and eight mace windup/swing/recovery poses.
- Mage: eight walking poses and eight staff casting/recovery poses.
- Class-specific walk speeds: Archer 10 fps, Knight 8 fps, Mage 9 fps, scaled with movement speed.
- Movement loops; stopping returns to the first walking pose as idle. Attacks play once, override walking, and return to locomotion.
- Gameplay attacks use a visual duration of up to 0.4 seconds, capped to the attack cooldown. Specials trigger the casting/attack clip as well.
- Player class evolutions inherit the base class's animation. Archer, Knight and Mage companions use the same animation system.
- Existing projectiles, damage timing, cooldowns, special effects and collision shapes remain controlled by the original gameplay code.
- Horizontal flipping supplies left-facing poses. Vertical movement continues to use the side view.
- These are AI-generated animation sheets, with some pose-to-pose variation in proportions and equipment. They are not hand-keyed skeletal animations.

## Assets

assets/archer_animation_sheet.png
assets/knight_animation_sheet.png
assets/mage_animation_sheet.png

Each final PNG is 1254 x 1254 with transparent alpha, copied directly from image generation. Each contains a 4-column/4-row arrangement: the first eight poses are walk, the last eight are attack. Generated spacing is approximate, so use the precise per-pose rectangles and foot anchors in assets/class_animation_frames.json (also embedded in scripts/class_animation_frames.gd), rather than slicing into equal cells. The metadata excludes imperceptible alpha noise outside each sprite. No recoloring, background removal or raster resampling was applied.

The final prompt set is in docs/CLASS_ANIMATION_PROMPTS.json: concatenate shared_initial_prompt with each class's initial_character_prompt, then apply its final_layout_edit using the initial generated image as reference. Built-in image_gen was used with transparent_background=true for every generation and edit.

## Validation

Godot 4.7.2 import and rendering succeeded.
class_animation_test.gd: PASS, covering walk/idle/attack/death transitions, valid non-overlapping source regions, player primary/special triggers and real companion attacks for each new class.
blade_animation_test.gd: PASS.
combat_test.gd: PASS (0 failures; reported a two-instance ObjectDB shutdown leak warning).
class_roster_test.gd: PASS (0 failures).
evolved_specials_test.gd: PASS (0 failures).
The animated gallery was rendered and visually inspected in both directions.

Known original project issue: thornwood_expanse_test.gd has three existing camera/spawn failures, reproduced with the original player/companion scripts during the prior Blade update. See BLADE_ANIMATION_UPDATE.md. This animation update does not change the exterior camera.

The project source ZIP excludes .godot caches; Godot imports textures when opened. Test runs used an isolated user-data folder, not your existing saved game.
