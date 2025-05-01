extends Unit

var nearest_unit = null
var min_distance = INF
var movement_points = 2

signal movement_finished

func _physics_process(delta):
	if is_moving:
		process_movement(delta)

func make_turn() -> void:
	if is_moving or has_moved:
		return
	
	var player_units = GameManager.player_units.filter(func(u): return is_instance_valid(u)) 
	if player_units.is_empty():
		has_moved = true
		return

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
		return
	
	var target_player_cell = tile_map.local_to_map(nearest_unit.global_position)
	
	if can_attack(nearest_unit):
		attack(nearest_unit)
		has_moved = true
		return
	
	var path : Array[Vector2i] = []
	
	var occupied_cells = GameManager.get_occupied_cells(self)
	var cells_to_revert = []
	
	for cell in occupied_cells:
		if cell == target_player_cell:
			continue
	
		if astar_grid.is_in_boundsv(cell):
			if not astar_grid.is_point_solid(cell):
				astar_grid.set_point_solid(cell, true)
				cells_to_revert.append(cell)
	
	path = astar_grid.get_id_path(my_cell, target_player_cell)
	
	for cell in cells_to_revert:
		if astar_grid.is_in_boundsv(cell):
			astar_grid.set_point_solid(cell, false)
	
	if not path.is_empty():
		if path[0] == my_cell:
			path.pop_front()

		if not path.is_empty() and path[-1] == target_player_cell:
			path.pop_back()

		if not path.is_empty():
			var move_range = min(path.size(), movement_points)
			current_id_path = path.slice(0, move_range)

			if not current_id_path.is_empty():
				is_moving = true
				await self.movement_finished

				# ➕ Новая проверка после движения
				if is_instance_valid(nearest_unit) and can_attack(nearest_unit):
					attack(nearest_unit)
				
				has_moved = true
				return
	
	
	if not has_moved and is_instance_valid(nearest_unit) and can_attack(nearest_unit):
		attack(nearest_unit)
		has_moved = true


func process_movement(delta: float):
	if current_id_path.is_empty():
		is_moving = false
		return # Путь пуст, нечего делать
	
	var target_pos = tile_map.map_to_local(current_id_path[0])
	# Используем move_toward для простоты и точности
	global_position = global_position.move_toward(target_pos, SPEED * delta)
	
	# Если достигли целевой точки текущего шага
	if global_position.is_equal_approx(target_pos):
		global_position = target_pos # Привязка к точной позиции
		current_id_path.pop_front() # Удаляем пройденную точку из пути
	
		if current_id_path.is_empty():
			is_moving = false
			has_moved = true # <-- ВАЖНО: Отмечаем, что юнит походил ПОСЛЕ завершения движения
			emit_signal("movement_finished") # Сообщаем о завершении
		else:
			pass
