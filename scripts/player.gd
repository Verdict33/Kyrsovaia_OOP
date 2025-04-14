extends Unit

func _input(event) -> void:
	if event.is_action_pressed("move") == false:
		return
	var id_path
	
	if is_moving:
		id_path = astar_grid.get_id_path(
			tile_map.local_to_map(target_position),
			tile_map.local_to_map(get_global_mouse_position())
		)
	else :
		id_path = astar_grid.get_id_path(
			tile_map.local_to_map(global_position),
			tile_map.local_to_map(get_global_mouse_position())
		)
		
	if id_path.is_empty() == false:
		current_id_path = id_path


func _physics_process(delta: float) -> void:
	if current_id_path.is_empty():
		return
	
	if is_moving == false:
		target_position = tile_map.map_to_local(current_id_path.front())
		is_moving = true
		
	
	global_position = global_position.move_toward(target_position, 1)
	
	if global_position == target_position:
		current_id_path.pop_front()
		
		if current_id_path.is_empty() == false:
			target_position = tile_map.map_to_local(current_id_path.front())
		else:
			is_moving = false 
