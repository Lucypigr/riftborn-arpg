extends Node2D

@onready var player: RiftPlayer = $Player
@onready var life_bar: ProgressBar = $HUD/Margin/VBox/Life
@onready var mana_bar: ProgressBar = $HUD/Margin/VBox/Mana
@onready var skill_label: Label = $HUD/Margin/VBox/Skills
@onready var status_label: Label = $HUD/Title

func _ready() -> void:
	player.health_changed.connect(_update_hud.bind())
	player.mana_changed.connect(_update_hud.bind())
	player.actor_died.connect(_on_player_died)
	CombatSystem.damage_resolved.connect(_on_damage)
	_update_hud()

func _process(_delta: float) -> void:
	life_bar.value = player.life
	mana_bar.value = player.mana
	skill_label.text = "LMB  Rift Cleave  %s\nRMB / Space  Arc Bolt  %s" % [_cooldown(player.cooldown_ratio(&"basic")), _cooldown(player.cooldown_ratio(&"projectile"))]

func _cooldown(ratio: float) -> String:
	return "[READY]" if ratio <= 0.0 else "[%d%%]" % int(ceil(ratio * 100.0))

func _update_hud(_a = 0, _b = 0) -> void:
	life_bar.max_value = player.max_life; life_bar.value = player.life
	mana_bar.max_value = player.max_mana; mana_bar.value = player.mana

func _on_player_died(_actor: Node) -> void:
	status_label.text = "THE RIFT CLAIMS YOU — returning in 2 seconds"
	await get_tree().create_timer(2.1).timeout
	status_label.text = "RIFTBORN  •  Ashen Training Ground"

func _on_damage(target: Node, result: Dictionary) -> void:
	if target == player: player.health_changed.emit(player.life, player.max_life)
	var popup := Label.new()
	popup.text = "%d%s" % [result.life_damage + result.barrier_absorbed, " CRIT" if result.critical else ""]
	popup.modulate = Color("ffdc73") if result.critical else Color.WHITE
	popup.global_position = target.global_position - Vector2(15, 45)
	add_child(popup)
	var tween := create_tween()
	tween.tween_property(popup, "position", popup.position - Vector2(0, 35), 0.55)
	tween.parallel().tween_property(popup, "modulate:a", 0.0, 0.55)
	tween.tween_callback(popup.queue_free)
