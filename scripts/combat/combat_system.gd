extends Node

signal damage_resolved(target: Node, result: Dictionary)
const MAX_VALUE := 2_000_000_000
const DAMAGE_TYPES := [&"physical", &"arcane", &"fire"]
var rng := DeterministicRng.new(0x52494654)

func set_seed(seed_value: int) -> void:
	rng = DeterministicRng.new(seed_value)

func resolve_hit(attacker: Node, target: Node, packet: Dictionary) -> Dictionary:
	var values := _outgoing_values(packet, true)
	var defended := _defend(values, target.combat_stats, int(packet.get("attacker_level", 1)))
	return _apply(target, defended, bool(packet.get("can_crit", true)) and bool(values.get("_critical", false)))

func create_dot_snapshot(packet: Dictionary) -> Dictionary:
	var copy := packet.duplicate(true)
	copy["can_crit"] = false
	var values := _outgoing_values(copy, false)
	values.erase("_critical")
	return {
		"values": values,
		"attacker_level": int(packet.get("attacker_level", 1)),
		"interval_ms": clampi(int(packet.get("interval_ms", 500)), 50, 60_000),
		"duration_ms": clampi(int(packet.get("duration_ms", 2000)), 0, 600_000),
	}

func resolve_dot_tick(target: Node, snapshot: Dictionary) -> Dictionary:
	var defended := _defend(snapshot["values"], target.combat_stats, snapshot["attacker_level"])
	return _apply(target, defended, false)

func _outgoing_values(packet: Dictionary, allow_crit: bool) -> Dictionary:
	var base: Dictionary = packet.get("base", {})
	var conversion: Dictionary = packet.get("conversion", {})
	var converted := {}
	for damage_type in DAMAGE_TYPES:
		converted[damage_type] = maxf(0.0, float(base.get(damage_type, 0.0)))
	for source in DAMAGE_TYPES:
		var routes: Dictionary = conversion.get(source, {})
		var total := 0.0
		for destination in routes:
			total += clampf(float(routes[destination]), 0.0, 100.0)
		var scale := 100.0 / total if total > 100.0 else 1.0
		var source_base: float = maxf(0.0, float(base.get(source, 0.0)))
		var moved := 0.0
		for destination in routes:
			if destination not in DAMAGE_TYPES: continue
			var portion: float = clampf(float(routes[destination]), 0.0, 100.0) * scale / 100.0
			converted[destination] += source_base * portion
			moved += source_base * portion
		converted[source] -= moved
	var increased: Dictionary = packet.get("increased", {})
	var global_bonus := clampf(float(increased.get("global", 0.0)), 0.0, 1000.0)
	for damage_type in DAMAGE_TYPES:
		var type_bonus := clampf(float(increased.get(damage_type, 0.0)), 0.0, 1000.0)
		converted[damage_type] *= 1.0 + (global_bonus + type_bonus) / 100.0
	var critical := false
	if allow_crit and bool(packet.get("can_crit", true)):
		critical = rng.roll_percent(float(packet.get("crit_chance", 0.0)))
		if critical:
			var multiplier := clampf(float(packet.get("crit_multiplier", 150.0)), 100.0, 1000.0) / 100.0
			for damage_type in DAMAGE_TYPES: converted[damage_type] *= multiplier
	converted["_critical"] = critical
	return converted

func _defend(values: Dictionary, stats: Dictionary, attacker_level: int) -> Dictionary:
	var output := {}
	var taken: Dictionary = stats.get("damage_taken", {})
	var resist: Dictionary = stats.get("resistance", {})
	for damage_type in DAMAGE_TYPES:
		var amount := float(values.get(damage_type, 0.0))
		amount *= clampf(float(taken.get(damage_type, 100.0)), 0.0, 1000.0) / 100.0
		if damage_type == &"physical":
			var armour := clampf(float(stats.get("armour", 0)), 0.0, MAX_VALUE)
			var reduction := clampf(armour / (armour + 100.0 + 10.0 * maxi(attacker_level, 1)), 0.0, 0.85)
			amount *= 1.0 - reduction
		else:
			var resistance := clampf(float(resist.get(damage_type, 0.0)), -50.0, 75.0)
			amount *= 1.0 - resistance / 100.0
		output[damage_type] = amount
	return output

func _apply(target: Node, values: Dictionary, critical: bool) -> Dictionary:
	var raw_total := 0.0
	for damage_type in DAMAGE_TYPES: raw_total += float(values.get(damage_type, 0.0))
	var total := clampi(int(floor(raw_total + 0.5)), 0, MAX_VALUE)
	if raw_total > 0.0: total = maxi(total, 1)
	var barrier_before: int = target.barrier
	var absorbed := mini(total, barrier_before)
	target.barrier = barrier_before - absorbed
	var life_damage := mini(total - absorbed, target.life)
	target.life -= life_damage
	var result := {"total": total, "barrier_absorbed": absorbed, "life_damage": life_damage, "critical": critical, "types": values.duplicate()}
	damage_resolved.emit(target, result)
	if target.life <= 0 and target.has_method("die"): target.die()
	return result
