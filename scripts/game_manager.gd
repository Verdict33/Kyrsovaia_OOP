extends Node2D

@onready var selected_unit: Unit = null # Выбранный игроком юнит

@onready var player_units: Array[Unit] = [] # Все юнит игрока

@onready var turn_state = TurnState.PLAYER_TURN # Отслеживание хода, игрок или враг

var units_container: Node = null # Хранятся все юниты поля

var tile_map: TileMap = null # TileMap (рассчитывается движение и позиции)

enum TurnState { PLAYER_TURN, ENEMY_TURN } # Перечисление состояний хода


# Функция готода для начала игры
func _ready():
	call_deferred("start_game")


func start_game():
	# Ждем пока узлы Units и TileMap не существуют в дереве сцены
	while not get_node_or_null("/root/world/Units") or not get_node_or_null("/root/world/TileMap"):
		await get_tree().process_frame  # один кадр перед следующей проверкой
	
	# Сохраняем ссылки на нужные узлы
	units_container = get_node("/root/world/Units")
	tile_map = get_node("/root/world/TileMap")
	Highligt.setup(tile_map)
	
	# Добавляем в список player_units только объекты типа Unit из узла Units
	for child in units_container.get_children():
		if child is Unit:
			player_units.append(child)


# Ввод мыши игрока во время хода игрока
func _unhandled_input(event):
	if turn_state != TurnState.PLAYER_TURN:
		return
	
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_global_mouse_position()
		
		var clicked_unit = get_unit_at_position(mouse_pos)
		
		if clicked_unit and not clicked_unit.has_moved:
			Highligt.clear_attack_highlight()
			selected_unit = clicked_unit
			print("Выбран юнит:", selected_unit.name)
			Highligt.show_movement_range(selected_unit.get_reachable_cells())
			Highligt.show_attack_targets(selected_unit, get_node("/root/world/Enemys").get_children())
			return
		
		# Если юнит выбран, попытка переместить его
		if selected_unit:
			var tile = tile_map.local_to_map(mouse_pos)
			
			# Есть ли враг в этой клетке
			var enemy_units = get_node("/root/world/Enemys").get_children()
			for enemy in enemy_units:
				var enemy_cell = tile_map.local_to_map(enemy.global_position)
				
				if enemy_cell == tile and selected_unit.can_attack(enemy):
					selected_unit.attack(enemy)
					selected_unit.has_moved = true
					selected_unit = null
					if all_units_moved():
						end_player_turn()
					return
			
			# Двигаемся, если врага нет
			selected_unit.try_move_to(tile)


# Возвращает юнита игрока, находящегося под указанной позицией мыши
func get_unit_at_position(pos: Vector2):
	for unit in player_units:
		if not is_instance_valid(unit):
			continue
		
		# Получаем спрайт юнита
		var sprite = unit.get_node("Sprite2D")
		if sprite:
			# Вычисляем прямоугольник спрайта юнита в мировых координатах
			var rect = Rect2(
				unit.global_position - sprite.texture.get_size() * 0.5 * unit.scale,
				sprite.texture.get_size() * unit.scale
			)
			
			# Если позиция мыши попадает в прямоугольник, то возвращаем юнита
			if rect.has_point(pos):
				return unit
	
	return null


# Возвращает массив занятых клеток на карте, исключает клетку указанного юнита
func get_occupied_cells(exclude: Unit):
	# Очищаем список от удалённых юнитов
	player_units = player_units.filter(func(unit): return is_instance_valid(unit))
	
	# Пустой массив для хранения занятых клеток
	var occupied: Array[Vector2i] = []
	
	# Проверка занятых клеток союзниками
	for unit in player_units:
		# Исключаем переданного юнита и проверка, что юнит ещё существует
		if unit != exclude and is_instance_valid(unit):
			# Получаем клетку с юнитом
			var cell = tile_map.local_to_map(unit.global_position)
			occupied.append(cell)

	# Те же действия для вражеских юнитов
	var enemy_units = get_node("/root/world/Enemys").get_children()
	for enemy in enemy_units:
		if enemy != exclude and is_instance_valid(enemy):
			var cell = tile_map.local_to_map(enemy.global_position)
			occupied.append(cell)
	
	# Список всех занятых клеток
	return occupied


# Завершает ход игрока и начинает ход врага
func end_player_turn():
	# Проверка ловушек для каждого юнита игрока
	for unit in player_units:
		if unit is Unit and is_instance_valid(unit):
			unit.check_for_traps()
	
	# Снимаем выделение с активного юнита
	selected_unit = null
	
	# Очищаем подсветку движения
	Highligt.clear_highlight()
	
	turn_state = TurnState.ENEMY_TURN
	process_enemy_turn()


# Обрабатывает ход врагов
func process_enemy_turn():
	# Пауза перед началом хода врагов
	await get_tree().create_timer(0.5).timeout
	
	# Получаем всех вражеских юнитов
	var enemy_units = get_node("/root/world/Enemys").get_children()
	for enemy in enemy_units:
		if enemy is Unit and is_instance_valid(enemy):
			await enemy.make_turn()
		else:
			pass
	
	# После завершения хода всех врагов сбрасываем флаг `has_moved` у всех юнитов
	var all_units = player_units + get_node("/root/world/Enemys").get_children()
	for unit in all_units:
		if is_instance_valid(unit) and unit is Unit:
			unit.has_moved = false
	
	turn_state = TurnState.PLAYER_TURN


# Проверяет все ли юниты сходили
func all_units_moved():
	for unit in player_units:
		if not unit.has_moved:
			return false
	return true


# Удаляет юнита
func remove_unit(unit: Unit):
	player_units.erase(unit)


# Проверяет есть ли полностью уничтоженная команда
func check_game_over():
	var player_alive = player_units.any(func(unit): return is_instance_valid(unit) and unit.health > 0)
	var enemy_alive = get_node("/root/world/Enemys").get_children().any(func(unit): return unit is Unit and is_instance_valid(unit) and unit.health > 0)
	
	if not player_alive or not enemy_alive:
		show_game_over_message(player_alive)


# Выводит сообщение о конце игры
func show_game_over_message(player_won: bool):
	var layer = get_node("/root/world/layer_end")
	
	var label = layer.get_node("GameOverLabel")
	
	label.text = "Игра окончена"
	label.global_position = tile_map.map_to_local(Vector2i(1, 3))
	label.visible = true
	
	set_process_input(false)
	
	await get_tree().create_timer(2.0).timeout
	
	get_tree().quit()
