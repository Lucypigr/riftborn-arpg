# Riftborn ARPG — BUILD 001

An original, playable isometric-style/top-down action RPG combat prototype made with **Godot 4.3 stable**. No third-party game code, data, or art is included; the geometric visuals and combat rules were created for this project.

## Play

1. Install Godot 4.3 stable (or a compatible Godot 4 stable release).
2. Open `project.godot` and press **F6/F5**, or run `godot4 --path .`.
3. Move with **WASD**, aim with the mouse, use **left mouse** for Rift Cleave, and **right mouse or Space** for Arc Bolt.

The training ground contains chasing melee enemies and ranged enemies that maintain distance. Damage, armour, resistance, Barrier and life are resolved centrally by `CombatSystem`; death respawns the player after two seconds.

## Structure

* `data/skills/` — data-only skill resources, ready for tags and future gem/link modifiers.
* `scripts/combat/` — deterministic RNG, central damage pipeline, and projectile delivery.
* `scripts/actors/` — player and enemy behaviour.
* `scenes/` — composed player, enemies, projectile, and playable arena.
* `docs/combat_spec.md` — normative units, ordering, DoT, defence, and RNG rules.
* `tests/` — headless combat/event/resource tests.

## Test

```bash
GODOT_BIN=godot4 ./scripts/test.sh
```

The test script first imports/parses the project and then checks damage math, conversion ordering, Barrier separation, seeded RNG, DoT snapshots, death/events, and all scene references.

On a Linux x86-64 machine without Godot, `./tools/install_godot.sh` downloads the pinned official 4.3-stable binary into the ignored `.tools/` directory. Then use `GODOT_BIN=.tools/godot-4.3-stable/godot4 ./scripts/test.sh`.

## BUILD 001 scope boundary

Skill data exposes tags, projectile count, area and damage multipliers, but the complete active/support gem inventory, sockets, links, modifier aggregation UI, loot, progression, audio, and saved games are intentionally deferred beyond BUILD 001.
