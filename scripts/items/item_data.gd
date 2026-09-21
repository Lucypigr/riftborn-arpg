class_name RiftItemData
extends Resource

@export var item_id := ""
@export var display_name := "Unknown Relic"
@export var rarity := "Common"
@export var required_level := 1
@export var damage_bonus := 0.0
@export var life_bonus := 0
@export var description := ""
@export var tint := Color.WHITE

func rarity_color() -> Color:
	match rarity:
		"Rare": return Color("f5c451")
		"Elite": return Color("d36dff")
		_: return Color("b7c5cf")

func summary() -> String:
	var damage_text := "+%d%% damage" % int(damage_bonus) if damage_bonus > 0.0 else ""
	var life_text := "+%d life" % life_bonus if life_bonus > 0 else ""
	if not damage_text.is_empty() and not life_text.is_empty():
		return "%s, %s" % [damage_text, life_text]
	return damage_text if not damage_text.is_empty() else life_text
