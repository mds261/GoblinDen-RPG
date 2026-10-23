# Art direction and generation

Created using the built-in ImageGen tool. Generated PNGs are included locally in `assets/descent/`; no network service or API key is needed to play.

Shared direction: richly textured hand-painted dark fantasy matching the established goblin cave and woodland art; chipped mossy gray-green stone, aged oak, tarnished bronze, ivory, restrained amber torchlight; orthographic overhead/three-quarter game views. Avoid flat vector shapes, cartoons, pixel art, neon, UI text and baked-in labels.

## Final prompt set

### stone_materials.png
Production square material atlas with four equal 2x2 quadrants and no dividers or gutters. Top left: overhead weathered flagstone floor with moss in joints. Top right: dense dark cavern rock wall tops with roots. Bottom left: frontal ancient masonry wall face, chipped beveled blocks with upper-left warm light and lower shadow. Bottom right: worn ceremonial vault paving engraved with faint circular runes. Fill every quadrant edge to edge; no doors, characters, props or horizon.

### dungeon_props.png
Transparent six-prop atlas in 3x2 cells with isolated silhouettes and consistent camera/light. Top row: substantial descending stone stairwell with side rails and lamps; matching ascending staircase and crumbling doorway; inactive rune obelisk on rooted stepped plinth. Bottom row: matching active jade-gold ward obelisk; closed carved oak and bronze reliquary with skull clasp; matching open reliquary with coins and amber relic. Detailed painterly dimensional production sprites, no text or grid lines.

### vault_hunger.png
Transparent 3x2 boss frame atlas, consistent chest mimic identity and camera, full silhouettes. Dark mossy carved oak chest with bronze straps and skull clasp, six root-like spider legs when awake, maroon maw, ivory fangs, gold chain tongue and dim amber eyes. Frames: dormant closed chest; awake idle; walking alternate; wide-jawed bite windup; braced slam/coin-storm attack; defeated collapsed chest with broken lid and spilled coins. Keep all frames isolated in cells and use the established painterly materials.

### chamber_floors.png
Four equal full-square overhead chamber paintings in a 2x2 atlas. Central 75 percent clear walkable floor, environmental storytelling only near edges. Root crypt with fine roots, moss and engraved graves; damp cool gray-blue scriptorium with parchment scraps and a worn circular floor motif; forgotten sanctuary with cracked patterned stone and sparse bones and rubble; royal vault with a bronze-gold heraldic circular seal and coin flecks. No raised walls, large obstacles, stairs, doors, characters or UI.

### dungeon_dressing.png
Transparent 3x2 isolated dungeon dressing atlas with generous padding. Top row: carved stone-backed iron torch sconce with amber flame; squat bronze coal brazier; tall broken mossy carved pillar. Bottom row: low bones, old shield and rusty sword scatter; low crumbled masonry and roots; ruined open archway with transparent passage. Matching top-down three-quarter camera, worn realistic painterly materials, no text, backgrounds or adjoining silhouettes.

## Runtime use

`descent_art.gd` trims transparent regions once and shares atlas textures. `dungeon_floor.gd` maps paintings only to the existing collision-defined floor cells. Stairs and ward art use the existing exact interaction points. Props and boss retain game-driven animation and feedback; artwork does not replace attack or collision logic.
