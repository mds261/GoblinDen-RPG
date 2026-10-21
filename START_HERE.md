# Goblin Den — Combat Update 1

This is a separate, updated copy of GoblinDen-Painted-TypeFix. The original archive is unchanged.

## Play

1. Extract the entire ZIP into a new folder.
2. Import `project.godot` in Godot (verified with the installed Godot 4.7.2).
3. Press F5. Walk right from the Den and press E to enter the passage.
4. Defeat the scouts, collect their drops, and continue right to the Breach.

This is an editable Godot project, not a standalone Windows executable.

## What's changed

- Mouse movement aims independently of walking. Left click attacks; right click uses your special. Press Space to return to movement-based aiming until the mouse moves again.
- Shift dodges in your movement direction, falling back to your aim direction when standing still.
- Attacks pressed just before recovery finishes are buffered for 0.14 seconds.
- Hits have short impact slowdown, restrained screen movement, and synthesized sound effects. Swing and dodge cues are included. These are first-pass procedural sounds, not final recorded audio.
- Dodge and special cooldowns are displayed continuously.
- Human pursuit and goblin follower pursuit route around the cave pillars. This is grid-based pathfinding; crowd formations and advanced ranged repositioning remain future work.
- The first Iron Captain has a dedicated fight. Later named bosses retain their original behavior.
- The Captain's arena now has two solid stone pillars. His charge locks its direction during the warning. Dodge sideways or bait him into stone to stagger him.
- His sweeping attack leaves a safe rear arc. Green ground rings indicate recovery openings.
- Below half health he attempts one rally. Stun him during the gold warning to stop it. Otherwise two weak guards arrive and the human party receives a temporary damage buff.
- Leaving a room cancels pending Captain attacks, preventing an unseen attack from carrying across transitions.
- The viewport is explicitly set to 1152 × 720 to match the authored layout.

## Verification

Both automated suites passed in Godot 4.7.2:

```
godot --headless --path . --script res://tests/expansion_test.gd
godot --headless --path . --script res://tests/combat_test.gd
```

The first suite checks existing movement, damage, upgrades, travel, loot, classes, recruitment, and campaign behavior. A pre-existing test typo was corrected to query groups on SceneTree.

The second checks actual movement around a pillar, locked charge aiming, wall stagger, front/rear sweep damage, rally interruption and reinforcements, movement-directed dodge, transition cancellation, and feedback cleanup.

A rendered Captain encounter was also inspected for visual layout. Full human playtesting and difficulty tuning are still needed.

## Scope of this milestone

This release focuses on combat, navigation, and the first boss. Save/load, menus, campaign progression redesign, new character animation assets, and companion command controls are not implemented yet. Existing R-to-restart and War Room campaign-cycling behavior remain.
