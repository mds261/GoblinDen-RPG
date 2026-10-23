# October 22 single-player design implementation

This branch implements the offline systems in `Goblin_Den_Complete_Development_Plan_Spells_Updated_Oct_2026.pdf`. It is a playable first pass for balancing and playtesting, not a completed content expansion.

## Play the new loop

Open `project.godot` in Godot 4.x (validated with 4.5.2), then run the main scene. In the den, use the **Forest trail** marker near the southeast side. In the forest, the **Trading settlement** marker leads to Bramble Market. The forest's southeast **Bog trail** leads to Mirewood Bog; the bog connects to Frostroot Cavern. Every new connection has a return route. Original den rooms, encounters, classes, evolutions and companions remain available.

Press **I** or the Backpack button for inventory/equipment. Select an item, then Equip, Use or Transfer; double-click equips and dragging onto a valid equipment slot also works. Click an occupied slot to unequip. Approach the den chest or settlement depot and press **E** to transfer items. Storage access requires being physically at that service. Crafting at home can consume den-chest materials; depot materials stay separate. The smith/merchant sells equipment and supplies; the trainer teaches actions; the quest board rewards five defeated enemies.

**F1–F12** activate assigned actions; click hotbar buttons as an alternative. Scroll the inventory panel to configure actions and rebind keys. Browser-reserved keys may need rebinding. Enter opens chat; `/cast heal` and `/cast fireball` use the same action validation as the hotbar. The targeting toggle switches nearest-enemy automatic targeting and mouse-directed manual aiming. Inventory interaction and chat typing suppress normal gameplay input.

## Implemented

- Shared transactional inventory model: bounded containers, stacks, atomic transfers, half-stack transfers, search, sort, bag upgrades, den-chest expansion, quick transfer and item tooltips.
- Eight equipment slots around a goblin preview, compatibility checks, immediate stat recalculation, level requirements and two-handed weapon/shield handling. Weapons may be used across classes; weapon proficiency determines melee versus ranged behavior.
- Existing character XP/levels plus spendable Strength, Dexterity, Vitality, Intelligence and Willpower points. Use-based combat, shielding, gathering and crafting proficiencies; Knight/Archer/Mage favored skills earn 1.5x proficiency XP as an initial tuning value.
- Learned actions, mana, cooldowns, automatic/manual targeting, range and line-of-sight checks, key customization, clickable hotbar and General/Combat/Loot/System event channels. Heal starts learned; other spells/abilities come from the trainer. Shield Bash requires a shield.
- Death transfers backpack and worn equipment into a recoverable corpse and respawns the goblin at home. Currency, den chest and depot remain protected. Multiple corpses persist independently. Fresh/decaying/fading colors and a five-minute warning precede permanent expiration at 30 minutes of active gameplay. Closing the game preserves remaining time.
- Separate safe settlement, persistent personal depot, merchant/smith, supply purchase, trainer and quest board. Later hub discoveries can use the same personal-depot model.
- Forest/bog/cave danger tiers, periodic ordinary-enemy encounters, occasional wandering merchants/injured travelers/treasure hunters, resource gathering, uncommon drops, zone-dependent weather and travel/rest-driven world time. Random bosses are excluded.
- All new inventory, equipment, skills, attributes, learned spells, hotkeys, cooldowns, discovery flags, NPC encounters and corpses are saved in a new section of the existing save. Existing saves migrate into the item model on first use.
- Existing combat windups, dodges, hit effects, legacy upgrades and follower recruitment remain. The known camera-affecting combat-feedback bootstrap is removed while individual hit and camera effects remain.

## Scope and balance still open

Multiplayer, mandatory den raids, additional settlements, expanded follower/decorating systems, advanced spell upgrades and a large content roster remain deferred as in the plan. New zones reuse existing painted backgrounds with biome tints; new service/loot/corpse markers are a first visual pass. Prices, drop chances, XP formulas, crafting recipes, encounter pacing, spell targeting and corpse-drop rules need playtesting. Newly added proficiencies are intentionally simple and their damage effects are modest. The intended 15–20 minute pacing has not been validated with a human playtest.

The source changes do **not** regenerate the previously committed `docs/` web build. Re-export using the corrected **Web** preset to update the browser game; exporting and publishing are separate from this source branch. Existing live Pages content is unchanged.

## Validation

Passed on Godot 4.5.2: project import/launch, RPG integration tests (atomic full-container swaps, conservation, storage separation, all new return routes and walkable arrivals, corpses and persistence, bindings and input suppression), original combat regression tests and den collision/doorway tests. Rendered and inspected the equipment panel and new area scenes with the compatibility renderer.

Run tests with a **temporary XDG_DATA_HOME** (or a disposable Godot user-data directory on other platforms), because the inherited test harness clears its test save. Tests are not intended to run against your personal playthrough save.

## Snare animation update

Snare now has an animated rune seal, iron jaws, venom motes and a lifetime arc while armed. Triggering it creates an expanding impact ring and a thorn cage attached to each caught enemy, with rising particles that fade at the end of the existing slow duration. Disarming and expiration do not create a capture effect. Damage, bleed, poison, trigger radius, stun and cooldown values are unchanged. Rendered checks verified the effect and its cleanup.

## Friendly NPC update

Seven named residents now use the existing directional goblin art: Moss (den keeper), Nib (depot keeper), Gruk (blacksmith), Vexa (spellkeeper), Pip (provisioner), Rusk (scout captain), and Tikk (forest guide). Approach and press E to open dialogue, choose their service, ask for advice, or leave. Dialogue pauses world danger, resource regeneration and corpse decay; closing it resumes gameplay. Residents face nearby players and are separate from enemy and companion combat groups.

Random merchants, injured scouts and treasure hunters now have visible goblin actors and dialogue. Trade/help choices are explicit; talking does not spend scrap or consume supplies. Resolving an encounter removes its actor, and a resolved encounter cannot pay or trade twice. Conversation discovery flags and traveler IDs persist through saves. Corpse looting takes priority when an NPC is nearby. Names and dialogue are provisional.

Verified seven-resident spawning, local service menus, one-time contract rewards and trades, paused dialogue timers, traveler actor cleanup, and conversation save/reload. Inventory and den-doorway regression tests passed. Visually inspected the market and dialogue panel.

## Painted item-art update

Every current item definition now has a distinct painted icon. The shared atlas mapping is used in inventory/storage, equipped slots, shops, crafting, drag previews, pickup feedback and ground loot displays. Empty slots retain their silhouettes. See `ART_ITEM_ICONS.md` for the complete mapping, asset location and generation prompt. Verified full coverage, in-bounds atlas regions and unchanged inventory/progression behavior; inspected UI renders. No item stats were changed.

## Three-floor quest dungeon update

Sealed Descent is connected beyond Frostroot Cavern, with three large floors, ward-seal objectives, side vaults, a floor map, return stairs, increasing enemy tiers, a new animated final boss and a one-time reward/return quest for Rusk. See `QUEST_DUNGEON.md` for spoiler-light instructions and validation. All previously added item artwork, NPCs and Snare effects remain included. World placement is still provisional.

## Persistent exploration mini-map

The mini-map now works across every area and reveals terrain only through exploration. It replaces the pre-revealed dungeon overview. Wall-aware discovery, independent area/floor fog, discovered-only landmark markers, player/facing and known corpse indicators, an M/click show-hide control, and save/reload persistence are included. See `EXPLORATION_MAP.md` for controls and validation.
