# Recovery and sound polish

Recovery now uses a painted leather satchel, moss cloak, dagger, amber potion and jade charm. Your gear uses the larger bundle; defeated monsters use a smaller one beside the body. World depth sorting lets actors walk naturally in front or behind it. A quiet proximity ring and nearby recovery timer replace the plain circle/cross and floating item strip. Fully claimed or expired loot removes its marker. Loot records, saved games, recovery lifetimes and selective monster claiming retain their existing rules.

Sound effects now have softer attacks, reduced high-frequency noise, cue-specific volume and short repeat limits. Reward and interaction pings are lower wooden/metallic notes, spells use soft air rather than rising electronic tones, potions use a quieter liquid texture, and leveling uses plucked strings. Crowded combat cannot stack every attack sound on the same instant. Existing music and the player's saved volume choices are preserved. Esc > Audio still has separate music and effects controls.

Validation: headless audio, selective loot and RPG integration checks; a rendered Windows game test for recovery art, scene changes, claiming/removal, monster inspection, cue balance and repeat limiting. No test failures.

## Art source

Asset: assets/descent/recovery_bundle.png, created with the imagegen skill and copied into the project. Transparent source retained; Godot trims and scales the sprite at runtime.

Prompt: One polished isolated transparent three-quarter overhead world prop for a hand-painted fantasy RPG: squat worn chestnut leather satchel with brass buckles, folded moss green cloak, short iron dagger, corked amber potion, small jade leaf charm. Warm earthy palette, compact readable silhouette, painted highlights, upper-left light, no character, body, blood, text, UI, floor or border.

## Audio source

All effects remain original synthesized samples. Regenerate effects only with tools/compose_audio.py --effects-only. Omitting that flag regenerates the original music as well.
