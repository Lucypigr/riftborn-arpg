extends Node2D

@onready var player: RiftPlayer = $Player
@onready var director: RiftWorldDirector = $WorldDirector
@onready var portal: RiftPortal = $RiftPortal
@onready var life_bar: ProgressBar = $HUD/StatusPanel/Stack/Life
@onready var mana_bar: ProgressBar = $HUD/StatusPanel/Stack/Mana
@onready var state_label: Label = $HUD/TopBar/State
@onready var objective_label: Label = $HUD/Objective
@onready var inventory_label: Label = $HUD/InventoryPanel/Stack/Inventory
@onready var equipment_label: Label = $HUD/InventoryPanel/Stack/Equipped
@onready var skill_label: Label = $HUD/StatusPanel/Stack/Skills

func _ready() -> void:
	director.setup(player, portal)
	player.set_inventory(director.inventory)
	director.state_changed.connect(_on_state_changed)
	director.objective_changed.connect(_on_objective_changed)
	director.inventory.changed.connect(_refresh_inventory)
	player.health_changed.connect(_refresh_bars)
	player.mana_changed.connect(_refresh_bars)
	CombatSystem.damage_resolved.connect(_on_damage)
	_refresh_bars()
	_refresh_inventory()
	_on_state_changed("CAMP", "ASHEN CAMP")
	_on_objective_changed("Walk to the rift portal and press E to begin the breach.")

func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	skill_label.text = "LMB  RIFT CLEAVE  %s\nRMB / SPACE  ARC BOLT  %s" % [_cooldown(player.cooldown_ratio(&"basic")), _cooldown(player.cooldown_ratio(&"projectile"))]
	_refresh_bars()

func _cooldown(ratio: float) -> String:
	return "[READY]" if ratio <= 0.0 else "[%d%%]" % int(ceil(ratio * 100.0))

func _refresh_bars(_a = 0, _b = 0) -> void:
	life_bar.max_value = player.max_life
	life_bar.value = player.life
	mana_bar.max_value = player.max_mana
	mana_bar.value = player.mana

func _refresh_inventory() -> void:
	var lines := PackedStringArray()
	for index in mini(director.inventory.items.size(), 5):
		lines.append(director.inventory.slot_label(index))
	if lines.is_empty():
		lines.append("No loot yet. The Warden guards the first relic.")
	inventory_label.text = "\n".join(lines)
	var equipped := director.inventory.equipped_weapon
	equipment_label.text = "EQUIPPED\n%s\n%s" % [equipped.display_name, equipped.summary()] if equipped else "EQUIPPED\nNone"

func _on_state_changed(state: String, message: String) -> void:
	state_label.text = "%s  /  %s" % [message, state]

func _on_objective_changed(message: String) -> void:
	objective_label.text = message

func _on_damage(target: Node, result: Dictionary) -> void:
	if target == player:
		_refresh_bars()
	var popup := Label.new()
	popup.text = "%d%s" % [result.life_damage + result.barrier_absorbed, "  CRIT" if result.critical else ""]
	popup.modulate = Color("ffdb78") if result.critical else Color("f0f3ff")
	popup.position = target.global_position - Vector2(26, 58)
	add_child(popup)
	var tween := create_tween()
	tween.tween_property(popup, "position", popup.position - Vector2(0, 32), 0.5)
	tween.parallel().tween_property(popup, "modulate:a", 0.0, 0.5)
	tween.tween_callback(popup.queue_free)
