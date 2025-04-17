extends Node2D

@onready var units_container = get_node("/root/world/Units")
@onready var tile_map = get_node("/root/world/TileMap")

var selected_unit: Unit = null
var player_units: Array[Unit] = []

func _ready():
	# Собираем всех юнитов игрока
	for child in units_container.get_children():
		if child is Unit:
			player_units.append(child)


func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_global_mouse_position()

		# Попробовать выбрать юнита
		var clicked_unit = get_unit_at_position(mouse_pos)
		if clicked_unit and not clicked_unit.is_moving:
			selected_unit = clicked_unit
			print("Выбран юнит:", selected_unit.name)
			return

		# Если юнит выбран — попытка переместить его
		if selected_unit:
			var tile = tile_map.local_to_map(mouse_pos)
			selected_unit.try_move_to(tile)


func get_unit_at_position(pos: Vector2) -> Unit:
	for unit in player_units:
		var sprite = unit.get_node("Sprite2D")
		if sprite:
			var rect = Rect2(
				unit.global_position - sprite.texture.get_size() * 0.5 * unit.scale,
				sprite.texture.get_size() * unit.scale
			)
			if rect.has_point(pos):
				return unit
	return null


func select_unit(unit: Unit) -> void:
	if unit.is_moving:
		return
	selected_unit = unit

func get_occupied_cells(exclude: Unit) -> Array[Vector2i]:
	var occupied: Array[Vector2i] = []
	for unit in player_units:
		if unit != exclude:
			var cell = tile_map.local_to_map(unit.global_position)
			occupied.append(cell)
	return occupied
