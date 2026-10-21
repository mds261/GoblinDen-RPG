# Goblin Den — Painted Dark Fantasy (Expanded Goblin Perspective RPG)

An expanded Godot 4 top-down dark-fantasy RPG built from the **Goblin Perspective RPG** concept document: begin as a surviving goblin in an underground tribe, switch and evolve across **4 core classes** and **9 advanced specializations**, build up **8 Goblin Den facilities**, assemble an **inverted RPG party** of goblin followers, steal **story-driven human weapons** with stat tradeoffs, use **cave shadow ambushes, chokepoints, and traps**, and repel **5 escalating tiers of coordinated human adventuring parties**.

Uses pure GDScript and bundled hand-painted dark-fantasy assets (`assets/`). No external plugins, API keys, or internet connection required.

## New: layered continuous Thornwood exterior

After defeating the Wolf Rider in Thornwood Hollow, the next exit opens a large, uninterrupted painted 2D exploration zone. The exterior keeps the established attacks, specials, projectiles, companions, drops, and enemy behaviors while adding an immediately responsive following camera, invisible physical route boundaries, landmarks, interactions, and spaced woodland patrols. The opaque painting remains strictly behind every actor and combat effect; foreground cutouts are deferred until properly isolated transparent art is available.

## Thornwood Expanse - Continuous Exterior Progression

Defeating the **Thornwood Wolf Rider** now opens the trail beyond Thornwood Hollow into the **Thornwood Expanse**. Unlike the earlier 1152x720 cave rooms, this is a **2304x1440 continuous exterior zone**: the player remains at normal gameplay scale while the `Camera2D` follows movement across the landscape. The spawn point begins inside the camera's valid tracking range and smoothing is disabled outdoors, preventing the opening view from appearing fixed.

- No room-to-room gates inside the exterior; the player walks freely through one broad woodland region.
- Branching visual routes connect a fallen-root arch, an old watch shrine, an abandoned hunter camp, a stream ford, and a high overlook.
- The cave entrance remains a visible return point to Thornwood Hollow.
- Exploration discovers and permanently records five landmarks.
- Exterior camera and collision bounds are activated on entry, then restored to room-sized limits when returning underground.
- The exterior background is `assets/thornwood_expanse.png`; its world-sized rendering is controlled by `scripts/cave.gd`.
- The player camera is explicitly enabled and forced to update when the zone changes, so it scrolls beyond the opening viewport.
- Collision polygons follow the old-growth trees, shrine, hunter camp, stream, waterfall, forest walls, and cliff edges. The stream ford, wooden bridge, and route loops remain traversable.
- Five one-time world interactions make the environment useful: forage root-herbs, invoke the shrine, search the hunter camp, recover river scrap, and study the overlook trail totem.
- Three spaced exterior patrols use the original 2D combat system, including attacks, specials, projectiles, status effects, companion support, scrap, and XP.

## Expanded Features (Based on Concept Document)

