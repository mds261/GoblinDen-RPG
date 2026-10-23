# Cave Fang, skeleton summons and animated specials

Built on GoblinDen-Thornwood-Four-Directions-All-Evolutions-Project, retaining its four core classes and nine evolution appearances.

## Open and review

Extract GoblinDen-Summons-and-Specials-Project.zip into a NEW folder. Import project.godot in Godot 4.7 and press F5.
WASD moves, Space/left click attacks, Q/right click uses the special. Existing progression and evolution unlock requirements are retained.

For a preview without unlocking classes, open scenes/summon_gallery.tscn and press F6. Press 1 for summons, 2/3 for all thirteen special effects. Arrow keys change pages. The previous directional_gallery.tscn is also retained.

## Summons

- The Archer's Beastmaster evolution now uses a real Cave Fang quadruped: muscular rusty-brown hide, bristled mane, long tail, large saber fangs, and a snarling head inspired by your reference.
- Necromancer summons now use exposed skeletal warriors with bare skulls/ribcages, rusty swords, bucklers and teal soulfire. They no longer fall back to goblin sprites.
- Both use four-pose front, rear and side movement cycles. Left mirrors right. Stopping retains the current direction with subtle idle breathing.
- Each has a four-pose side attack: wolf anticipation/pounce/bite/recovery, skeleton anticipation/raise/slash/recovery. Attacks mirror for left, matching the previous characters' side-attack convention.
- Each has a four-pose death/collapse clip which holds the final corpse pose. Hurt flashes, animated arrival, and a one-shot buff pulse are handled by code. Skeletons rise and fade in during arrival.
- Fallen skeletons no longer count toward the existing two-living-summon cap. Their collapse finishes before the corpse is removed on replacement.

## Special attacks

All four base specials and all nine evolved specials have layered animated effects. Four new painted effect families (crescent slash, venom arrows, frost shield/shards, spectral soulfire/skulls) cross-fade through four phases. Each form keeps its distinct procedural accents: assassin trails, berserker sweeps, hunter sight, beastmaster claws, warlord rays, guardian shield, shaman wisps, warlock impact and necromancer rising skulls.

Ground glyphs render beneath actors; airborne accents render above them. Fast impact bloom, travelling ribbons, sparks, rising souls and a fading afterglow provide motion. Nodes clean up at the end of the effect. Damage, hit timing, cooldowns, progression and collision rules retain their existing behavior.

## Assets and source

assets/summons/wolf.png and skeleton.png contain walking/death artwork. Their original fourth rows are unused because the attack frames needed wider spacing. assets/summons/attacks.png supplies the eight replacement attack poses. assets/summons/specials.png supplies sixteen effect poses.

There are forty used summon poses in total, plus sixteen painted effect poses. Exact summon regions, foot anchors and attack scale adjustments are in assets/summons/frames.json and scripts/summon_frames.gd. Do not split the source sheets into equal cells; generated spacing varies. Special effects use a 4x4 grid, with soft outer wisps clipped at cell boundaries. Original generated PNGs and transparency are preserved byte-for-byte.

Artwork was created with built-in image_gen; full final prompts, including the attack-spacing repair, are in docs/SUMMONS_SPECIALS_ART_PROMPTS.json. No fallback image API was used. These are generated frame animations, so minor anatomy/equipment variation between poses remains.

Changed existing scripts: scripts/goblin_ally.gd, scripts/main.gd, scripts/special_effect.gd.
New scripts: summon_animation.gd, summon_frames.gd, special_accent.gd, summon_gallery.gd.
New scene: scenes/summon_gallery.tscn.
New tests: tests/summon_animation_test.gd and tests/summon_render_smoke.gd.

This download is the updated Godot source project. A browser export has not been rebuilt; stale browser binaries are omitted from this package. The earlier export preset is retained for exporting from Godot.

## Validation

Godot 4.7.2:
- summon_animation_test.gd: PASS, zero failures. Tests frame bounds/non-overlap, four-direction choice, retained idle direction, attack sequencing/recovery, buff playback, collapse, Beastmaster wolf, Necromancer skeletons, replacement and living cap, all thirteen effect layers and cleanup.
- summon_render_smoke.gd: PASS in OpenGL, zero failures. Exercises both summons in the full game, renders movement/attack poses and specials, and captures gameplay screenshots.
- blade_animation_test.gd: PASS.
- class_animation_test.gd: PASS.
- directional_animation_test.gd: PASS.
- directional_render_smoke.gd: PASS, zero failures.
- combat_test.gd: PASS, zero failures.
- class_roster_test.gd: PASS, zero failures.
- evolved_specials_test.gd: PASS, zero failures.
- specials_and_packs_test.gd: PASS, zero failures.
- OpenGL gallery: captured all three pages and 96 animation frames, visually inspected, successful exit with no script errors.

Validation used an isolated APPDATA directory and did not use your game save. Editor import completed with an isolated editor-settings safe-save warning; runtime checks and renders completed successfully. The earlier project's documented Thornwood camera/spawn test failures remain outside this artwork update and were not changed.

The two GIFs are assembled from actual Godot-rendered frames. The full project ZIP excludes editor import caches, which regenerate when opened. The asset pack is a supplement; use the complete project ZIP for an already integrated game.
