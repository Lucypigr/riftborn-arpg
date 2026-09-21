class_name RiftPlayer
extends CombatActor

@export var basic_skill: SkillData
@export var projectile_skill: SkillData
@export var projectile_scene: PackedScene
var cooldowns := {&"basic": 0.0, &"projectile": 0.0}
var aim_direction := Vector2.RIGHT
var spawn_position := Vector2.ZERO

func _ready() -> void:
	super._ready()
	faction = &"player"
	combat_stats["armour"] = 35
	combat_stats["resistance"] = {&"arcane": 10.0, &"fire": 10.0}
	combat_stats["increased"] = {&"global": 10.0, &"physical": 15.0, &"arcane": 20.0}
	spawn_position = global_position

func _physics_process(delta: float) -> void:
	for key in cooldowns: cooldowns[key] = maxf(0.0, cooldowns[key] - delta)
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input * move_speed
	move_and_slide()
	aim_direction = global_position.direction_to(get_global_mouse_position())
	rotation = aim_direction.angle()
	if Input.is_action_pressed("basic_attack"): use_basic()
	if Input.is_action_pressed("cast_projectile"): use_projectile()

func use_basic() -> void:
	if cooldowns[&"basic"] > 0.0: return
	cooldowns[&"basic"] = basic_skill.cooldown_seconds
	var nearest: CombatActor
	var nearest_distance := basic_skill.range_pixels
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if candidate.dead: continue
		var distance: float = global_position.distance_to(candidate.global_position)
		if distance <= nearest_distance and aim_direction.dot(global_position.direction_to(candidate.global_position)) > 0.25:
			nearest = candidate
			nearest_distance = distance
	if nearest: CombatSystem.resolve_hit(self, nearest, basic_skill.make_packet(combat_stats))

func use_projectile() -> void:
	if cooldowns[&"projectile"] > 0.0 or not spend_mana(projectile_skill.mana_cost): return
	cooldowns[&"projectile"] = projectile_skill.cooldown_seconds
	spawn_projectile(projectile_skill, aim_direction, &"player")

func spawn_projectile(skill: SkillData, direction: Vector2, owner_faction: StringName) -> void:
	var shot = projectile_scene.instantiate()
	shot.setup(self, skill, direction, owner_faction)
	get_tree().current_scene.add_child(shot)
	shot.global_position = global_position + direction * 28.0

func die() -> void:
	if dead: return
	super.die()
	await get_tree().create_timer(2.0).timeout
	global_position = spawn_position
	collision_layer = 2
	collision_mask = 1
	restore()

func cooldown_ratio(key: StringName) -> float:
	var skill := basic_skill if key == &"basic" else projectile_skill
	return cooldowns[key] / skill.cooldown_seconds