1. **Four Core Goblin Classes & Nine Class Evolutions (Section 1)**
   - **`[1] Blade Goblin`** (*Fast melee striker*): Dual blades, combo crits, bleed stacks, fast dodge, and **Shadow Flurry (`Q`)**.
     - Evolves into **Assassin** (lethal backstab crits + venom/bleed burst) or **Berserker** (+40 HP, blood-frenzy attack speed & lifesteal).
   - **`[2] Archer Goblin`** (*Ranged hunter*): Poison arrows, kiting speed, and **Venom Snare Traps (`Q`)**.
     - Evolves into **Hunter** (3-arrow piercing volley + razor traps) or **Beastmaster** (summons a loyal **Cave Fang Wolf** companion).
   - **`[3] Knight Goblin`** (*Front-line tank*): Heavy armor (`25%` damage reduction), cleaver knockback, and **Shield Bash & Bulwark (`Q`)** (stuns enemies & grants a `3.5s` barrier).
     - Evolves into **Warlord** (Goblin Chief's Warcry buffs all goblin allies) or **Guardian** (+65 HP, +20% armor, reflects blocked damage).
   - **`[4] Mage Goblin`** (*Fragile spellcaster*): Explosive fire/hex bolts, slow curses, and **Hex Miasma Blast (`Q`)**.
     - Evolves into **Shaman** (heals player & goblin allies), **Warlock** (explosive hellfire bolts + lifesteal), or **Necromancer** (raises fallen humans as **Risen Skeleton** minions).

2. **Coordinated Human Adventuring Parties & Threat Tiers (Sections 2 & 3)**
   - **Knight**: Holds the frontline, telegraphs heavy strikes, and projects a shield aura that reduces damage taken by nearby human allies by `25%`.
   - **Priest**: Stays in the backline and casts **Sacred Mend** (healing wounded human allies for `+24 HP` and buffing their attack), forcing you to prioritize targets.
   - **Mage**: Channels delayed **Arcane Flame Pillars** (`68px` AoE blast zones) that punish clustered goblins.
   - **Ranger**: Fires aimed broadhead arrows from afar and kites away when approached.
   - **Rogue**: High-speed flanker that actively searches for and **disarms Goblin Traps** before lunging at your backline.

3. **All Eight Goblin Den Home Base Facilities (Section 4 & 5)**
   - **Forge**: Reforge weapons (`+10` base damage per tier; unlocks up to Tier 5 in higher campaigns).
   - **Rest Fire**: Restore 100% HP, revive/heal all Goblin Party followers, and refill Bloodmoss Potions.
   - **Training Pit**: Unlock and cycle **Advanced Class Evolutions** at Level 2+ (or spend 4 scrap to train immediately).
   - **Archery Range & Trap Workshop**: Upgrade trap damage (`+12`) and ranged precision (`+6`).
   - **Shaman Hut**: Brew **Bloodmoss & Venom Potions** (`F` key) and increase Hex/Magic power.
   - **Recruitment Hut**: Recruit up to 4 specialists (**Goblin Archer**, **Goblin Shaman**, **Goblin Berserker**, **Goblin Rogue**) to fight alongside you (Section 7).
   - **Treasure Room**: Inspect and equip stolen human weapons with lore and tradeoffs (Section 6).
   - **War Room**: Launch **5 escalating Raid Campaigns** (from *Tier 1: The Breach Incursion* up to *Endgame: Legendary Hero Party*).

4. **Story-Driven Human Loot & Cave Ambush Tactics (Sections 3 & 6)**
   - Defeated human leaders drop named equipment with stat tradeoffs and flavor lore (such as the *Rusty Human Sword*, *Knight Captain's Sword* with `-10% Attack Speed (Too Large)`, *Outrider's Recurve Bow*, *Sun-Cleric's Relic Censer*, *Trapfinder's Twin Stiletto*, *Court Mage's Ember Staff*, *Royal Paladin's Sunblade*, and *Legendary Hero's Dawnbreaker*).
   - **Shadow Ambush Alcoves** along the cave perimeter grant **Cave Stealth (`AMBUSH READY`)** after `0.45s`, making distant enemies hesitate and empowering your next strike with massive ambush critical damage.
   - **Cave Chokepoint Pillars** appear in Tier 2–5 campaigns to block enemy arrows and funnel human knights into your traps.

## Polish & UX Layer

A juice and quality-of-life pass layered on top of the existing combat feel work
(`combat_feedback.gd` hit-stop and synthesized cues are untouched and still run).

1. **Camera Shake System** (`scripts/camera_fx.gd`)
   - Multi-octave decaying shake applied to the player's `Camera2D.offset`, so it composes cleanly with the existing viewport hit-stop shake.
   - Shakes are **stackable but never escalate**: a weaker shake cannot override a stronger one already in progress.
   - Fires on crits, specials, level ups, evolutions, campaign launches, captain kills, and player death.
   - Ships a paired **screen flash** overlay (warm for level ups, red for death, gold for boss downs).

2. **Floating Damage Numbers** (`scripts/floating_text.gd`)
   - Color-coded and pop-scaled: **orange** = crit, **amber** = normal, **red** = damage you take, **green** = heals, **gold** = loot/scrap, plus arbitrary status labels.
   - Drifts upward with deceleration, random horizontal jitter so stacked numbers stay readable, then fades.
   - Replaces the old inline per-enemy hit number, so damage never renders twice.

3. **Death Particle Bursts** (`scripts/death_effect.gd`)
   - Expanding ring plus scattered fading particles; separate `burst_enemy`, `burst_boss` (larger, gold), and `burst_ally` variants.

4. **Impact Flash / Sparks** (`scripts/hit_spark.gd`)
   - Radiating spark lines on melee impact, projectile detonation, and trap triggers, with per-projectile-style colors (`arrow`, `hex`, `fire`, `human_arrow`, `smite`) and a bigger golden burst on crits.

5. **Cooldown Arc Indicators**
   - Arcs drawn around the goblin: **purple** = Special (`Q`) recharge, **teal** = Dodge (`Shift`) recharge, **pulsing green** = active venom coating.
   - Complements the existing textual cooldown readout in the HUD.

6. **Damage Flash on the Player**
   - Brief red tint on hit that scales with how heavy the blow was.

7. **Enhanced HUD**
   - Slim blue **XP progress bar** under the health bar, plus a transient **SAVED** indicator.

8. **Save / Load System** (`scripts/save_data.gd`)
   - `ConfigFile` at `user://goblin_den_save.cfg`. Auto-saves every **30s** while in the Den and on key moments (level up, evolution, class switch, loot unlock, recruit, facility purchase, captain defeat, campaign launch).
   - Persists scrap, all facility levels, potions, campaign tier, player level/XP/class/evolution/damage bonuses, equipped + unlocked loot, and recruited party.
   - **Loads automatically on startup** (restoring your recruited war-party), and saves before `R` starts a fresh run.

9. **Tutorial Overlay** (`scripts/tutorial.gd`)
   - 22 contextual first-time hints covering movement, all four classes, specials, dodge, evolution, potions, loot, party, codex, scrap, and every Den facility.
   - Each hint shows **once per session**, tracked in a meta dict on the game node.

10. **Ambient Cave Particles** (`scripts/cave.gd`)
    - Four cheap, deterministic depth layers: slow **fog wisps**, drifting **dust motes**, **rising embers** anchored to the four wall torches, and cold **ceiling drips** with landing ripples in combat rooms only.
    - All drawn at `z_index = -1`, so atmosphere can never obscure actors, health bars, or interaction markers.

## Controls

| Input | Action |
| --- | --- |
| `WASD` | Move and aim/face a direction |
| `Space` / `Left Click` | Primary class attack (melee slash, poison arrow, mace smash, or hex bolt) |
| `Q` / `Right Click` | Class Special Skill (Shadow Flurry, Snare Trap, Shield Bash, or Hex Miasma) |
| `Shift` | Dodge burst with short invulnerability |
| `1` / `2` / `3` / `4` | Switch base class in the Goblin Den (Blade / Archer / Knight / Mage) |
| `C` | Cycle unlocked Class Evolution (Assassin/Berserker, Hunter/Beastmaster, Warlord/Guardian, Shaman/Warlock/Necromancer) |
| `F` | Drink Bloodmoss & Venom Potion (`+35 HP` and `8s` poison weapon coating) |
| `I` | Cycle equipped stolen human weapon / relic |
| `E` | Interact with a nearby Den facility or room gate |
| `TAB` | Toggle the **Goblin Warlord & Tribe Codex** overview |
| `R` | Start a fresh run |

## Open and Play

1. Extract `GoblinDen-Painted.zip` (or copy the updated folders into `C:\Goblin Game\GoblinDen-Painted`).
2. Open Godot 4, choose **Import**, and select `project.godot`.
3. Press **F5** to play.

## Headless Verification

From the project folder, run:

```bash
godot --headless --path . --script res://tests/expansion_test.gd
godot --headless --path . --script res://tests/combat_test.gd
```

`expansion_test.gd` covers the Den/raid loop, all four classes and evolutions, loot,
party recruitment, campaign tiers, **and** the full Polish & UX layer (camera shake,
screen flash, every floating-text / death-burst / hit-spark factory, HUD elements,
the save round trip, tutorial one-shot tracking, and the ambient cave layer).

Both suites call `SaveData.delete_save()` first, because the game auto-loads
`user://goblin_den_save.cfg` on startup — that keeps the checks deterministic
no matter what you last played.
