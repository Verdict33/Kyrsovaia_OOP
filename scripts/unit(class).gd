class_name Unit
extends Node2D

@onready var tile_map = get_node("/root/world/TileMap")

var astar_grid: AStarGrid2D
var current_id_path: Array[Vector2i]
var target_position: Vector2
var has_moved: bool = false
var SPEED = 100
var is_moving: bool
var max_move_cells: int = 5

func _ready() -> void:
	astar_grid = AStarGrid2D.new()
	astar_grid.region = tile_map.get_used_rect()
	astar_grid.cell_size = Vector2(16, 16)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	
	for x in tile_map.get_used_rect().size.x:
		for y in tile_map.get_used_rect().size.y:
			var tile_position = Vector2i(
				x + tile_map.get_used_rect().position.x,
				y + tile_map.get_used_rect().position.y
			)
			
			var tile_data = tile_map.get_cell_tile_data(0, tile_position)
			
			if tile_data == null or tile_data.get_custom_data("walking") == false:
				astar_grid.set_point_solid(tile_position)


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
	
	check_for_traps()
	if not is_instance_valid(self):
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
			
			GameManager.clear_highlight()
			
			# Проверка на завершение хода игрока
			if GameManager.all_units_moved():
				GameManager.end_player_turn()
		else:
			target_position = tile_map.map_to_local(current_id_path.front())

func _on_area_2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		GameManager.select_unit(self)

func try_move_to(target_cell: Vector2i) -> void:
	if has_moved:
		return

	var start_cell = tile_map.local_to_map(global_position)
	var occupied = GameManager.get_occupied_cells(self)

	# Отмечаем занятые клетки как непроходимые
	for cell in occupied:
		if astar_grid.is_in_boundsv(cell):
			astar_grid.set_point_solid(cell, true)

	var id_path = astar_grid.get_id_path(start_cell, target_cell)

	# Снимаем отметки
	for cell in occupied:
		if astar_grid.is_in_boundsv(cell):
			astar_grid.set_point_solid(cell, false)

	# Проверка доступности пути
	if id_path.is_empty():
		return

	# Ограничение по длине хода (не учитываем начальную точку)
	var move_length = id_path.size() - 1
	if move_length > max_move_cells:
		return

	# Допустимый путь — начинаем движение
	current_id_path = id_path
	is_moving = false

func get_reachable_cells() -> Array[Vector2i]:
	var start_cell = tile_map.local_to_map(global_position)
	var reachable: Array[Vector2i] = []
	
	var occupied = GameManager.get_occupied_cells(self)
	for cell in occupied:
		if astar_grid.is_in_boundsv(cell):
			astar_grid.set_point_solid(cell, true)
	
	var region = astar_grid.region
	for x in range(region.position.x, region.position.x + region.size.x):
		for y in range(region.position.y, region.position.y + region.size.y):
			var target_cell = Vector2i(x, y)
			if not astar_grid.is_point_solid(target_cell):
				var path = astar_grid.get_id_path(start_cell, target_cell)
				if not path.is_empty() and path.size() - 1 <= max_move_cells:
					reachable.append(target_cell)
	
	# Убрать временную блокировку
	for cell in occupied:
		if astar_grid.is_in_boundsv(cell):
			astar_grid.set_point_solid(cell, false)
	
	return reachable

var health = 10
var attack_power = 3
var attack_dist = 1

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		die()
		GameManager.check_game_over()

func die():
	if is_inside_tree():
		get_node("/root/world/GameManager").remove_unit(self)
	queue_free()

	
func attack(target: Unit) -> void:
	if target:
		target.take_damage(attack_power)

func can_attack(target: Unit) -> bool:
	var self_cell = tile_map.local_to_map(global_position)
	var target_cell = tile_map.local_to_map(target.global_position)
	return self_cell.distance_to(target_cell) <= attack_dist 

func check_for_traps():
	var traps = get_node("/root/world/Traps").get_children()
	for trap in traps:
		if trap is Trap:
			trap.check_trigger(self)
