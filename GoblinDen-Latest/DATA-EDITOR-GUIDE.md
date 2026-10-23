# GoblinDen Data editor

Open this project in Godot and click **GoblinDen Data** beside the normal 2D / 3D / Script tabs. If the tab is missing, enable **GoblinDen Data** in Project > Project Settings > Plugins.

1. Stop the running game.
2. Select a category on the left. Use Items for weapons, armor, and materials; Player classes for the four playable classes; Spells for learned actions and class specials.
3. Search by display name or permanent ID.
4. Double-click a display name in the table, or select the row and edit its labeled fields on the right. Scroll the right pane for more fields.
5. Click **Save changes**. Validation errors appear at the bottom and block saving.
6. Start the game again with F5. The new names and values are read from the saved data files. An already-running game keeps its previously loaded data.

Example: select Items, search `iron_sword`, change Name to `Goblin Blade`, and change Attack from 9 to 12. Save, then restart the game. The weapon remains `iron_sword` internally, so existing inventories and equipment still refer to the right item.

## What is included

The editor covers items, monsters and bosses, player classes, evolutions, spells and class specials, companions, summons, NPC names/dialogue, travelers, rooms, stations, landmarks, world interactions, campaigns, quests, skill display names, attribute display names, equipment-slot labels, and named world labels.

The categories live in `data/catalog/*.json`. No database service, spreadsheet application, or Python installation is needed to use the editor. Icons reference the existing atlas or an optional image inside the project; artwork is not duplicated.

IDs, behavior types, class links, and encounter placement/layout links are fixed in the editor. Changing a name does not change behavior, teach a new spell, create a new class, or place a new monster. This first version edits the existing records; adding entirely new records/behaviors is still development work. It is not a general-purpose scene or animation editor.

NPC dialogue text can be edited directly. Names embedded inside prose, tutorials, or story messages are independent wording, so changing an entity name does not automatically rewrite every sentence mentioning it. Rooms and their main labels, inventory names, spell hotbar labels, monster labels, and NPC headers/prompts use the catalog directly.

## Saving and collaborating

Edits stay in memory until saved. **Revert selected entry** restores that entry to its last saved values. **Discard / Reload** reloads all categories and asks before discarding unsaved edits. Dirty state is retained when switching categories or searching.

Saving validates the full catalog, stages all changed files, and keeps the previous version of each changed file as `.json.bak`. If a write fails, it attempts to restore already-replaced files and reports any restore failure. If a category changed outside this editor, saving stops rather than overwriting that file; copy your intended edits, discard/reload, and apply them to the refreshed records.

Share the project folder through your normal source-control workflow. Each category has a separate file to keep changes manageable. No GitHub push or browser rebuild is included in this update. Published games need a new export to include edited project data; this is an authoring tool, not remote live configuration.

## Validation

The editor's save/reopen, invalid-value rejection, stable-ID protection, backups, and external-change conflict checks are exercised in `tests/catalog_editor_test.gd`. Runtime rename/stat/save compatibility is exercised with `tests/run_catalog_runtime_test.py --godot PATH_TO_GODOT`; close the editor first, since that test temporarily changes fixture values and restores the files afterward. The game does not require Python.

Other existing gameplay regression tests cover inventory/equipment, combat, NPC services, dungeon progression, movement/interaction, den passages/collisions, animations, special abilities, and item icons. Native UI smoke captures verify the Items and Monsters editor layouts.
