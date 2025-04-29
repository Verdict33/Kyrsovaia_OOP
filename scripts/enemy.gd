extends Unit

var nearest_unit = null
var min_distance = INF
var movement_points = 2

func _physics_process(delta):
	if is_moving:
		process_movement(delta)

func make_turn():
	if is_moving or has_moved:
		return
	
	var player_units = GameManager.player_units
	if player_units.is_empty():
		return
	
	var my_cell = tile_map.local_to_map(global_position)
	nearest_unit = null
	min_distance = INF
	
	for unit in player_units:
		var unit_cell = tile_map.local_to_map(unit.global_position)
		var path = astar_grid.get_id_path(my_cell, unit_cell)
		if path.size() < min_distance:
			min_distance = path.size()
			nearest_unit = unit
	
	if nearest_unit:
		var target_cell = tile_map.local_to_map(nearest_unit.global_position)
		var path = astar_grid.get_id_path(my_cell, target_cell)
	
		if not path.is_empty() and path[-1] == target_cell:
			path.remove_at(path.size() - 1)
	
		if not path.is_empty() and path[0] == my_cell:
			path.remove_at(0)
	
		var move_range = min(path.size(), movement_points)
		current_id_path = path.slice(0, move_range)
	
		if not current_id_path.is_empty():
			target_position = tile_map.map_to_local(current_id_path[0])
			is_moving = true
			
	if nearest_unit and can_attack(nearest_unit):
		attack(nearest_unit)
		has_moved = true
		return


func process_movement(delta):
	if current_id_path.is_empty():
		is_moving = false
		return

	var target_pos = tile_map.map_to_local(current_id_path[0])
	var direction = (target_pos - global_position).normalized()
	var distance = SPEED * delta

	if global_position.distance_to(target_pos) <= distance:
		global_position = target_pos
		current_id_path.remove_at(0)
	else:
		global_position += direction * distance
