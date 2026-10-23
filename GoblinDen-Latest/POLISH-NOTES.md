# October 23 Godot polish

## Movement, animation, and interaction pass

- Short acceleration and stronger braking keep movement responsive while softening starts and stops. Class top speeds remain intact.
- Animation follows actual physics displacement, so a goblin stops walking when blocked by a wall.
- Dodge exit no longer carries excess velocity into normal walking.
- Attack artwork and swing arcs keep their original facing for the duration of the swing.
- Idle sprites have a subtle breathing motion; direction selection resumes immediately when an attack finishes.
- Travel clears velocity, animation state, and pending attacks, dodges, and specials.
- One shared focus resolver selects a nearby interaction by distance and line of sight. The visible prompt and E use the same target.
- A gold focus ring and styled contextual prompt cover residents, travelers, chests, resources, passages, den stations, dungeon seals, stairs, and vaults.
- Unavailable resources and dungeon objectives explain their state in the prompt.
- Inventory, dialogue, codex, pause, and death block world interaction.
- Interaction activation has a short debounce and a soft audio cue. Distant markers retain their names without advertising active E prompts.
- Existing NPCs still provide settlement services through dialogue.

## Earlier polish retained

- 140 ms dodge and special input buffers; pending combat clears while inventory or chat is active.
- Damage numbers for player-owned ranged impacts, including splash targets.
- Equipment comparisons, informative item tooltips, unavailable action states, and explicit equipment feedback.

## Validation

Godot 4.5.1: focused movement/interaction checks, directional/evolution animation, combat, RPG systems, NPC services/persistence, three-floor dungeon, prior polish, and connected-den collision tests.
Visual smoke captures checked chest, NPC, passage, and resource focus. Human playtesting remains the final check for movement feel and audio balance.

This archive is the editable Godot project. Open project.godot to continue development. No console/controller implementation, browser rebuild, or GitHub push is included in this pass.

## GoblinDen Data editor

The project now includes an enabled Godot main-screen plugin for editing 221 existing definitions across 19 categories. Names, supported gameplay numbers, dialogue, and item icon references come from JSON catalog files. Fixed IDs and behavior/layout links remain protected. See DATA-EDITOR-GUIDE.md for the edit/save/restart workflow and the exact scope.

Validated editor save/reopen, backups, invalid values, external-change conflicts, and runtime renaming with stable saved equipment IDs. Nine existing gameplay regression suites passed. Native UI smoke captures verified Items and Monsters layouts. No GitHub push or browser export was performed for this update.
