class_name RiftEnemy
extends CombatActor

signal died_for_director(enemy: RiftEnemy)

enum Kind { MELEE, RANGED }
@export var kind := Kind.MELEE
@export var skill: SkillData
@export var projectile_scene: PackedScene
@export var preferred_distance := 300.0
@export var is_elite := false

var attack_cooldown := 0.0
var attack_windup := 0.0
var player: RiftPlayer
var attack_direction := Vector2.LEFT

func _ready() -> void:
	super._ready()
	faction = &"enemy"
	combat_stats["armour"] = 26 if kind == Kind.MELEE else 12
	combat_stats["resistance"] = {&"arcane": 5.0, &"fire": 0.0}
	if is_elite:
		combat_stats["armour"] = 48
		combat_stats["resistance"] = {&"arcane": 25.0, &"fire": 20.0}
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player") as RiftPlayer
	queue_redraw()

func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if attack_windup > 0.0:
		attack_windup -= delta
		if attack_windup <= 0.0:
			_resolve_attack()
		queue_redraw()
		return
	if not is_instance_valid(player) or player.dead:
		velocity = Vector2.ZERO
		return
	var distance := global_position.distance_to(player.global_position)
	var direction := global_position.direction_to(player.global_position)
	if kind == Kind.MELEE:
		velocity = direction * move_speed if distance > skill.range_pixels * 0.82 else Vector2.ZERO
		if distance <= skill.range_pixels:
			attack()
	else:
		if distance < preferred_distance * 0.72:
			velocity = -direction * move_speed
		elif distance > preferred_distance * 1.15:
			velocity = direction * move_speed
		else:
			velocity = Vector2.ZERO
		if distance <= skill.range_pixels:
			attack()
	move_and_slide()

func attack() -> void:
	if attack_cooldown > 0.0 or attack_windup > 0.0:
		return
	attack_cooldown = skill.cooldown_seconds
	attack_windup = 0.26 if kind == Kind.MELEE else 0.38
	attack_direction = global_position.direction_to(player.global_position)
	queue_redraw()

func _resolve_attack() -> void:
	if not is_instance_valid(player) or player.dead:
		return
	if kind == Kind.MELEE:
		if global_position.distance_to(player.global_position) <= skill.range_pixels + 12.0:
			CombatSystem.resolve_hit(self, player, skill.make_packet(combat_stats))
	else:
		var shot := projectile_scene.instantiate()
		shot.setup(self, skill, attack_direction, &"enemy")
		get_tree().current_scene.add_child(shot)
		shot.global_position = global_position + attack_direction * 26.0

func die() -> void:
	if dead:
		return
	super.die()
	died_for_director.emit(self)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.28)
	await get_tree().create_timer(0.45).timeout
	queue_free()

func _draw() -> void:
	var width := 76.0 if is_elite else 48.0
	var bar_y := -70.0 if is_elite else -52.0
	var health_ratio := clampf(float(life) / float(max_life), 0.0, 1.0)
	draw_rect(Rect2(-width * 0.5, bar_y, width, 5.0), Color(0.05, 0.04, 0.08, 0.9))
	draw_rect(Rect2(-width * 0.5, bar_y, width * health_ratio, 5.0), Color("d36dff") if is_elite else Color("e45b68"))
	if is_elite:
		draw_arc(Vector2.ZERO, 44.0, 0.0, TAU, 32, Color(0.78, 0.35, 1.0, 0.55), 3.0)
	if attack_windup > 0.0:
		draw_arc(Vector2.ZERO, 42.0, attack_direction.angle() - 0.45, attack_direction.angle() + 0.45, 12, Color(1.0, 0.35, 0.3, 0.75), 4.0)
