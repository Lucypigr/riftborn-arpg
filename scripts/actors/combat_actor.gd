class_name CombatActor
extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal mana_changed(current: int, maximum: int)
signal actor_died(actor: Node)

@export var max_life := 100
@export var max_mana := 50
@export var move_speed := 220.0
@export var faction := &"neutral"
var life := 100
var mana := 50
var barrier := 0
var dead := false
var combat_stats := {
	"level": 1, "armour": 0, "resistance": {&"arcane": 0.0, &"fire": 0.0},
	"damage_taken": {}, "increased": {}, "crit_chance": 5.0, "crit_multiplier": 150.0,
}

func _ready() -> void:
	life = max_life
	mana = max_mana

func spend_mana(amount: int) -> bool:
	if mana < amount: return false
	mana -= amount
	mana_changed.emit(mana, max_mana)
	return true

func flash_hit() -> void:
	modulate = Color("fff1d4")
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.12)

func die() -> void:
	if dead: return
	dead = true
	actor_died.emit(self)
	set_physics_process(false)
	visible = false
	collision_layer = 0
	collision_mask = 0

func restore() -> void:
	dead = false
	life = max_life
	mana = max_mana
	barrier = 0
	visible = true
	set_physics_process(true)
	health_changed.emit(life, max_life)
	mana_changed.emit(mana, max_mana)
