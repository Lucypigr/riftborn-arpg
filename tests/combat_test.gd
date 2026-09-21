extends SceneTree

class DummyTarget extends Node:
	var life := 100
	var barrier := 0
	var died := false
	var combat_stats := {"armour": 0, "resistance": {&"arcane": 0.0, &"fire": 0.0}, "damage_taken": {}}
	func die() -> void: died = true

var failures := 0

func _init() -> void:
	call_deferred("run")

func expect_equal(actual, expected, label: String) -> void:
	if actual != expected:
		failures += 1
		printerr("FAIL %s: expected %s, got %s" % [label, expected, actual])
	else: print("PASS ", label)

func run() -> void:
	var combat = load("res://scripts/combat/combat_system.gd").new()
	root.add_child(combat)
	# 100 physical with armour 100 at level 1 => 100 * (1 - 100/210) = 52.38 => 52.
	var target := DummyTarget.new(); target.combat_stats.armour = 100; root.add_child(target)
	var result: Dictionary = combat.resolve_hit(null, target, {"base": {&"physical": 100.0}, "can_crit": false, "attacker_level": 1})
	expect_equal(result.total, 52, "physical armour formula and rounding")
	expect_equal(target.life, 48, "life damage application")
	# Converted physical receives only destination increased: 100 -> fire, +50% fire, resisted 20% = 120.
	target.life = 500; target.combat_stats.armour = 0; target.combat_stats.resistance[&"fire"] = 20.0
	result = combat.resolve_hit(null, target, {"base": {&"physical": 100.0}, "conversion": {&"physical": {&"fire": 100.0}}, "increased": {&"physical": 100.0, &"fire": 50.0}, "can_crit": false})
	expect_equal(result.total, 120, "single destination bonus after conversion")
	# Barrier and life remain separate.
	target.life = 100; target.barrier = 30; target.combat_stats.resistance[&"fire"] = 0.0
	result = combat.resolve_hit(null, target, {"base": {&"fire": 50.0}, "can_crit": false})
	expect_equal(result.barrier_absorbed, 30, "barrier absorption")
	expect_equal(result.life_damage, 20, "post-barrier life loss")
	# Explicit xorshift sequence proves seed reproducibility independent of engine RNG.
	var a := DeterministicRng.new(123456); var b := DeterministicRng.new(123456)
	var sequence_a := []; var sequence_b := []
	for i in 10: sequence_a.append(a.next_u32()); sequence_b.append(b.next_u32())
	expect_equal(sequence_a, sequence_b, "fixed-seed RNG sequence")
	expect_equal(sequence_a[0], 3044438244, "xorshift32 reference value")
	# Death and damage event are both observable.
	var death_target := DummyTarget.new(); death_target.life = 10; root.add_child(death_target)
	var observed := [false]
	combat.damage_resolved.connect(func(_target, _result): observed[0] = true)
	combat.resolve_hit(null, death_target, {"base": {&"physical": 20.0}, "can_crit": false})
	expect_equal(observed[0], true, "damage event emitted")
	expect_equal(death_target.died, true, "monster death callback")
	# DoT outgoing value is snapshotted while current target resistance remains dynamic.
	var snapshot: Dictionary = combat.create_dot_snapshot({"base": {&"fire": 20.0}, "increased": {&"fire": 50.0}, "duration_ms": 1100})
	expect_equal(snapshot.values[&"fire"], 30.0, "DoT outgoing snapshot")
	expect_equal(snapshot.duration_ms / snapshot.interval_ms, 2, "complete DoT tick count")
	for path in ["res://scenes/main.tscn", "res://scenes/player.tscn", "res://scenes/melee_enemy.tscn", "res://scenes/ranged_enemy.tscn", "res://scenes/projectile.tscn"]:
		expect_equal(load(path) != null, true, "resource loads: " + path)
	print("Combat test suite: %d failure(s)" % failures)
	quit(1 if failures else 0)
