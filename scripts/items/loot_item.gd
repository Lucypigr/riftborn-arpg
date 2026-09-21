class_name RiftLootItem
extends Area2D

signal picked_up(item: RiftItemData)

var item_data: RiftItemData
var pulse := 0.0
var nearby := false

func setup(data: RiftItemData) -> void:
	item_data = data
	queue_redraw()

func _ready() -> void:
	monitoring = true
	queue_redraw()

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()
	var player := get_tree().get_first_node_in_group("player") as RiftPlayer
	if not is_instance_valid(player) or player.dead:
		return
	nearby = global_position.distance_to(player.global_position) <= 52.0
	if nearby and Input.is_action_just_pressed("interact"):
		picked_up.emit(item_data)
		queue_free()

func _draw() -> void:
	var color := item_data.rarity_color() if item_data else Color("f5c451")
	var glow := 0.55 + sin(pulse * 4.0) * 0.2
	draw_circle(Vector2.ZERO, 20.0 + sin(pulse * 3.0) * 2.0, Color(color, glow * 0.22))
	draw_circle(Vector2.ZERO, 8.0, Color(color, 0.9))
	draw_circle(Vector2.ZERO, 3.0, Color.WHITE)
	if nearby:
		draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 24, Color.WHITE, 2.0)
