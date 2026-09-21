class_name DeterministicRng
extends RefCounted

const MASK: int = 0xffffffff
const ZERO_SEED: int = 0x6d2b79f5
var state: int

func _init(seed_value: int = ZERO_SEED) -> void:
	state = (seed_value & MASK) if (seed_value & MASK) != 0 else ZERO_SEED

func next_u32() -> int:
	var value := state
	value = (value ^ ((value << 13) & MASK)) & MASK
	value = (value ^ (value >> 17)) & MASK
	value = (value ^ ((value << 5) & MASK)) & MASK
	state = value
	return value

func roll_percent(chance: float) -> bool:
	var bounded := clampf(chance, 0.0, 100.0)
	var threshold := int(floor(bounded * 4294967296.0 / 100.0))
	return next_u32() < threshold
