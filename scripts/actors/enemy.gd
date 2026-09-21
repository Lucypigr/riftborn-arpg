class_name RiftEnemy
extends CombatActor

enum Kind { MELEE, RANGED }
@export var kind := Kind.MELEE
@export var skill: SkillData
@export var projectile_scene: PackedScene
@export var preferred_distance := 300.0
var attack_cooldown := 0.0
var player: RiftPlayer

func _ready() -> void:
	super._ready()
	faction = &"enemy"
	combat_stats["armour"] = 18 if kind == Kind.MELEE else 8
	combat_stats["resistance"] = {&"arcane": 5.0, &"fire": 0.0}
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if not is_instance_valid(player) or player.dead:
		velocity = Vector2.ZERO; return
	var distance := global_position.distance_to(player.global_position)
	var direction := global_position.direction_to(player.global_position)
	if kind == Kind.MELEE:
		velocity = direction * move_speed if distance > skill.range_pixels * 0.8 else Vector2.ZERO
		if distance <= skill.range_pixels: attack()
	else:
		if distance < preferred_distance * 0.7: velocity = -direction * move_speed
		elif distance > preferred_distance * 1.2: velocity = direction * move_speed
		else: velocity = Vector2.ZERO
		if distance <= skill.range_pixels: attack()
	move_and_slide()

func attack() -> void:
	if attack_cooldown > 0.0: return
	attack_cooldown = skill.cooldown_seconds
	if kind == Kind.MELEE:
		CombatSystem.resolve_hit(self, player, skill.make_packet(combat_stats))
	else:
		var shot = projectile_scene.instantiate()
		shot.setup(self, skill, global_position.direction_to(player.global_position), &"enemy")
		get_tree().current_scene.add_child(shot)
		shot.global_position = global_position + global_position.direction_to(player.global_position) * 24.0

func die() -> void:
	if dead: return
	super.die()
	await get_tree().create_timer(0.7).timeout
	queue_free()
