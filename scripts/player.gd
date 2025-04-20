extends Unit

@onready var ray_cast_2d = $RayCast2D

func _physics_process(delta: float) -> void:
	if current_id_path.is_empty():
		return
	
	# Юнит уже сходил — не двигается
	if has_moved:
		return

	var next_cell = current_id_path.front()
	var current_cell = tile_map.local_to_map(global_position)
	var direction = next_cell - current_cell
	ray_cast_2d.target_position = Vector2(direction.x, direction.y) * 16
	ray_cast_2d.force_raycast_update()

	if ray_cast_2d.is_colliding():
		return

	if not is_moving:
		target_position = tile_map.map_to_local(current_id_path.front())
		is_moving = true

	global_position = global_position.move_toward(target_position, SPEED * delta)

	if global_position == target_position:
		current_id_path.pop_front()
		
		if current_id_path.is_empty():
			is_moving = false
			has_moved = true  # Отметить, что юнит сходил
			# Проверка на завершение хода игрока
			if GameManager.all_units_moved():
				GameManager.end_player_turn()
		else:
			target_position = tile_map.map_to_local(current_id_path.front())
