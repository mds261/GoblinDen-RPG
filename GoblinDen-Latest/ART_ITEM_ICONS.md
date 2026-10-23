# Painted item icons

Generated with the built-in image-generation tool for this project. Asset: `assets/items/item_atlas.png` (transparent RGBA, 1374 × 1145, six columns by five rows, 229-pixel cells). The runtime uses `scripts/item_icons.gd` and AtlasTexture regions; individual files are not required. Empty equipment slots retain their silhouette icons.

All 25 inventory/unique-loot definitions have a distinct icon. The same mapping is used by backpack and storage entries, equipped slots, shop and crafting buttons, drag previews, pickup notifications, ground relic/scrap drops and recoverable-bag contents. Five additional icons cover the existing potion and scrap resources, backpack, chest and scroll.

## Atlas mapping

| Row | Column 1 | Column 2 | Column 3 | Column 4 | Column 5 | Column 6 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | wood | ore | herb | fish | rust_sword | iron_sword |
| 2 | axe | club | bow | staff | shield | cloth_armor |
| 3 | helmet | legs | boots | ring | necklace | rusty_sword |
| 4 | hunter_shortbow | priest_rosary | captain_sword | rogue_stiletto | mage_ember_staff | paladin_greatsword |
| 5 | hero_dawnbreaker | potion | scrap | backpack | chest | scroll |

## Generation prompt

Create ONE production game UI asset: a perfectly regular 6-column by 5-row icon atlas, total 30 cells, canvas 1536 wide by 1280 high if possible (aspect 6:5). Transparent background everywhere outside the isolated objects. Every cell same dimensions and perfectly aligned. Each icon centered in its own cell with 20% empty padding on every side. NO borders, NO grid lines, NO lettering, NO numbers, NO labels, NO extra objects outside cells. Hand-painted dark fantasy goblin RPG inventory artwork, muted earthy materials, warm worn iron, moss greens, antique gold, high contrast silhouettes, clean sharp edges, consistent light from upper left, readable reduced to 40 pixels. Not flat line icons, not photorealism, not glossy 3D, not pixel art. Single isolated item or compact bundle per cell. STRICT row-major order: ROW 1: bundle of thornwood logs; chunky bog iron ore with iron flecks; glowing green medicinal leaf sprig; silver freshwater fish; simple short rusty goblin sword; sturdy forged straight iron sword. ROW 2: wooden handled woodsman's axe; stone-headed primitive club; long wooden bow with taut string; twisted wooden staff with luminous green mushroom cap; ironwood round shield; woven brown cloth chest armor. ROW 3: worn iron helmet; brown hide leggings; pair of sturdy leather boots; amber gem ring; fang-and-green-stone goblin necklace; chipped human militia sword with dark red wrapping, clearly different from row1 rusty sword. ROW 4: elegant yew recurve shortbow distinct from longbow; ornate gold sun-cleric censer hanging from chain; knight captain's sword with blue hilt and wider steel blade; pair of black assassin stilettos crossed; ruby ember staff with orange flame crystal; massive royal paladin greatsword with gold sun crossguard. ROW 5: legendary radiant golden hero sword with white sun gem, most ornate; stoppered red healing potion bottle; compact pile of scavenged metal scrap; brown leather backpack with green rolled blanket; iron-banded wooden storage chest; rolled parchment spell scroll tied with purple string. Ensure exactly 30 separate icons occupying their assigned cells, no overlap or bleed between cells, all fully within padding.

## Validation

Godot imported the atlas successfully. Coverage checks verified every item ID maps to a distinct in-bounds atlas region; UI rendering did not change inventory or progression data. RPG integration regression checks passed. Inspected actual inventory/equipment renders at the game's 1152 × 720 viewport. NPCs and Snare remain part of the project; the live browser build still requires re-exporting.
