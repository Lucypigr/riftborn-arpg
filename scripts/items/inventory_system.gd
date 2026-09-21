class_name RiftInventory
extends Node

signal changed
signal equipped_changed(item: RiftItemData)

const MAX_SLOTS := 12
var items: Array[RiftItemData] = []
var equipped_weapon: RiftItemData

func add_item(item: RiftItemData) -> bool:
	if items.size() >= MAX_SLOTS:
		return false
	items.append(item)
	changed.emit()
	return true

func equip_weapon(item: RiftItemData) -> bool:
	if item == null or not items.has(item):
		return false
	equipped_weapon = item
	equipped_changed.emit(item)
	changed.emit()
	return true

func has_item(item: RiftItemData) -> bool:
	return items.has(item)

func slot_label(index: int) -> String:
	if index < 0 or index >= items.size():
		return ""
	var item := items[index]
	var equipped := "  [EQUIPPED]" if item == equipped_weapon else ""
	return "%d. %s%s\n   %s" % [index + 1, item.display_name, equipped, item.summary()]
