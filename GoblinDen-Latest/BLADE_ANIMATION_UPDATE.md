# Blade Goblin walk and attack update

Open `project.godot` in Godot 4.7 and press F5. Select Blade with 1 in the Den.
Move with WASD, attack with Space or left click, and use the special with Q or right click.

- Walking uses the supplied 1280 x 1280 transparent sheet: 24 frames at 28 fps; the final repeated pose is omitted.
- Attacks use cells 5 through 19 (zero based) from the supplied 2560 x 2560 sheet. Repeated ready poses are skipped; each attack plays once in up to 0.34 seconds.
- Idle uses the opening walking pose. Left-facing movement/attacks mirror the art. Up/down movement retains the side view.
- Rendering compensates for sheet padding and matches body height and ground contact. The original artwork and alpha are preserved without re-encoding.
- Blade player, Assassin/Berserker evolutions, and Blade companions use the new animation. Combat damage, hit windows, cooldowns, and collision shapes retain their existing behavior.
- The attack and walk sheets have different character proportions and viewing angles, so the switch remains visible.

Changed: scripts/player.gd, scripts/goblin_ally.gd.
Added: scripts/blade_animation.gd, assets/blade_walk_sheet.png, assets/blade_attack_sheet.png, tests/blade_animation_test.gd.

Verified using Godot 4.7.2:
- New animation transition/integration checks: PASS.
- Existing combat_test.gd: PASS (0 failures).
- Existing class_roster_test.gd: PASS (0 failures).
- Visual rendering checked for walk/attack, left and right, transparency and scale.
- Existing thornwood_expanse_test.gd: three camera/spawn assertions fail. Repeating the test with the original unmodified player and companion scripts produces the same three failures: smoothing disabled, exterior spawn within camera tracking range, and immediate camera follow. This update does not repair those pre-existing camera issues.

Tests use an isolated Godot user-data folder during validation; your game save was not used.
The ZIP contains the source project. Godot regenerates its import cache when opened.
