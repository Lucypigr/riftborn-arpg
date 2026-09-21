# Riftborn ARPG research audit

Audit date: 2026-09-22

This document records only research summaries and source paths. It does not copy Grim Dawn source records into Riftborn.

## Source status

- Grim Dawn research root is readable at `D:\ARPG-Research\database`.
- The root contains `database.arz`, `templates.arc`, `records/`, and `templates/`.
- Current filesystem counts: 34,182 `.dbr` records and 818 `.tpl` files.
- No separate research report was found under `D:\ARPG-Research`; the only existing design report found in Riftborn is `docs/combat_spec.md`.
- The `.arz` and `.arc` files were identified as binary archives and were not treated as text source.

## Evidence classification

### VERIFIED — direct record and field evidence

| Finding | Source record | Fields / template |
| --- | --- | --- |
| Player record has base life, mana, strength, dexterity, intelligence, offensive and defensive ability values. | `records/creatures/pc/malepc01.dbr` | `templateName=database/templates/player.tpl`; `characterLife=250`; `characterMana=250`; `characterStrength=50`; `characterDexterity=50`; `characterIntelligence=50`; `characterOffensiveAbility=65`; `characterDefensiveAbility=65` |
| Skills are data records with a template and level-scaled damage arrays. | `records/skills/playerclass06/graspingvines1.dbr` | `templateName=database/templates/skill_attackprojectileareaeffect.tpl`; `Class=Skill_AttackProjectileAreaEffect`; `offensivePhysicalMin` and `offensiveSlowBleedingMin` contain semicolon-separated level values. |
| Monster records link controllers, skills and loot tables. | `records/creatures/enemies/boar_a01.dbr` | `templateName=database/templates/monster.tpl`; `controller`; `skillName1..5`; `skillLevel1..5`; `lootMisc1Item1..3`; `lootMisc2Item1..4`. |
| Loot tables contain item references and weights and expose rare prefix/suffix controls. | `records/items/loottables/misc/tdyn_commonmi_weapons.dbr` | `templateName=database/templates/lootitemtable_dynweighted_dynaffix.tpl`; `lootName1..31`; `lootWeight1..31`; `rareBothPrefixSuffix`; `prefixOnly`; `suffixOnly`. |
| Weapon records carry combat modifiers through weapon templates. | `records/items/faction/weapons/axe1h/f001a_axe.dbr` | `templateName=database/templates/weapon_axe.tpl`; defensive and offensive character modifier fields. |
| Combat data includes equations for physical, magical, duration and ability calculations. | `records/game/combatformulas.dbr` | `templateName=database/templates/combatequations.tpl`; `physicalDamageEquation`; `magicalDamageEquation`; `offensiveAbilityEquation`; `defensiveAbilityEquation`. |

### INFERRED — supported by data structure, not engine proof

- `skillNameN` plus `skillLevelN` indicates a skill attachment list on monster records, but the record alone does not prove the complete runtime cast scheduler.
- `lootNameN` plus `lootWeightN` indicates weighted loot selection, but the full roll order and duplicate-prevention behavior require engine knowledge not present in the database.
- The template include chain (`monster.tpl` → `character.tpl`, `weapon_axe.tpl` → `Weapon.tpl`) indicates shared schemas, but it does not expose Godot-like runtime classes.

### ORIGINAL — Riftborn decisions

- Riftborn uses its own damage pipeline documented in `docs/combat_spec.md`.
- Riftborn will use a small original loot table with explicit rarity and affix rules for the vertical slice.
- Camp, rift portal, wave generation, elite encounter, inventory, pickup and return flow are original Riftborn systems.
- Generated art in `assets/art/` is original project art and is not copied from the research database.

## Protection boundary

No `.dbr`, `.tpl`, `.arz`, `.arc`, Grim Dawn image, sound, model or extracted game asset is included in the Riftborn project.
