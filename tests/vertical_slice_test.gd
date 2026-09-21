extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("run")

func expect_equal(actual, expected, label: String) -> void:
	if actual != expected:
		failures += 1
		printerr("FAIL %s: expected %s, got %s" % [label, expected, actual])
	else:
		print("PASS ", label)

func run() -> void:
	var inventory_script: GDScript = load("res://scripts/items/inventory_system.gd")
	var item_script: GDScript = load("res://scripts/items/item_data.gd")
	var inventory: RiftInventory = inventory_script.new()
	var item: RiftItemData = item_script.new()
	root.add_child(inventory)
	item.display_name = "Test Rift Blade"
	item.damage_bonus = 12.0
	item.life_bonus = 20
	expect_equal(inventory.add_item(item), true, "inventory accepts item")
	expect_equal(inventory.equip_weapon(item), true, "inventory equips weapon")
	expect_equal(inventory.equipped_weapon.damage_bonus, 12.0, "equipped weapon bonus")
	expect_equal(item.summary(), "+12% damage, +20 life", "item summary")
	for path in [
		"res://scenes/main.tscn",
		"res://scenes/elite_enemy.tscn",
		"res://scenes/loot_item.tscn",
		"res://scenes/portal.tscn"
	]:
		expect_equal(load(path) != null, true, "vertical slice resource loads: " + path)
	print("Vertical slice test suite: %d failure(s)" % failures)
	quit(1 if failures else 0)
