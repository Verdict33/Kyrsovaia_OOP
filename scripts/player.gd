extends Unit

@onready var ray_cast_2d = $RayCast2D  # Луч для обнаружения препятствий

func _physics_process(delta: float) -> void:
	# Если путь пуст — ничего не делаем
	if current_id_path.is_empty():
		return
	
	# Если юнит уже сделал ход — он не двигается
	if has_moved:
		return

	# Получаем следующую целевую клетку
	var next_cell = current_id_path.front()
	var current_cell = tile_map.local_to_map(global_position)
	var direction = next_cell - current_cell

	# Настраиваем луч на направление движения
	ray_cast_2d.target_position = Vector2(direction.x, direction.y) * 16
	ray_cast_2d.force_raycast_update()

	# Если луч сталкивается с чем-то — прерываем движение
	if ray_cast_2d.is_colliding():
		return

	# Если юнит еще не начал движение — устанавливаем целевую позицию
	if not is_moving:
		target_position = tile_map.map_to_local(current_id_path.front())
		is_moving = true

	# Плавное движение к цели
	global_position = global_position.move_toward(target_position, SPEED * delta)

	# Когда достигнута целевая позиция:
	if global_position == target_position:
		current_id_path.pop_front()  # Убираем достигнутую клетку

		if current_id_path.is_empty():
			# Движение завершено
			is_moving = false
			has_moved = true  # Отметить, что юнит потратил ход

			GameManager.clear_highlight()  # Убираем подсветку

			# Если все юниты сходили — завершаем ход игрока
			if GameManager.all_units_moved():
				GameManager.end_player_turn()
		else:
			# Переход к следующей клетке
			target_position = tile_map.map_to_local(current_id_path.front())
