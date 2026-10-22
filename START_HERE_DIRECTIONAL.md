# Four-direction walking and nine evolution appearances

This package includes the previous walking/attack work plus new up/down walk cycles for Blade, Archer, Knight and Mage, and distinct sprites for all nine evolutions.

## Open and play

Extract the complete project ZIP into a new folder. Open project.godot in Godot 4.7 and press F5.
WASD moves. Space/left click attacks. Q/right click uses the special.
Switch base class in the Den with 1 (Blade), 2 (Archer), 3 (Knight), 4 (Mage).
C cycles unlocked evolutions; the existing level/training requirements still apply.

## Preview without unlocking classes

Open scenes/directional_gallery.tscn and press F6.
Use keys 1-5 or left/right arrows to change pages:
1. All four base classes.
2. Assassin, Berserker, Hunter, Beastmaster.
3. Warlord and Guardian.
4. Shaman, Warlock, Necromancer.
5. Overview of all nine evolutions.

The family pages show front walk, rear walk, right walk, left walk and attack. The preview slows attack clips to make their poses easier to inspect.

## What changed

- Walking up selects a rear-facing walk, and down selects a front-facing walk.
- Stopping retains the last movement view rather than snapping sideways.
- A 15% axis-selection dead band keeps diagonal movement from flickering between side and vertical views. Left-facing poses mirror right-facing art.
- All four core companion classes use the new directional walking too.
- Every evolution selects its own artwork for front/rear/side walks and attacks. Switching back to a base class restores its base artwork.
- Existing movement, hit timing, damage, specials, projectiles, progression, save/load and collision behavior remain in the original gameplay scripts.
- Base-class side walking and attack clips from the previous update are retained.

Evolution designs:
Assassin: charcoal hood, face wrap, emerald sash, venom daggers.
Berserker: red mohawk, warpaint, fur shoulders, twin cleavers.
Hunter: green leaf cloak, large quiver, decorated hunting bow.
Beastmaster: wolf headdress, tawny pelt, fang necklace, compact bow.
Warlord: brass armor, red helm crest, crimson cape, decorated shield and mace.
Guardian: steel-blue armor, pale tabard, tower shield and hammer.
Shaman: antler headdress, moss-green robes, bone charms and green spirit staff.
Warlock: burgundy hood, horns, magenta runes and soulfire staff.
Necromancer: skull hood, bone breastplate, spine harness and teal skull staff.

## Assets and playback

New art is in assets/directional/: thirteen original transparent PNG atlases at 1254 x 1254.
All sprites were created with built-in image_gen, using the existing class PNGs as identity/style references. No fallback API or external model was used. The final prompts, including the Warlord spacing repair, are in docs/DIRECTIONAL_ART_PROMPTS.json.

Each new directional walk is a four-pose cycle. Each evolution also has four side-walk poses (mirrored for left) and four attack poses. Base sheets use their first two rows only: front and rear walk; their unused generated side/attack rows are not used in the game, because the previous base side clips are retained. Thus 176 new poses are used: 32 base vertical poses and 144 evolution poses.

The generated grid spacing is approximate. Use the exact source rectangles, foot anchors and scale in assets/directional/frames.json or scripts/directional_frames.gd. Do not assume equal cell boundaries. The source PNGs retain their generated alpha; metadata ignores faint alpha speckles outside each sprite. No image recoloring or raster resampling was applied.

These are generated frame animations, so some clothing/equipment and body proportions vary between poses. In particular the supplied Blade side art and new Blade front/rear art have different proportions. Front/rear ATTACK clips are not part of this update: attacks use the existing side-facing base clips or each evolution's new side attack. Up/down walking and idle retain front/rear views.

## Validation

Godot 4.7.2:
- directional_animation_test.gd: PASS (0 failures): view selection, retained idle direction, diagonal dead band, frame bounds/non-overlap, all nine evolution selections, player normal/special attack triggers, switching back to base classes, and companion upward movement.
- directional_render_smoke.gd: PASS (0 failures), both headless and OpenGL: the full game scene exercised all 13 forms in four movement directions and rendered a real in-game screenshot.
- blade_animation_test.gd: PASS.
- class_animation_test.gd: PASS.
- combat_test.gd: PASS, 0 failures; reports the existing two-instance ObjectDB shutdown leak warning.
- class_roster_test.gd: PASS, 0 failures.
- evolved_specials_test.gd: PASS, 0 failures.
- Five gallery pages rendered and visually inspected for all directions/evolutions.

Tests used isolated Godot user-data folders and did not use your game save. Import caches are excluded from the ZIP and regenerate when Godot opens it.

Known earlier project issue: three camera/spawn assertions in thornwood_expanse_test.gd fail in the original attached project too, as documented in BLADE_ANIMATION_UPDATE.md. This animation update does not change that camera code.
