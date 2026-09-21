class_name RiftWorldDirector
extends Node2D

signal state_changed(state: String, message: String)
signal objective_changed(message: String)
signal loot_created(item: RiftItemData)

enum State { CAMP, DUNGEON, CLEARED }
const MELEE_SCENE := preload("res://scenes/melee_enemy.tscn")
const RANGED_SCENE := preload("res://scenes/ranged_enemy.tscn")
const ELITE_SCENE := preload("res://scenes/elite_enemy.tscn")
const LOOT_SCENE := preload("res://scenes/loot_item.tscn")

var state := State.CAMP
var wave := 0
var enemies_alive := 0
var player: RiftPlayer
var inventory: RiftInventory
var portal: RiftPortal
var cleared := false

func setup(new_player: RiftPlayer, new_portal: RiftPortal) -> void:
	player = new_player
	portal = new_portal
	inventory = RiftInventory.new()
	inventory.name = "Inventory"
	add_child(inventory)

func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	if Input.is_action_just_pressed("interact") or _mobile_interact():
		interact()
	if state == State.DUNGEON and enemies_alive == 0 and not cleared:
		if wave < 2:
			_spawn_wave(wave + 1)
		elif get_tree().get_nodes_in_group("enemies").is_empty():
			_spawn_elite()

func _mobile_interact() -> bool:
	var controls := get_tree().get_first_node_in_group("mobile_controls") as RiftMobileControls
	return is_instance_valid(controls) and controls.consume_interact()

func interact() -> void:
	if state == State.CAMP and player.global_position.distance_to(portal.global_position) < 120.0:
		_enter_dungeon()
	elif state == State.CLEARED and player.global_position.distance_to(portal.global_position) < 120.0:
		_return_to_camp()

func _enter_dungeon() -> void:
	state = State.DUNGEON
	wave = 0
	cleared = false
	portal.active = false
	player.global_position = Vector2(640, 390)
	objective_changed.emit("Rift breach: clear two waves and defeat the elite Warden.")
	_spawn_wave(1)
	state_changed.emit("DUNGEON", "ASHEN RIFT")

func _return_to_camp() -> void:
	state = State.CAMP
	cleared = false
	portal.active = true
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	for drop in get_tree().get_nodes_in_group("loot"):
		drop.queue_free()
	player.global_position = Vector2(320, 380)
	objective_changed.emit("Camp restored. Walk to the rift when you are ready.")
	state_changed.emit("CAMP", "ASHEN CAMP")

func _spawn_wave(number: int) -> void:
	wave = number
	var melee_count := 5 if number == 1 else 7
	var ranged_count := 2 if number == 1 else 3
	var positions := _spawn_positions(melee_count + ranged_count)
	for index in melee_count:
		_spawn_enemy(MELEE_SCENE, positions[index], false)
	for index in ranged_count:
		_spawn_enemy(RANGED_SCENE, positions[melee_count + index], false)
	enemies_alive = melee_count + ranged_count
	objective_changed.emit("Wave %d/2 — %d enemies remain." % [number, enemies_alive])

func _spawn_elite() -> void:
	cleared = true
	_spawn_enemy(ELITE_SCENE, Vector2(980, 360), true)
	enemies_alive = 1
	objective_changed.emit("ELITE WARDEN — break its guard and claim the relic.")

func _spawn_enemy(scene: PackedScene, position: Vector2, elite: bool) -> void:
	var enemy := scene.instantiate() as RiftEnemy
	enemy.global_position = position
	enemy.is_elite = elite
	enemy.died_for_director.connect(_on_enemy_died)
	add_child(enemy)

func _spawn_positions(count: int) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for index in count:
		var angle := TAU * float(index) / float(count)
		result.append(Vector2(640, 390) + Vector2(cos(angle), sin(angle)) * 250.0)
	return result

func _on_enemy_died(enemy: RiftEnemy) -> void:
	enemies_alive = maxi(enemies_alive - 1, 0)
	var item := _make_drop(enemy.is_elite)
	_spawn_loot(enemy.global_position, item)
	if enemies_alive > 0 and state == State.DUNGEON and not cleared:
		objective_changed.emit("Wave %d/2 — %d enemies remain." % [wave, enemies_alive])
	elif cleared and enemies_alive == 0:
		state = State.CLEARED
		portal.active = true
		objective_changed.emit("Warden defeated. Pick up the relic, then return to the rift.")
		state_changed.emit("CLEARED", "RIFT SECURED")

func _make_drop(elite: bool) -> RiftItemData:
	var item := RiftItemData.new()
	if elite:
		item.item_id = "wardens_echo"
		item.display_name = "Warden's Echo"
		item.rarity = "Elite"
		item.damage_bonus = 28.0
		item.life_bonus = 40
		item.description = "A shard of the elite's broken guard."
		item.tint = Color("d36dff")
	else:
		item.item_id = "riftbound_blade_%d" % randi_range(1, 9999)
		item.display_name = "Riftbound Blade"
		item.rarity = "Rare" if randf() > 0.58 else "Common"
		item.damage_bonus = 10.0 if item.rarity == "Rare" else 5.0
		item.life_bonus = 10 if item.rarity == "Rare" else 0
		item.description = "A field-forged weapon touched by the breach."
		item.tint = item.rarity_color()
	return item

func _spawn_loot(position: Vector2, item: RiftItemData) -> void:
	var drop := LOOT_SCENE.instantiate() as RiftLootItem
	drop.global_position = position
	drop.setup(item)
	drop.picked_up.connect(_on_loot_picked)
	add_child(drop)
	loot_created.emit(item)

func _on_loot_picked(item: RiftItemData) -> void:
	if inventory.add_item(item):
		inventory.equip_weapon(item)
		if is_instance_valid(player):
			player.set_inventory(inventory)
		objective_changed.emit("Equipped %s — %s" % [item.display_name, item.summary()])
