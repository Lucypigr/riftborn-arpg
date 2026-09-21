extends Area2D

var source: CombatActor
var skill: SkillData
var direction := Vector2.RIGHT
var speed := 500.0
var owner_faction := &"neutral"
var travelled := 0.0

func setup(new_source: CombatActor, new_skill: SkillData, new_direction: Vector2, new_faction: StringName) -> void:
	source = new_source
	skill = new_skill
	direction = new_direction.normalized()
	speed = skill.projectile_speed
	owner_faction = new_faction
	if owner_faction == &"player":
		collision_layer = 8; collision_mask = 4
	else:
		collision_layer = 16; collision_mask = 2

func _physics_process(delta: float) -> void:
	var movement := direction * speed * delta
	position += movement
	travelled += movement.length()
	if travelled >= skill.range_pixels: queue_free()
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if body is CombatActor and body.faction != owner_faction and not body.dead:
		CombatSystem.resolve_hit(source, body, skill.make_packet(source.combat_stats))
		queue_free()

func _draw() -> void:
	var color := Color("ff945e") if owner_faction == &"enemy" else Color("75f0ff")
	draw_circle(Vector2.ZERO, 15.0, Color(color, 0.16))
	draw_circle(Vector2.ZERO, 6.0, color)
	draw_circle(Vector2.ZERO, 2.0, Color.WHITE)
