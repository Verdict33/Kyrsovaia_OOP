class_name Trap
extends Node2D

var damage = 0.2

@onready var tile_map = get_node("/root/world/TileMap")

var trap_cell: Vector2i


# Инициализация клетки с ловушкой
func _ready():
	trap_cell = tile_map.local_to_map(global_position)


# Проверяет стал ли юнит на клетку с ловушкой
func check_trigger(unit: Unit):
	if not is_instance_valid(unit):
		return
	
	var unit_cell = tile_map.local_to_map(unit.global_position)
	if unit_cell == trap_cell:
		unit.take_damage(unit.max_health * damage)
		queue_free()
