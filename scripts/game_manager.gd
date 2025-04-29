extends Node2D

@onready var units_container = get_node("/root/world/Units")
@onready var tile_map = get_node("/root/world/TileMap")

var selected_unit: Unit = null
var player_units: Array[Unit] = []
enum TurnState { PLAYER_TURN, ENEMY_TURN }
var turn_state = TurnState.PLAYER_TURN

const HIGHLIGHT_LAYER = 1  # Слой для подсветки
const HIGHLIGHT_TILE_ID = 1  # ID тайла подсветки


func _ready():
	# Собираем всех юнитов игрока
	for child in units_container.get_children():
		if child is Unit:
			player_units.append(child)


func _unhandled_input(event):
	if turn_state != TurnState.PLAYER_TURN:
		return
	
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_global_mouse_position()

		var clicked_unit = get_unit_at_position(mouse_pos)
		if clicked_unit and not clicked_unit.has_moved:
			selected_unit = clicked_unit
			print("Выбран юнит:", selected_unit.name)
			show_movement_range(selected_unit)  # <--- ЭТО ДОБАВИТЬ
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
	
	# Проверка своих юнитов
	for unit in player_units:
		if unit != exclude:
			var cell = tile_map.local_to_map(unit.global_position)
			occupied.append(cell)
	
	# Проверка вражеских юнитов
	var enemy_units = get_node("/root/world/Enemys").get_children()
	for enemy in enemy_units:
		if enemy != exclude:
			var cell = tile_map.local_to_map(enemy.global_position)
			occupied.append(cell)
	
	return occupied


func end_player_turn():
	clear_highlight()
	for unit in player_units:
		unit.has_moved = false
	selected_unit = null
	turn_state = TurnState.ENEMY_TURN
	print("Ход врага")

	await get_tree().create_timer(1.0).timeout
	turn_state = TurnState.PLAYER_TURN
	print("Ход игрока")

func all_units_moved() -> bool:
	for unit in player_units:
		if not unit.has_moved:
			return false
	return true

func show_movement_range(unit: Unit) -> void:
	clear_highlight()
	var reachable = unit.get_reachable_cells()
	print("Клетки для подсветки:", reachable)

	var tile_set_id = 2
	var atlas_coords = Vector2i(9, 6)

	for cell in reachable:
		tile_map.set_cell(HIGHLIGHT_LAYER, cell, tile_set_id, atlas_coords)

func clear_highlight() -> void:
	tile_map.clear_layer(HIGHLIGHT_LAYER)
