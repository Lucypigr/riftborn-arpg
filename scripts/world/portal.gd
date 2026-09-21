class_name RiftPortal
extends Area2D

var active := true
var pulse := 0.0

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func _draw() -> void:
	var radius := 34.0 + sin(pulse * 2.3) * 3.0
	var violet := Color("9c5cff") if active else Color("4d5264")
	draw_circle(Vector2.ZERO, radius + 12.0, Color(violet, 0.10))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(violet, 0.9), 4.0)
	draw_arc(Vector2.ZERO, radius - 10.0, pulse, pulse + PI * 1.35, 28, Color("5ee9ff", 0.75), 3.0)
	draw_circle(Vector2.ZERO, radius * 0.54, Color("1d1235", 0.82))
	if active:
		draw_string(ThemeDB.fallback_font, Vector2(-48, 62), "E  ENTER RIFT", HORIZONTAL_ALIGNMENT_CENTER, 96, 14, Color("d9ccff"))
