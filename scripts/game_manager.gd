extends Node2D

@onready var selected_unit: Unit = null # Выбранный игроком юнит

@onready var player_units: Array[Unit] = [] # Все юнит игрока

@onready var turn_state = TurnState.PLAYER_TURN # Отслеживание хода, игрок или враг

var units_container: Node = null # Хранятся все юниты поля

var tile_map: TileMap = null # TileMap (рассчитывается движение и позиции)

enum TurnState { PLAYER_TURN, ENEMY_TURN } # Перечисление состояний хода

const HIGHLIGHT_LAYER = 1 # слой подсветки

# Функция готода для начала игры
func _ready():
	call_deferred("start_game")


func start_game():
	# Пока узлы Units и TileMap не существуют в дереве сцены — ждём. 
	while not get_node_or_null("/root/world/Units") or not get_node_or_null("/root/world/TileMap"):
		await get_tree().process_frame  # ждём один кадр перед следующей проверкой

	# Когда нужные узлы появились — сохраняем ссылки на них
	units_container = get_node("/root/world/Units")
	tile_map = get_node("/root/world/TileMap")

	# Добавляем в список player_units только объекты типа Unit из узла Units
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
			show_movement_range(selected_unit)
			return


		# Если юнит выбран — попытка переместить его
		if selected_unit:
			var tile = tile_map.local_to_map(mouse_pos)
			
			# Проверка — есть ли враг в этой клетке
			var enemy_units = get_node("/root/world/Enemys").get_children()
			for enemy in enemy_units:
				var enemy_cell = tile_map.local_to_map(enemy.global_position)
				
				if enemy_cell == tile and selected_unit.can_attack(enemy):
					selected_unit.attack(enemy)
					selected_unit.has_moved = true
					clear_highlight()
					selected_unit = null
					if all_units_moved():
						end_player_turn()
					return

			# Если врага нет — попробовать двигаться
			selected_unit.try_move_to(tile)



func get_unit_at_position(pos: Vector2) -> Unit:
	for unit in player_units:
		if not is_instance_valid(unit):
			continue  # Юнит уже удалён — пропускаем

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
	player_units = player_units.filter(func(u): return is_instance_valid(u))

	var occupied: Array[Vector2i] = []

	# Проверка своих юнитов
	for unit in player_units:
		if unit != exclude and is_instance_valid(unit):
			var cell = tile_map.local_to_map(unit.global_position)
			occupied.append(cell)

	# Проверка вражеских юнитов
	var enemy_units = get_node("/root/world/Enemys").get_children()
	for enemy in enemy_units:
		if enemy != exclude and is_instance_valid(enemy):
			var cell = tile_map.local_to_map(enemy.global_position)
			occupied.append(cell)

	return occupied


func end_player_turn():
	clear_highlight()
	
	# Проверяем ловушки для каждого юнита игрока
	for unit in player_units:
		if unit is Unit and is_instance_valid(unit):
			unit.check_for_traps()

	selected_unit = null # Снимаем выделение
	turn_state = TurnState.ENEMY_TURN
	print("Ход врага")

	process_enemy_turn()



func process_enemy_turn():
	await get_tree().create_timer(0.5).timeout

	var enemy_units = get_node("/root/world/Enemys").get_children()
	for enemy in enemy_units:
		if enemy is Unit and is_instance_valid(enemy):
			await enemy.make_turn()
		else:
			pass
	
	var all_units = player_units + get_node("/root/world/Enemys").get_children()
	for unit in all_units:
		if is_instance_valid(unit) and unit is Unit:
			unit.has_moved = false
	
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

	var tile_set_id = 0
	var atlas_coords = Vector2i(2, 23)

	for cell in reachable:
		tile_map.set_cell(HIGHLIGHT_LAYER, cell, tile_set_id, atlas_coords)

func clear_highlight() -> void:
	tile_map.clear_layer(HIGHLIGHT_LAYER)

func wait_until_enemies_done():
	while true:
		var enemies_moving = false
		for enemy in get_node("/root/world/Enemys").get_children():
			if enemy is Unit and enemy.is_moving:
				enemies_moving = true
				break
		if not enemies_moving:
			break
		await get_tree().process_frame

func remove_unit(unit: Unit) -> void:
	player_units.erase(unit)

@onready var layer_end = get_node("/root/world/layer_end")

func check_game_over():
	var player_alive = player_units.any(func(u): return is_instance_valid(u) and u.health > 0)
	var enemy_alive = get_node("/root/world/Enemys").get_children().any(func(u): return u is Unit and is_instance_valid(u) and u.health > 0)

	if not player_alive or not enemy_alive:
		show_game_over_message(player_alive)

func show_game_over_message(player_won: bool):
	var layer = get_node("/root/world/layer_end")
	
	var label = layer.get_node("GameOverLabel")
	
	label.text = "Игра окончена"
	label.global_position = tile_map.map_to_local(Vector2i(1, 3))
	label.visible = true
	
	set_process_input(false)
	
	await get_tree().create_timer(2.0).timeout
	
	get_tree().quit()
