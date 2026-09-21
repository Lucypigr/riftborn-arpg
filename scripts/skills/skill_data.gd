class_name SkillData
extends Resource

@export var display_name := "Skill"
@export var tags: PackedStringArray = []
@export var base_damage: Dictionary = {&"physical": 10.0}
@export var conversion: Dictionary = {}
@export var mana_cost := 0
@export var cooldown_seconds := 0.5
@export var range_pixels := 90.0
@export var projectile_speed := 650.0
@export var projectile_count := 1
@export var area_multiplier := 1.0
@export var damage_multiplier := 1.0

func make_packet(source_stats: Dictionary) -> Dictionary:
	var scaled := {}
	for damage_type in base_damage:
		scaled[damage_type] = float(base_damage[damage_type]) * clampf(damage_multiplier, 0.0, 1000.0)
	return {
		"base": scaled,
		"conversion": conversion,
		"increased": source_stats.get("increased", {}),
		"crit_chance": source_stats.get("crit_chance", 0.0),
		"crit_multiplier": source_stats.get("crit_multiplier", 150.0),
		"attacker_level": source_stats.get("level", 1),
		"can_crit": true,
	}
