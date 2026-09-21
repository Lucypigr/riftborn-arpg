# Riftborn ARPG architecture audit

Audit date: 2026-09-22

## Difference table

| System | Research evidence | Existing implementation | Gap | Decision |
| --- | --- | --- | --- | --- |
| Player movement | Player records expose base character stats, but not Godot movement. | `scripts/actors/player.gd` uses `CharacterBody2D`, WASD and mouse aim. | No camp/dungeon state, touch movement, animation state or attack wind-up. | Preserve combat actor contract; rebuild movement input and add touch controls. |
| Combat | `records/game/combatformulas.dbr` contains source equations, but not complete engine collision or AI. | `scripts/combat/combat_system.gd` has deterministic damage, conversion, armour, resistance, Barrier and DoT. | Direct melee attack selects a nearby target and has no attack animation or hit window. | Preserve the tested calculator; add attack telegraph, hit flash and attack state around it. |
| Skills | Skill records use template-driven fields and level arrays. | `SkillData` supports a few hand-authored `.tres` resources. | No modular effect execution, support gems or skill progression. | Keep the data resource; add only the two vertical-slice skills needed for a complete loop. |
| Enemy AI | Monster records link controller, skill and loot references. | `enemy.gd` has chase, ranged spacing and cooldown. | Fixed five enemies, no waves, elite phase, stagger, telegraph or spawn director. | Replace fixed scene instances with a director and three authored enemy profiles. |
| Loot and equipment | Loot records expose item references, weights and affix switches; weapon records expose stat fields. | No item, loot, pickup, inventory or equipment code. | Entire loop missing. | Add small original `ItemData`, `LootTable`, `InventorySystem` and ground pickup modules. |
| World flow | Database records contain portals/teleports, but do not define Riftborn level flow. | One static training arena in `main.tscn`. | No camp, portal, dungeon clear, elite or return flow. | Rebuild the main world as camp → portal → generated battle map → return. |
| Presentation | Database references original game assets, which are not licensed for Riftborn use. | Player, enemies and ground are plain Polygon2D shapes. | Does not meet the visual bar for an ARPG slice. | Use original generated raster art in `assets/art/`; keep code-drawn effects limited to feedback. |
| Mobile | Research database cannot prove mobile input behavior. | No touch controls. | Desktop mouse logic is not sufficient. | Add a separate virtual movement pad and action buttons; never map movement touch to attack. |

## Source and provenance conclusion

The existing repository was a combat prototype, not a recovered or completed ARPG. The source of the earlier implementation cannot be established from Git history beyond the existing commits. This slice therefore treats the current combat module as reusable code and treats all camp, world, enemy director, loot, equipment, UI and presentation work as new Riftborn implementation.
