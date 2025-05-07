extends Unit

var nearest_unit = null # Ближайший юнита игрока

var min_distance = INF # Дистанция до ближайшего юнита игрока

var movement_points = 2 # Дальность хода врага

signal movement_finished # Сигнал для завершения хода вражеского юнита

# Функцция годота для начала работы и вызова передвижения
func _physics_process(delta):
	if is_moving:
		process_movement(delta)
		check_for_traps()
		if not is_instance_valid(self):
			return

# Поиск момента и корректного применения передвижения для GameManager
func make_turn() -> void:
	# Если юнит уже двигается или уже походил, то завершаем работу
	if is_moving or has_moved:
		return
	
	# Получаем список живых юнитов игрока
	var player_units = GameManager.player_units.filter(func(unit): return is_instance_valid(unit)) 
	if player_units.is_empty():
		has_moved = true
		return  # Если юнитов игрока нет, то отмечаем, что враг походил, завершаем функию
	
	# Ищет ближайшего живого юнита игрока
	var my_cell = tile_map.local_to_map(global_position)
	nearest_unit = null
	min_distance = INF
	
	for unit in player_units:
		if not is_instance_valid(unit): 
			continue
	
		var unit_cell = tile_map.local_to_map(unit.global_position)
		var dist = my_cell.distance_to(unit_cell)
		if dist < min_distance:
			min_distance = dist
			nearest_unit = unit
	
	if not nearest_unit:
		has_moved = true
		return # Если никого не нашел, пропускает ход
	
	var target_player_cell = tile_map.local_to_map(nearest_unit.global_position)
	
	# Если можно атаковать сразу, то атакуем
	if can_attack(nearest_unit):
		attack(nearest_unit)
		has_moved = true
		return
	
	# Подготовка к передвижению до ближайшему юнита игрока
	var path : Array[Vector2i] = []
	var occupied_cells = GameManager.get_occupied_cells(self)
	var cells_to_revert = []
	
	# Временно помечает занятые клетки как непроходимые для AStar
	for cell in occupied_cells:
		if cell == target_player_cell:
			continue  # Игнорирует клетку цели
		if astar_grid.is_in_boundsv(cell):
			if not astar_grid.is_point_solid(cell):
				astar_grid.set_point_solid(cell, true)
				cells_to_revert.append(cell)
	
	# Путь до цели
	path = astar_grid.get_id_path(my_cell, target_player_cell)
	
	# Удаляет временные блокировки
	for cell in cells_to_revert:
		if astar_grid.is_in_boundsv(cell):
			astar_grid.set_point_solid(cell, false)
	
	# Если путь найден:
	if not path.is_empty():
		if path[0] == my_cell:
			path.pop_front()  # Удаляет текущую позицию из пути
	
		# Не заходит на клетку с врагом
		if not path.is_empty() and path[-1] == target_player_cell:
			path.pop_back()
	
		# Ограничивает путь числом шагов юнита
		if not path.is_empty():
			var move_range = min(path.size(), movement_points)
			current_id_path = path.slice(0, move_range)
	
			if not current_id_path.is_empty():
				is_moving = true
	
				await self.movement_finished  # Ждёт завершения движения
	
				# Если можно атаковать, то атакует
				if is_instance_valid(nearest_unit) and can_attack(nearest_unit):
					attack(nearest_unit)
	
				has_moved = true
				return
	
	# Дополнительная проверка, если путь не найден, но юнит уже рядом (на случай ошибки)
	if not has_moved and is_instance_valid(nearest_unit) and can_attack(nearest_unit):
		attack(nearest_unit)
		has_moved = true


# Реализация пошагового передвижения
func process_movement(delta: float):
	if current_id_path.is_empty():
		is_moving = false
		return # Путь пуст, завершение хода
	
	var target_pos = tile_map.map_to_local(current_id_path[0])

	global_position = global_position.move_toward(target_pos, SPEED * delta)
	
	# Если достигнута целевая точка текущего шага
	if global_position.is_equal_approx(target_pos):
		global_position = target_pos # Привязка к точной позиции
		current_id_path.pop_front() # Удаляет пройденную точку из пути
	
		if current_id_path.is_empty():
			is_moving = false
			has_moved = true
			emit_signal("movement_finished") # сигнал о завершении
