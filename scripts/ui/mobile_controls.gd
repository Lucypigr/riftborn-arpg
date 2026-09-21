class_name RiftMobileControls
extends Control

var move_vector := Vector2.ZERO
var basic_pressed := false
var spell_pressed := false
var interact_pressed := false
var move_touch_id := -1
var move_origin := Vector2.ZERO
var move_current := Vector2.ZERO

func _ready() -> void:
	add_to_group("mobile_controls")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(true)

func consume_basic() -> bool:
	var value := basic_pressed
	basic_pressed = false
	return value

func consume_spell() -> bool:
	var value := spell_pressed
	spell_pressed = false
	return value

func consume_interact() -> bool:
	var value := interact_pressed
	interact_pressed = false
	return value

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_handle_touch_down(touch.index, touch.position)
		else:
			_handle_touch_up(touch.index)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == move_touch_id:
			move_current = drag.position
			move_vector = move_origin.direction_to(move_current) * minf(move_origin.distance_to(move_current) / 72.0, 1.0)
			queue_redraw()

func _handle_touch_down(index: int, position: Vector2) -> void:
	var viewport_size := get_viewport_rect().size
	if position.x < viewport_size.x * 0.45 and move_touch_id == -1:
		move_touch_id = index
		move_origin = position
		move_current = position
		return
	if position.x > viewport_size.x * 0.72:
		if position.y > viewport_size.y * 0.70:
			spell_pressed = true
		elif position.y > viewport_size.y * 0.48:
			basic_pressed = true
		else:
			interact_pressed = true

func _handle_touch_up(index: int) -> void:
	if index == move_touch_id:
		move_touch_id = -1
		move_vector = Vector2.ZERO
		queue_redraw()

func _draw() -> void:
	var size := get_viewport_rect().size
	if move_touch_id != -1:
		draw_circle(move_origin, 72.0, Color(0.15, 0.85, 0.95, 0.10))
		draw_circle(move_current, 28.0, Color(0.3, 0.9, 1.0, 0.32))
	if size.x < 900.0:
		draw_circle(Vector2(size.x - 116, size.y - 150), 48.0, Color(0.82, 0.28, 0.45, 0.35))
		draw_string(ThemeDB.fallback_font, Vector2(size.x - 160, size.y - 145), "ATTACK", HORIZONTAL_ALIGNMENT_CENTER, 88, 13, Color.WHITE)
		draw_circle(Vector2(size.x - 116, size.y - 58), 42.0, Color(0.35, 0.45, 1.0, 0.35))
		draw_string(ThemeDB.fallback_font, Vector2(size.x - 160, size.y - 53), "ARC", HORIZONTAL_ALIGNMENT_CENTER, 88, 13, Color.WHITE)
