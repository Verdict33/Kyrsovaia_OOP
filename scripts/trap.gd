class_name Trap
extends Node2D

@export var damage: int = 10
@onready var tile_map = get_node("/root/world/TileMap")

var trap_cell: Vector2i

func _ready():
	trap_cell = tile_map.local_to_map(global_position)

func check_trigger(unit: Unit) -> void:
	if not is_instance_valid(unit):
		return

	var unit_cell = tile_map.local_to_map(unit.global_position)
	if unit_cell == trap_cell:
		unit.take_damage(damage)
		queue_free()
