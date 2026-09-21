class_name RiftPlayer
extends CombatActor

@export var basic_skill: SkillData
@export var projectile_skill: SkillData
@export var projectile_scene: PackedScene

var cooldowns := {&"basic": 0.0, &"projectile": 0.0}
var aim_direction := Vector2.RIGHT
var spawn_position := Vector2.ZERO
var attack_windup := 0.0
var attack_direction := Vector2.RIGHT
var inventory: RiftInventory
var mobile_controls: RiftMobileControls
var base_increased := {&"global": 10.0, &"physical": 15.0, &"arcane": 20.0}

func _ready() -> void:
	super._ready()
	faction = &"player"
	combat_stats["armour"] = 35
	combat_stats["resistance"] = {&"arcane": 10.0, &"fire": 10.0}
	spawn_position = global_position
	mobile_controls = get_tree().get_first_node_in_group("mobile_controls") as RiftMobileControls
	queue_redraw()

func _physics_process(delta: float) -> void:
	for key in cooldowns:
		cooldowns[key] = maxf(0.0, cooldowns[key] - delta)
	if attack_windup > 0.0:
		attack_windup -= delta
		if attack_windup <= 0.0:
			_resolve_melee_hit()
		queue_redraw()
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if is_instance_valid(mobile_controls) and mobile_controls.move_vector.length() > 0.05:
		input = mobile_controls.move_vector
	velocity = input * move_speed
	move_and_slide()
	if not is_instance_valid(mobile_controls):
		mobile_controls = get_tree().get_first_node_in_group("mobile_controls") as RiftMobileControls
	aim_direction = global_position.direction_to(get_global_mouse_position())
	if aim_direction.length_squared() > 0.01:
		rotation = aim_direction.angle()
	if Input.is_action_just_pressed("basic_attack") or _consume_mobile_basic():
		start_basic()
	if Input.is_action_just_pressed("cast_projectile") or _consume_mobile_spell():
		use_projectile()

func _consume_mobile_basic() -> bool:
	return is_instance_valid(mobile_controls) and mobile_controls.consume_basic()

func _consume_mobile_spell() -> bool:
	return is_instance_valid(mobile_controls) and mobile_controls.consume_spell()

func start_basic() -> void:
	if dead or cooldowns[&"basic"] > 0.0 or attack_windup > 0.0:
		return
	cooldowns[&"basic"] = basic_skill.cooldown_seconds
	attack_windup = 0.11
	attack_direction = aim_direction
	queue_redraw()

func _resolve_melee_hit() -> void:
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(candidate) or candidate.dead:
			continue
		var offset: Vector2 = candidate.global_position - global_position
		if offset.length() <= basic_skill.range_pixels and attack_direction.dot(offset.normalized()) > 0.18:
			CombatSystem.resolve_hit(self, candidate, basic_skill.make_packet(combat_stats))
	queue_redraw()

func use_projectile() -> void:
	if dead or cooldowns[&"projectile"] > 0.0 or not spend_mana(projectile_skill.mana_cost):
		return
	cooldowns[&"projectile"] = projectile_skill.cooldown_seconds
	spawn_projectile(projectile_skill, aim_direction, &"player")

func spawn_projectile(skill: SkillData, direction: Vector2, owner_faction: StringName) -> void:
	var shot := projectile_scene.instantiate()
	shot.setup(self, skill, direction, owner_faction)
	get_tree().current_scene.add_child(shot)
	shot.global_position = global_position + direction * 28.0

func set_inventory(new_inventory: RiftInventory) -> void:
	inventory = new_inventory
	if not inventory.equipped_changed.is_connected(_on_equipment_changed):
		inventory.equipped_changed.connect(_on_equipment_changed)
	_refresh_equipment()

func _on_equipment_changed(_item: RiftItemData) -> void:
	_refresh_equipment()

func _refresh_equipment() -> void:
	var increased := base_increased.duplicate()
	var life_bonus := 0
	if is_instance_valid(inventory) and inventory.equipped_weapon:
		increased[&"global"] += inventory.equipped_weapon.damage_bonus
		life_bonus = inventory.equipped_weapon.life_bonus
	combat_stats["increased"] = increased
	max_life = 180 + life_bonus
	life = mini(life, max_life)
	health_changed.emit(life, max_life)

func die() -> void:
	if dead:
		return
	super.die()
	await get_tree().create_timer(2.0).timeout
	global_position = spawn_position
	collision_layer = 2
	collision_mask = 1
	restore()

func cooldown_ratio(key: StringName) -> float:
	var skill := basic_skill if key == &"basic" else projectile_skill
	return cooldowns[key] / skill.cooldown_seconds

func _draw() -> void:
	if attack_windup > 0.0:
		var progress := 1.0 - attack_windup / 0.11
		draw_arc(Vector2.ZERO, 78.0 + progress * 12.0, -0.7, 0.7, 20, Color(0.72, 0.38, 1.0, 0.85), 7.0)
