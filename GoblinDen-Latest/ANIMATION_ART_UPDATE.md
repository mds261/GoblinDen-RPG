# Animation & Station Art Update

This version is based only on the original `GoblinDen-Polishedv1` project.

## Character animation

The shared painted-actor renderer now gives the player, goblin allies, human enemies, and bosses:

- rhythmic walking bounce and side-to-side stride;
- subtle squash/stretch and directional lean;
- foot-contact dust and responsive ground shadows;
- attack anticipation, forward snap, and follow-through;
- restrained motion echoes and class-colored weapon trails.

The animation is visual only and does not alter collision or combat timing.

## Den station artwork

The original furnace and campfire remain unchanged. The other six facilities now use matching painted transparent artwork:

- Training Pit;
- Archery Range & Trap Workshop;
- Shaman Hut;
- Recruitment Hut;
- Treasure Room;
- War Room.

The new `assets/den_stations_v2.png` sheet includes a true alpha channel. Station-specific glow, embers, magical bubbles, and treasure glints are layered in Godot for gentle motion.
