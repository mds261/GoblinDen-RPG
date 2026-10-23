# Wider aggro and RPG audio

The dungeon notice radius is now 350 pixels instead of 280: 25 percent farther. Physical walls still block detection, distant guards remain idle, and retreat/leash behavior is retained. Companions still avoid pulling idle guards.

## Soundtrack

Three original instrumental loops are included as local stereo WAV files:

- Haven: a gentler harp, airy flute and string-pad theme for the den and Bramble Market, about 76 seconds.
- Woodland: a traveling theme with harp arpeggios, woodwind melody and restrained hand drum for the outdoor areas, 80 seconds.
- Sealed Descent: darker low strings, sparse plucks, bells and a subtle pulse for caves and dungeon floors, 80 seconds.

Themes crossfade when the area changes, loop continuously, and lower gently while paused. Audio timing is independent of gameplay slowdown.

## Effects

Sixteen new local effects cover melee swings and impacts, hurt reactions, bows, spells, dodge, interactions, loot, coins, potions, level ups, defeated enemies, stairs, boss cues, and grass/stone footsteps. Footsteps follow distance actually traveled, so pushing into a wall or standing in a menu does not keep playing steps. Effects use a bounded voice pool, short cue cooldowns and subtle pitch variation. A master limiter keeps overlapping sounds within the output ceiling.

## Controls

Esc → Audio has independent Music and Sound effects sliders, a preview button and a default-volume button. Zero mutes that category. Choices are remembered separately from the gameplay save, so the existing save remains compatible.

## Validation

Godot 4.7.2 checks passed for music looping and area selection, crossfades, all effect sample data and playback routing, movement-only footsteps, pause ducking, real audio-menu controls, independent mute and restart persistence. A rendered Windows playback test captured nonzero audio at the mixer and the Audio menu was visually inspected. Music files were checked for headroom and small loop-boundary steps. Wider-range guard detection, wall occlusion, local-only aggro, retreat, dungeon progression/boss behavior and selective-loot persistence checks also passed.

All tests ran with separate save/settings profiles. Open this folder's project.godot in Godot and run the main scene. Restart a running game to load the new audio.
